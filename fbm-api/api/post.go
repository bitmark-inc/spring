package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func (s *Server) getAllPosts(c *gin.Context) {
	// account := c.MustGet("account").(*store.Account)
	var params struct {
		StartedAt int64 `form:"started_at"`
		EndedAt   int64 `form:"ended_at"`
	}

	if err := c.BindQuery(&params); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	posts, err := s.fbDataStore.GetFBStat(c, "test"+"/post", params.StartedAt, params.EndedAt)
	shouldInterupt(err, c)

	c.JSON(http.StatusOK, gin.H{
		"result": posts,
	})
}
