package api

import (
	"net/http"
	"time"

	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/gin-gonic/gin"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
)

func (s *Server) downloadFBArchive(c *gin.Context) {
	var params struct {
		Headers   map[string]string `json:"headers"`
		FileURL   string            `json:"file_url"`
		RawCookie string            `json:"raw_cookie"`
		StartedAt int64             `json:"started_at"`
		EndedAt   int64             `json:"ended_at"`
	}

	if err := c.BindJSON(&params); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	account := c.MustGet("account").(*store.Account)
	archiveRecord, err := s.store.AddFBArchive(c, account.AccountNumber, time.Unix(params.StartedAt, 0), time.Unix(params.EndedAt, 0))
	shouldInterupt(err, c)

	args := work.Q{
		"file_url":       params.FileURL,
		"raw_cookie":     params.RawCookie,
		"account_number": account.AccountNumber,
		"archive_id":     archiveRecord.ID,
	}

	for k, v := range params.Headers {
		args["header_"+k] = v
	}

	job, err := s.backgroundEnqueuer.EnqueueUnique("download_archive", args)
	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}
	log.Info("Enqueued job with id:", job.ID)

	c.JSON(http.StatusAccepted, gin.H{"result": "ok"})
}

func (s *Server) getAllArchives(c *gin.Context) {
	account := c.MustGet("account").(*store.Account)

	archives, err := s.store.GetFBArchives(c, &store.FBArchiveQueryParam{
		AccountNumber: &account.AccountNumber,
	})
	shouldInterupt(err, c)

	c.JSON(http.StatusOK, gin.H{
		"result": archives,
	})
}

func (s *Server) parseArchive(c *gin.Context) {
	job, err := s.backgroundEnqueuer.EnqueueUnique("analyze_posts", work.Q{
		"url":            "https://bitmark.numbersprotocol.io/version-test/api/1.1/obj/fb_post",
		"account_number": "test",
	})
	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}
	log.Info("Enqueued job with id:", job.ID)
	c.JSON(http.StatusAccepted, gin.H{"result": "ok"})
}
