package api

import (
	"net/http"
	"strconv"

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
	if shouldInterupt(err, c) {
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"result": posts,
	})
}

func (s *Server) getPostStats(c *gin.Context) {
	period := c.Param("period")
	startedAt, err := strconv.ParseInt(c.Query("started_at"), 10, 64)

	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	stat, err := s.fbDataStore.GetExactFBStat(c, "test"+"/"+period+"-stat", startedAt)
	if shouldInterupt(err, c) {
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"result": stat,
	})
}
