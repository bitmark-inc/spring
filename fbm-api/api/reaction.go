package api

import (
	"net/http"

	"github.com/bitmark-inc/fbm-apps/fbm-api/protomodel"
	"github.com/gin-gonic/gin"
	"github.com/golang/protobuf/proto"
	log "github.com/sirupsen/logrus"
)

func (s *Server) getAllReactions(c *gin.Context) {
	accountNumber := c.GetString("requester")
	var params struct {
		StartedAt int64 `form:"started_at"`
		EndedAt   int64 `form:"ended_at"`
		Limit     int64 `form:"limit"`
	}

	if err := c.BindQuery(&params); err != nil {
		log.Debug(err)
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	if params.StartedAt >= params.EndedAt {
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	if params.Limit > 1000 {
		params.Limit = 1000
	}

	if params.Limit < 1 {
		params.Limit = 100
	}

	data, err := s.fbDataStore.GetFBStat(c, accountNumber+"/reaction", params.StartedAt, params.EndedAt, params.Limit)
	if shouldInterupt(err, c) {
		return
	}

	reactions := make([]*protomodel.Reaction, 0)
	for _, d := range data {
		var reaction protomodel.Reaction
		err := proto.Unmarshal(d, &reaction)
		if shouldInterupt(err, c) {
			return
		}

		reactions = append(reactions, &reaction)
	}

	responseWithEncoding(c, http.StatusOK, &protomodel.ReactionsResponse{
		Result: reactions,
	})
}
