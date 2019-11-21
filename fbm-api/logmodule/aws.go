package logmodule

import (
	"github.com/aws/aws-sdk-go/aws"
	log "github.com/sirupsen/logrus"
)

type AWSLog struct {
	aws.Logger
}

func (a *AWSLog) Log(args ...interface{}) {
	logEntry := log.WithField("prefix", "aws")
	logEntry.Debug(args...)
}
