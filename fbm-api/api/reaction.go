package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func (s *Server) getAllReactions(c *gin.Context) {
	accountNumber := c.GetString("requester")
	var params struct {
		StartedAt int64 `form:"started_at"`
		EndedAt   int64 `form:"ended_at"`
	}

	if err := c.BindQuery(&params); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	if params.StartedAt >= params.EndedAt {
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	reactions, err := s.fbDataStore.GetFBStat(c, accountNumber+"/reaction", params.StartedAt, params.EndedAt)
	if shouldInterupt(err, c) {
		return
	}

	if reactions == nil {
		reactions = []interface{}{}
	}

	c.JSON(http.StatusOK, gin.H{
		"result": reactions,
	})
}
