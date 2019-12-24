package api

import (
	"math/rand"
	"net/http"
	"strconv"

	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func (s *Server) getSentiment(accountNumber, period string, timestamp int64) int {
	return rand.Intn(9) + 1
}

func getPreviousPeriodStartingPoint(period string, currentTimestamp int64) int64 {
	switch period {
	case "week":
		return currentTimestamp - 7*24*60*60
	case "year":
		return currentTimestamp - 365*24*60*60
	case "decade":
		return currentTimestamp - 10*365*24*60*60
	}
	return 0
}

func getTotalFBIncomeForDataPeriod(period string, from int64, lookupRange []fbIncomePeriod) float64 {
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

func (s *Server) getFBIncomeFromData(account *store.Account, period string, timestamp int64) float64 {
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

	return getTotalFBIncomeForDataPeriod(period, timestamp, lookupRange)
}

// InsightSection represent one section of the insight data
type InsightSection struct {
	DiffFromPrevious float64 `json:"diff_from_previous"`
	Period           string  `json:"period"`
	PeriodStartedAt  int64   `json:"period_started_at"`
	Quantity         int64   `json:"quantity"`
	Value            float64 `json:"value"`
	SectionName      string  `json:"section_name"`
}

func (s *Server) getInsight(c *gin.Context) {
	account := c.MustGet("account").(*store.Account)

	period := c.Param("period")
	if period != "week" && period != "year" && period != "decade" {
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	startedAt, err := strconv.ParseInt(c.Query("started_at"), 10, 64)
	if err != nil {
		log.Debug(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidParameters)
		return
	}

	results := make([]InsightSection, 0)

	// fb income for data
	currentPeriodFBIncome := s.getFBIncomeFromData(account, period, startedAt)
	previousPeriodFBIncome := s.getFBIncomeFromData(account, period, getPreviousPeriodStartingPoint(period, startedAt))
	var diff float64

	if previousPeriodFBIncome == 0 {
		diff = 1
	} else {
		diff = (currentPeriodFBIncome - previousPeriodFBIncome) / previousPeriodFBIncome
	}

	results = append(results, InsightSection{
		SectionName:      "fb-income",
		Value:            currentPeriodFBIncome,
		PeriodStartedAt:  startedAt,
		Period:           period,
		DiffFromPrevious: diff,
	})

	results = append(results, InsightSection{
		SectionName:      "sentiment",
		Value:            float64(s.getSentiment(account.AccountNumber, period, startedAt)),
		PeriodStartedAt:  startedAt,
		Period:           period,
		DiffFromPrevious: 0.0,
	})

	c.JSON(http.StatusOK, gin.H{
		"result": results,
	})
}
