package api

import (
	"fmt"
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

	posts, err := s.fbDataStore.GetFBStat(c, "michael"+"/post", params.StartedAt, params.EndedAt)
	if shouldInterupt(err, c) {
		return
	}

	if posts == nil {
		posts = []interface{}{}
	}

	c.JSON(http.StatusOK, gin.H{
		"result": posts,
	})
}

func (s *Server) getAllReactions(c *gin.Context) {
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

	posts, err := s.fbDataStore.GetFBStat(c, "test"+"/reaction", params.StartedAt, params.EndedAt)
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

	results := make([]interface{}, 0)

	postStat, err := s.fbDataStore.GetExactFBStat(c, fmt.Sprintf("%s/post-%s-stat", "test", period), startedAt)
	if shouldInterupt(err, c) {
		return
	}

	if postStat != nil {
		results = append(results, postStat)
	}

	reactionStat, err := s.fbDataStore.GetExactFBStat(c, fmt.Sprintf("%s/reaction-%s-stat", "test", period), startedAt)
	if shouldInterupt(err, c) {
		return
	}

	if reactionStat != nil {
		results = append(results, reactionStat)
	}

	c.JSON(http.StatusOK, gin.H{
		"result": results,
	})
}
