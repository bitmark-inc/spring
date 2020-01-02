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

	if shouldInterupt(err, c) {
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"result": archives,
	})
}

func (s *Server) parseArchive(c *gin.Context) {
	accountNumber := c.GetString("requester")

	// For post
	job, err := s.backgroundEnqueuer.EnqueueUnique("analyze_posts", work.Q{
		"account_number": accountNumber,
	})
	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}
	log.Info("Enqueued job with id:", job.ID)

	// For reaction
	reactionJob, err := s.backgroundEnqueuer.EnqueueUnique("analyze_reactions", work.Q{
		"account_number": accountNumber,
	})
	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}
	log.Info("Enqueued job with id:", reactionJob.ID)

	// For sentiment
	sentimentJob, err := s.backgroundEnqueuer.EnqueueUnique("analyze_sentiments", work.Q{
		"account_number": accountNumber,
	})
	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}
	log.Info("Enqueued job with id:", sentimentJob.ID)

	c.JSON(http.StatusAccepted, gin.H{"result": "ok"})
}

func (s *Server) adminSubmitArchives(c *gin.Context) {
	var params struct {
		Ids []int64 `json:"ids"`
	}

	if err := c.BindJSON(&params); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	result := make(map[string]store.FBArchive)
	for _, id := range params.Ids {
		archives, err := s.store.GetFBArchives(c, &store.FBArchiveQueryParam{
			ID: &id,
		})
		if len(archives) != 1 {
			continue
		}

		archive := archives[0]

		job, err := s.backgroundEnqueuer.EnqueueUnique("upload_archive", work.Q{
			"s3_key":         archive.S3Key,
			"account_number": archive.AccountNumber,
			"archive_id":     archive.ID,
		})
		if err != nil {
			log.Debug(err)
			c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
			return
		}
		log.Info("Enqueued job with id:", job.ID)
		result[job.ID] = archive
	}

	c.JSON(http.StatusAccepted, result)
}

func (s *Server) adminForceParseArchive(c *gin.Context) {
	var params struct {
		AccountNumbers []string `json:"account_numbers"`
	}

	if err := c.BindJSON(&params); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	result := make(map[string]string)
	for _, accountNumber := range params.AccountNumbers {
		job, err := s.backgroundEnqueuer.EnqueueUnique("analyze_posts", work.Q{
			"account_number": accountNumber,
		})
		if err != nil {
			log.Debug(err)
			c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
			return
		}
		log.Info("Enqueued job with id:", job.ID)
		result[job.ID] = accountNumber
	}

	c.JSON(http.StatusAccepted, result)
}
