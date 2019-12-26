package api

import (
	"fmt"
	"net/http"
	"net/url"
	"strconv"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func (s *Server) getAllPosts(c *gin.Context) {
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

	posts, err := s.fbDataStore.GetFBStat(c, accountNumber+"/post", params.StartedAt, params.EndedAt)
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

func (s *Server) getPostStats(c *gin.Context) {
	accountNumber := c.GetString("requester")
	period := c.Param("period")
	startedAt, err := strconv.ParseInt(c.Query("started_at"), 10, 64)

	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	results := make([]interface{}, 0)

	postStat, err := s.fbDataStore.GetExactFBStat(c, fmt.Sprintf("%s/post-%s-stat", accountNumber, period), startedAt)
	if shouldInterupt(err, c) {
		return
	}

	if postStat != nil {
		results = append(results, postStat)
	}

	reactionStat, err := s.fbDataStore.GetExactFBStat(c, fmt.Sprintf("%s/reaction-%s-stat", accountNumber, period), startedAt)
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

func (s *Server) getPostMediaURI(c *gin.Context) {
	key := c.Query("key")
	keyDecoded, err := url.QueryUnescape(key)
	if key == "" {
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	uri, err := s.bitSocialClient.GetMediaPresignedURI(c, keyDecoded)
	if shouldInterupt(err, c) {
		return
	}

	log.Debug(uri)

	c.Redirect(http.StatusSeeOther, uri)
}
