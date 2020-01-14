package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func (s *Server) metricAccountCreation(c *gin.Context) {
	var params struct {
		From int64 `form:"from"`
		To   int64 `form:"to"`
	}

	if err := c.BindQuery(&params); err != nil {
		log.Debug(err)
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	if params.From > 0 && params.To > 0 && params.From >= params.To {
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	count, err := s.store.CountAccountCreation(c, time.Unix(params.From, 0), time.Unix(params.To, 0))
	if shouldInterupt(err, c) {
		return
	}

	c.JSON(http.StatusOK, gin.H{"result": gin.H{"total": count}})
}
