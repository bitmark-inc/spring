package api

import (
	"context"
	"mime"
	"net/http"
	"net/http/httputil"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"

	"github.com/gin-gonic/gin"
)

func (s *Server) accountRegister(c *gin.Context) {
	accountNumber := c.GetString("requester")

	account, err := s.store.QueryAccount(c, &store.AccountQueryParam{
		AccountNumber: &accountNumber,
	})
	if shouldInterupt(err, c) {
		return
	}

	if account != nil {
		c.AbortWithStatusJSON(http.StatusForbidden, errorAccountTaken)
		return
	}

	account, err = s.store.InsertAccount(c, accountNumber, nil)
	if shouldInterupt(err, c) {
		return
	}

	c.JSON(http.StatusCreated, gin.H{"result": account})
}

func (s *Server) accountDetail(c *gin.Context) {
	accountNumber := c.GetString("account_number")
	account, err := s.store.QueryAccount(c, &store.AccountQueryParam{
		AccountNumber: &accountNumber,
	})
	if shouldInterupt(err, c) {
		return
	}

	if account == nil {
		c.AbortWithStatusJSON(http.StatusUnauthorized, errorAccountNotFound)
		return
	}

	c.JSON(http.StatusOK, gin.H{"result": account})
}

func (s *Server) meRoute(meAlias string) gin.HandlerFunc {
	return func(c *gin.Context) {
		accountNumber := c.Param("account_number")
		if accountNumber == meAlias {
			accountNumber = c.GetString("requester")
			c.Set("me", true)
		}
		c.Set("account_number", accountNumber)
	}
}

func (s *Server) downloadFBArchive(c *gin.Context) {
	var params struct {
		Headers map[string]string `json:"headers"`
		FileURL string            `json:"file_url"`
		Cookies []struct {
			Name     string `json:"name"`
			Value    string `json:"value"`
			Path     string `json:"path"`
			Domain   string `json:"domain"`
			Expires  int64  `json:"expire"`
			Secure   bool   `json:"secure"`
			HTTPOnly bool   `json:"httponly"`
		} `json:"cookies"`
		RawCookie string `json:"raw_cookie"`
	}

	if err := c.BindJSON(&params); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	req, err := http.NewRequestWithContext(c, "GET", params.FileURL, nil)
	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	for k, v := range params.Headers {
		req.Header.Set(k, v)
	}

	for _, cookie := range params.Cookies {
		c := &http.Cookie{
			Name:     cookie.Name,
			Value:    cookie.Value,
			Path:     cookie.Path,
			Domain:   cookie.Domain,
			Secure:   cookie.Secure,
			HttpOnly: cookie.HTTPOnly,
			SameSite: http.SameSiteNoneMode,
		}

		if cookie.Expires > 0 {
			t := time.Unix(cookie.Expires, 0)
			log.Debug(t)
			c.Expires = t
		}
		req.AddCookie(c)
	}

	if len(params.RawCookie) > 0 {
		req.Header.Set("Cookie", params.RawCookie)
	}

	go func(req *http.Request) {
		reqDump, err := httputil.DumpRequest(req, true)
		if err != nil {
			log.Debug(err)
		}
		log.WithField("dump", string(reqDump)).Info("Request dump")
	}(req)

	account := c.MustGet("account").(*store.Account)

	c.JSON(http.StatusAccepted, gin.H{"result": "ok"})

	go func(req *http.Request, account *store.Account) {
		resp, err := s.httpClient.Do(req)
		if err != nil {
			log.Debug(err)
			return
		}

		if resp.StatusCode > 300 {
			// Print out the response in console log
			dumpBytes, err := httputil.DumpResponse(resp, true)
			if err != nil {
				log.Error(err)
			}
			dump := string(dumpBytes)
			log.WithField("prefix", "fbarchives").Info("response: ", dump)

			return
		}

		sess := session.New(s.awsConf)
		svc := s3manager.NewUploader(sess)

		_, p, err := mime.ParseMediaType(resp.Header.Get("Content-Disposition"))
		if err != nil {
			log.Error(err)
			return
		}
		filename := p["filename"]

		defer resp.Body.Close()

		_, err = svc.Upload(&s3manager.UploadInput{
			Bucket: aws.String(viper.GetString("aws.s3.archive_bucket")),
			Key:    aws.String("archives/" + account.AccountNumber + "/" + filename),
			Body:   resp.Body,
			Metadata: map[string]*string{
				"url": aws.String(params.FileURL),
			},
		})

		if err != nil {
			log.Error(err)
			return
		}

		if err := s.oneSignalClient.NotifyFBArchiveAvailable(context.Background(), account.AccountNumber); err != nil {
			log.Error(err)
		}
	}(req, account)
}
