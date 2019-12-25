package main

import (
	"context"
	"io/ioutil"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

func (b *BackgroundContext) submitArchive(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	s3key := job.ArgString("s3_key")
	archiveid := job.ArgInt64("archive_id")
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()

	sess := session.New(b.awsConf)
	downloader := s3manager.NewDownloader(sess)

	tmpFile, err := ioutil.TempFile(os.TempDir(), "fbarchives-*.zip")
	if err != nil {
		logEntity.Error(err)
		return err
	}

	defer tmpFile.Close()
	// Remember to clean up the file afterwards
	defer os.Remove(tmpFile.Name())

	_, err = downloader.Download(tmpFile,
		&s3.GetObjectInput{
			Bucket: aws.String(viper.GetString("aws.s3.bucket")),
			Key:    aws.String(s3key),
		})

	if err != nil {
		logEntity.Error(err)
		return err
	}

	logEntity.Info("Downloaded zip file. Start submiting")
	job.Checkin("Downloaded zip file. Start submiting")

	taskID, err := b.bitSocialClient.UploadArchives(ctx, tmpFile, accountNumber)
	if err != nil {
		logEntity.Error(err)
		return err
	}

	logEntity.Info("Upload success, update db information")

	if _, err := b.store.UpdateFBArchiveStatus(ctx, &store.FBArchiveQueryParam{
		ID: &archiveid,
	}, &store.FBArchiveQueryParam{
		AnalyzedID: &taskID,
	}); err != nil {
		logEntity.Error(err)
		return err
	}

	logEntity.Info("Finish...")
	enqueuer.EnqueueIn(jobPeriodicArchiveCheck, 60*10, map[string]interface{}{
		"archive_id": archiveid,
	})
	return nil
}

func (b *BackgroundContext) checkArchive(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	archiveid := job.ArgInt64("archive_id")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()

	archives, err := b.store.GetFBArchives(ctx, &store.FBArchiveQueryParam{
		ID: &archiveid,
	})
	if err != nil {
		logEntity.Error(err)
		return err
	}

	if len(archives) != 1 {
		logEntity.Warn("Cannot find archive with ID: ", archiveid)
		return nil
	}

	status, err := b.bitSocialClient.GetArchiveTaskStatus(ctx, archives[0].AnalyzedTaskID)
	if err != nil {
		logEntity.Error(err)
		return err
	}
	log.Info("Receive status: ", status)

	switch status {
	case "FAILURE":
		if _, err := b.store.UpdateFBArchiveStatus(ctx, &store.FBArchiveQueryParam{
			ID: &archiveid,
		}, &store.FBArchiveQueryParam{
			Status: &store.FBArchiveStatusInvalid,
		}); err != nil {
			logEntity.Error(err)
			return err
		}
	case "SUCCESS":
		if _, err := b.store.UpdateFBArchiveStatus(ctx, &store.FBArchiveQueryParam{
			ID: &archiveid,
		}, &store.FBArchiveQueryParam{
			Status: &store.FBArchiveStatusProcessed,
		}); err != nil {
			logEntity.Error(err)
			return err
		}
		if _, err := enqueuer.EnqueueIn(jobAnalyzePosts, 3, work.Q{
			"account_number": "example_public_key",
		}); err != nil {
			logEntity.Error(err)
			return err
		}
	default:
		// Retry after 10 minutes
		log.Info("Retry after 10 minutes")
		if _, err := enqueuer.EnqueueIn(jobPeriodicArchiveCheck, 10*60, map[string]interface{}{
			"archive_id": archiveid,
		}); err != nil {
			return err
		}
	}

	logEntity.Info("Finish...")

	return nil
}
