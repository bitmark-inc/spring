package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type trendResult struct {
	DiffFromPrevious int    `json:"diff_from_previous"`
	ID               int    `json:"id"`
	Quantity         int    `json:"quantity"`
	Section          string `json:"section"`
}

func (s *Server) getTrends(c *gin.Context) {
	var query struct {
		Type            string `form:"type" binding:"required"`
		DurationType    string `form:"duration_type" binding:"optional"`
		DurationAmount  int64  `form:"duration_amount" binding:"optional"`
		DurationStartAt int64  `form:"duration_start_at" binding:"optional"`
	}

	if err := c.ShouldBindQuery(&query); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"result": []trendResult{
			trendResult{
				ID:               1,
				Section:          "post",
				Quantity:         24,
				DiffFromPrevious: 5,
			},
			trendResult{
				ID:               2,
				Section:          "comment",
				Quantity:         20,
				DiffFromPrevious: 3,
			},
			trendResult{
				ID:               3,
				Section:          "friend",
				Quantity:         4,
				DiffFromPrevious: 8,
			},
			trendResult{
				ID:               4,
				Section:          "reaction",
				Quantity:         100,
				DiffFromPrevious: -18,
			},
		},
	})
}
