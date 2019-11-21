package logmodule

import (
	"reflect"
	"time"

	"github.com/getsentry/sentry-go"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func Ginrus(server string) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		c.Next()

		end := time.Now()
		latency := end.Sub(start)

		entry := log.WithFields(log.Fields{
			"prefix":    "gin",
			"requester": c.GetString("requester"),
			"status":    c.Writer.Status(),
			"method":    c.Request.Method,
			"path":      path,
			"latency":   latency,
		})

		requester := c.GetString("requester")
		if len(requester) > 0 {
			entry.WithField("requester", requester)
		}

		if len(c.Errors) > 0 {
			entry.Error(c.Errors.String())

			go func() {
				for _, err := range c.Errors {
					exception := err.Err
					event := sentry.NewEvent()
					event.Level = sentry.LevelError
					event.Message = exception.Error()
					stacktrace := sentry.ExtractStacktrace(exception)

					if stacktrace != nil {
						stacktrace = sentry.NewStacktrace()
					}
					event.Exception = []sentry.Exception{{
						Value:      exception.Error(),
						Type:       reflect.TypeOf(exception).String(),
						Stacktrace: stacktrace,
					}}
					event.User = sentry.User{
						Username: requester,
					}
					event.Logger = "gin"

					sentry.CaptureEvent(event)
				}
			}()

		} else {
			entry.Debug(server)
		}
	}
}
