package api

import (
	"fmt"
	"net/http"
	"net/url"
	"strconv"

	"github.com/bitmark-inc/fbm-apps/fbm-api/protomodel"
	"github.com/gin-gonic/gin"
	"github.com/golang/protobuf/proto"
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
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	data, err := s.fbDataStore.GetFBStat(c, accountNumber+"/post", params.StartedAt, params.EndedAt)
	if shouldInterupt(err, c) {
		return
	}

	posts := make([]*protomodel.Post, 0)
	for _, d := range data {
		var post protomodel.Post
		err := proto.Unmarshal(d, &post)
		if shouldInterupt(err, c) {
			return
		}

		posts = append(posts, &post)
	}

	responseWithEncoding(c, http.StatusOK, &protomodel.PostsResponse{
		Result: posts,
	})
}

func (s *Server) getPostStats(c *gin.Context) {
	accountNumber := c.GetString("requester")
	period := c.Param("period")
	startedAt, err := strconv.ParseInt(c.Query("started_at"), 10, 64)

	if err != nil {
		log.Debug(err)
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	results := make([]*protomodel.Usage, 0)

	postStatData, err := s.fbDataStore.GetExactFBStat(c, fmt.Sprintf("%s/post-%s-stat", accountNumber, period), startedAt)
	if shouldInterupt(err, c) {
		return
	}

	if postStatData != nil {
		var postStat protomodel.Usage
		err := proto.Unmarshal(postStatData, &postStat)
		if shouldInterupt(err, c) {
			return
		}
		results = append(results, &postStat)
	}

	reactionStatData, err := s.fbDataStore.GetExactFBStat(c, fmt.Sprintf("%s/reaction-%s-stat", accountNumber, period), startedAt)
	if shouldInterupt(err, c) {
		return
	}

	if reactionStatData != nil {
		var reactionStat protomodel.Usage
		err := proto.Unmarshal(reactionStatData, &reactionStat)
		if shouldInterupt(err, c) {
			return
		}
		results = append(results, &reactionStat)
	}

	responseWithEncoding(c, http.StatusOK, &protomodel.UsageResponse{
		Result: results,
	})
}

func (s *Server) getPostMediaURI(c *gin.Context) {
	key := c.Query("key")
	keyDecoded, err := url.QueryUnescape(key)
	if key == "" {
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	uri, err := s.bitSocialClient.GetMediaPresignedURI(c, keyDecoded)
	if shouldInterupt(err, c) {
		return
	}

	log.Debug(uri)

	c.Redirect(http.StatusSeeOther, uri)
}
