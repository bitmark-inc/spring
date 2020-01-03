package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type statisticCategory struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type statisticGroup struct {
	Categories []struct {
		Category statisticCategory `json:"category"`
		Quantity int               `json:"quantity"`
	} `json:"categories"`
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type statisticResult struct {
	DiffFromPrevious int              `json:"diff_from_previous"`
	DurationAmount   int              `json:"duration_amount"`
	DurationType     string           `json:"duration_type"`
	Groups           []statisticGroup `json:"groups"`
	SectionID        int              `json:"section_id"`
}

func (s *Server) getStatistic(c *gin.Context) {
	var query struct {
		SectionID       string `form:"section_id" binding:"required"`
		DurationType    string `form:"duration_type" binding:"optional"`
		DurationAmount  int64  `form:"duration_amount" binding:"optional"`
		DurationStartAt int64  `form:"duration_start_at" binding:"optional"`
	}

	if err := c.ShouldBindQuery(&query); err != nil {
		log.Debug(err)
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

}
