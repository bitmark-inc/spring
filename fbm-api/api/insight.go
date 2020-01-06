package api

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/bitmark-inc/fbm-apps/fbm-api/protomodel"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/gin-gonic/gin"
	"github.com/golang/protobuf/proto"
	log "github.com/sirupsen/logrus"
)

func getPreviousPeriodStartingPoint(period string, currentPeriodTimestamp int64) int64 {
	switch period {
	case "week":
		return currentPeriodTimestamp - 7*24*60*60
	case "year":
		return currentPeriodTimestamp - 365*24*60*60
	case "decade":
		return currentPeriodTimestamp - 10*365*24*60*60
	}
	return 0
}

func getNextPeriodStartingPoint(period string, currentPeriodTimestamp int64) int64 {
	switch period {
	case "week":
		return currentPeriodTimestamp + 7*24*60*60
	case "year":
		return currentPeriodTimestamp + 365*24*60*60
	case "decade":
		return currentPeriodTimestamp + 10*365*24*60*60
	}
	return 0
}

func getTotalFBIncomeForDataPeriod(period string, from int64, lookupRange []fbIncomePeriod) float64 {

	// "to" variable is to set the upper threshold for the period that is longer than quarter
	to := getNextPeriodStartingPoint(period, from) - 1

	amount := 0.0

	for _, v := range lookupRange {
		if period == "week" && from >= v.StartedAt {
			amount = v.QuarterAmount / 13
			break // for period shorter than quarter, we break right away
		} else if period == "year" && from <= v.StartedAt && to > v.StartedAt {
			log.Debug("Amount: ", v.QuarterAmount)
			amount += v.QuarterAmount
		} else if period == "decade" && from <= v.StartedAt && to > v.StartedAt {
			amount += v.QuarterAmount
		}
	}

	return amount
}

func (s *Server) getFBIncomeFromData(account *store.Account, period string, timestamp int64) float64 {
	countryCode := ""
	if c, ok := account.Metadata["original_location"].(string); ok {
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
	accountNumber := c.GetString("requester")
	account := c.MustGet("account").(*store.Account)

	period := c.Param("period")
	if period != "week" && period != "year" && period != "decade" {
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	startedAt, err := strconv.ParseInt(c.Query("started_at"), 10, 64)
	if err != nil {
		log.Debug(err)
		abortWithEncoding(c, http.StatusBadRequest, errorInvalidParameters)
		return
	}

	results := make([]*protomodel.Insight, 0)

	// fb income for data
	currentPeriodFBIncome := s.getFBIncomeFromData(account, period, startedAt)

	if currentPeriodFBIncome != 0 {
		previousPeriodFBIncome := s.getFBIncomeFromData(account, period, getPreviousPeriodStartingPoint(period, startedAt))

		var diff float64
		if previousPeriodFBIncome == 0 {
			diff = 1
		} else {
			diff = (currentPeriodFBIncome - previousPeriodFBIncome) / previousPeriodFBIncome
		}

		results = append(results, &protomodel.Insight{
			SectionName:      "fb-income",
			Value:            currentPeriodFBIncome,
			PeriodStartedAt:  startedAt,
			Period:           period,
			DiffFromPrevious: diff,
		})
	}

	sentimentStatData, err := s.fbDataStore.GetExactFBStat(c, fmt.Sprintf("%s/sentiment-%s-stat", accountNumber, period), startedAt)
	if shouldInterupt(err, c) {
		return
	}

	if sentimentStatData != nil {
		var sentimentStat protomodel.Insight
		err := proto.Unmarshal(sentimentStatData, &sentimentStat)
		if shouldInterupt(err, c) {
			return
		}
		results = append(results, &sentimentStat)
	}

	responseWithEncoding(c, http.StatusOK, &protomodel.InsightResponse{
		Result: results,
	})
}
