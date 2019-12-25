package main

import (
	"context"

	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
)

func (b *BackgroundContext) notifyAnalyzingDone(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()

	if err := b.oneSignalClient.NotifyFBArchiveAvailable(ctx, accountNumber); err != nil {
		logEntity.Error(err)
		return err
	}

	return nil
}
