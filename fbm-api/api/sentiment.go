package api

import (
	"math/rand"
	"net/http"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func (s *Server) getSentiment(c *gin.Context) {
	// account := c.MustGet("account").(*store.Account)
	// period := c.Param("period")
	// log.Info("period ", period)
	// if period != "week" && period != "year" && period != "decade" {
	// 	c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
	// 	return
	// }

	var query struct {
		Timestamp int64 `form:"timestamp" binding:"required"`
	}
	if err := c.ShouldBindQuery(&query); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"result": rand.Intn(9) + 1,
	})
}
