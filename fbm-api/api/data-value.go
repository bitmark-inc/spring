package api

import (
	"net/http"

	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func getTotalValueForDataPeriod(period string, from int64, lookupRange []fbIncomePeriod) float64 {
	totalQuarter := 1
	switch period {
	case "week":
		totalQuarter = 1
	case "year":
		totalQuarter = 4
	case "decade":
		totalQuarter = 40
	}

	amount := 0.0
	quarterCounter := 0

	for _, v := range lookupRange {
		if period == "week" && from >= v.StartedAt {
			amount = v.QuarterAmount / 13
			quarterCounter++
		} else if period == "year" && from <= v.StartedAt {
			amount += v.QuarterAmount
			quarterCounter++
		} else if period == "decade" && from <= v.StartedAt {
			amount += v.QuarterAmount
			quarterCounter++
		}

		if quarterCounter >= totalQuarter {
			break
		}
	}

	return amount
}

func (s *Server) getDataValue(c *gin.Context) {
	account := c.MustGet("account").(*store.Account)
	period := c.Param("period")
	log.Info("period ", period)
	if period != "week" && period != "year" && period != "decade" {
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	var query struct {
		Timestamp int64 `form:"timestamp" binding:"required"`
	}
	if err := c.ShouldBindQuery(&query); err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	countryCode := ""
	if c, ok := account.Metadata["original_country"].(string); ok {
		countryCode = c
	}

	var lookupRange []fbIncomePeriod
	// Logic: if there is no country code, it's world-wide area
	// if it's us/canada, then area is us-canada
	// if it's europe or asia, then area is either
	// fallback to rest if can not look it up

	if countryCode == "" {
		lookupRange = s.areaFBIncomeMap.WorldWide
	} else if countryCode == "us" || countryCode == "ca" {
		lookupRange = s.areaFBIncomeMap.USCanada
	} else {
		if continent, ok := s.countryContinentMap[countryCode]; ok {
			if continent == "Europe" {
				lookupRange = s.areaFBIncomeMap.Europe
			} else if continent == "Asia" {
				lookupRange = s.areaFBIncomeMap.AsiaPacific
			} else {
				lookupRange = s.areaFBIncomeMap.Rest
			}
		} else {
			lookupRange = s.areaFBIncomeMap.Rest
		}
	}

	amount := getTotalValueForDataPeriod(period, query.Timestamp, lookupRange)

	c.JSON(http.StatusOK, gin.H{
		"result": amount,
	})
}
