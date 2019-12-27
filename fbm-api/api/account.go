package api

import (
	"encoding/hex"
	"net/http"

	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	log "github.com/sirupsen/logrus"

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

	var params struct {
		EncPubKey string `json:"enc_pub_key"`
	}

	if err := c.BindJSON(&params); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	// Register data owner
	if err := s.bitSocialClient.NewDataOwner(c, accountNumber); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadGateway, errorInternalServer)
		return
	}

	// Save to db
	encPubKey, err := hex.DecodeString(params.EncPubKey)
	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	account, err = s.store.InsertAccount(c, accountNumber, encPubKey)
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
