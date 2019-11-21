package logmodule

import (
	log "github.com/sirupsen/logrus"
)

type NSQLog struct {
}

func (n *NSQLog) Output(calldepth int, s string) error {
	logEntry := log.WithField("prefix", "nsq")
	logEntry.Debug(s)

	return nil
}
