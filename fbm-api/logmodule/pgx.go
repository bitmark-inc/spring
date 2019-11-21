package logmodule

import (
	"context"

	"github.com/jackc/pgx/v4"
	log "github.com/sirupsen/logrus"
)

type PgxLogger struct {
	pgx.Logger
}

func (l *PgxLogger) Log(ctx context.Context, level pgx.LogLevel, msg string, data map[string]interface{}) {
	data["prefix"] = "pgx"
	logEntry := log.WithFields(data)
	switch level {
	case pgx.LogLevelTrace:
		logEntry.Debug(msg)
	case pgx.LogLevelDebug:
		logEntry.Debug(msg)
	case pgx.LogLevelInfo:
		logEntry.Debug(msg)
	case pgx.LogLevelWarn:
		logEntry.Warn(msg)
	case pgx.LogLevelError:
		logEntry.Error(msg)
	case pgx.LogLevelNone:
	default:
	}
}
