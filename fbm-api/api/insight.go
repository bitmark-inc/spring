package api

import (
	"net/http"
	"time"

	"github.com/bitmark-inc/fbm-apps/fbm-api/protomodel"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func getTotalFBIncomeForDataPeriod(lookupRange []fbIncomePeriod, from, to int64) float64 {
	amount := 0.0

	if len(lookupRange) == 0 {
		return amount
	}

	quarterIndex := 0
	for {
		currentQuarter := lookupRange[quarterIndex]

		if currentQuarter.StartedAt > from { // if from is far in the past, move it up the the latest point facebook as income
			from = currentQuarter.StartedAt
		} else if from > currentQuarter.EndedAt { // our of current quarter, check next quarter
			quarterIndex++
		} else { // from is in current quarter
			amount += currentQuarter.QuarterAmount / 90
			from += 24 * 60 * 60 // next day
		}

		if from > to || quarterIndex >= len(lookupRange) {
			break
		}
	}

	return amount
}

func (s *Server) getFBIncomeFromUserData(account *store.Account) float64 {
	f, ok := account.Metadata["original_timestamp"].(float64)
	if !ok {
		return -1
	}
	from := int64(f)

	t, ok := account.Metadata["latest_activity_timestamp"].(float64)
	var to int64
	if !ok {
		to = time.Now().Unix()
	} else {
		to = int64(t)
	}

	log.Info(to)

	countryCode := ""
	if c, ok := account.Metadata["original_location"].(string); ok {
		countryCode = c
	}

	// Logic: if there is no country code, it's world-wide area
	// if it's us/canada, then area is us-canada
	// if it's europe or asia, then area is either
	// fallback to rest if can not look it up
	var lookupRange []fbIncomePeriod

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

	return getTotalFBIncomeForDataPeriod(lookupRange, from, to)
}

func (s *Server) getInsight(c *gin.Context) {
	account := c.MustGet("account").(*store.Account)

	// fb income for data
	fbIncome := s.getFBIncomeFromUserData(account)

	responseWithEncoding(c, http.StatusOK, &protomodel.InsightResponse{
		Result: &protomodel.Insight{
			FbIncome: fbIncome,
		},
	})
}
