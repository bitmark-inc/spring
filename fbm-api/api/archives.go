package api

import (
	"net/http"

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
	}

	if err := c.BindJSON(&params); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	account := c.MustGet("account").(*store.Account)

	args := work.Q{
		"file_url":       params.FileURL,
		"raw_cookie":     params.RawCookie,
		"account_number": account.AccountNumber,
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
