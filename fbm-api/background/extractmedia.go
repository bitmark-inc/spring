package main

import (
	"archive/zip"
	"context"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

func (b *BackgroundContext) extractMedia(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	s3key := job.ArgString("s3_key")
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

	size, err := downloader.Download(tmpFile,
		&s3.GetObjectInput{
			Bucket: aws.String(viper.GetString("aws.s3.bucket")),
			Key:    aws.String(s3key),
		})

	if err != nil {
		logEntity.Error(err)
		return nil
	}

	logEntity.Info("Downloaded zip file. Start unziping")
	job.Checkin("Downloaded zip file. Start unziping")

	uploader := s3manager.NewUploader(sess)

	r, err := zip.NewReader(tmpFile, size)
	if err != nil {
		logEntity.Error(err)
		return err
	}

	total := len(r.File)
	for i, f := range r.File {
		job.Checkin("Unziping: " + strconv.Itoa(i) + "/" + strconv.Itoa(total))
		if !strings.HasPrefix(f.Name, "photos_and_videos") ||
			strings.HasSuffix(f.Name, "no-data.txt") ||
			f.FileInfo().IsDir() {
			logEntity.Info("Skiping file: ", f.Name)
			continue
		}

		logEntity.Info("Upload file: ", f.Name)
		rc, err := f.Open()
		if err != nil {
			logEntity.Error(err)
			return err
		}

		_, err = uploader.Upload(&s3manager.UploadInput{
			Bucket: aws.String(viper.GetString("aws.s3.bucket")),
			Key:    aws.String("media/" + accountNumber + "/" + f.Name),
			Body:   rc,
			Metadata: map[string]*string{
				"from_zipfile": aws.String(s3key),
			},
		})

		if err != nil {
			logEntity.Error(err)
			rc.Close()
			return err
		}
		rc.Close()
	}

	logEntity.Info("Send notification to: ", accountNumber)
	job.Checkin("Send notification to: " + accountNumber)
	if err := b.oneSignalClient.NotifyFBArchiveAvailable(ctx, accountNumber); err != nil {
		logEntity.Error(err)
		return err
	}

	logEntity.Info("Finish...")

	return nil
}
