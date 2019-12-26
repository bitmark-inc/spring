package main

import (
	"context"
	"encoding/hex"
	"errors"
	"io"
	"mime"
	"net/http"
	"net/http/httputil"
	"strconv"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/getsentry/sentry-go"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"golang.org/x/crypto/sha3"
)

func (b *BackgroundContext) downloadArchive(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	fileURL := job.ArgString("file_url")
	rawCookie := job.ArgString("raw_cookie")
	archiveid := job.ArgInt64("archive_id")
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()
	req, err := http.NewRequestWithContext(ctx, "GET", fileURL, nil)
	if err != nil {
		logEntity.Error(err)
		return err
	}

	headerPrefix := "header_"
	for k, v := range job.Args {
		if strings.HasPrefix(k, headerPrefix) {
			req.Header.Set(k[len(headerPrefix):], v.(string))
		}
	}

	req.Header.Set("Cookie", rawCookie)

	reqDump, err := httputil.DumpRequest(req, true)
	if err != nil {
		logEntity.Error(err)
	}
	logEntity.WithField("dump", string(reqDump)).Info("Request dump")

	resp, err := b.httpClient.Do(req)
	if err != nil {
		logEntity.Error(err)
		return err
	}

	job.Checkin("Start downloading archives")

	// Print out the response in console log
	dumpBytes, err := httputil.DumpResponse(resp, false)
	if err != nil {
		logEntity.Error(err)
	}
	dump := string(dumpBytes)
	logEntity.Info("response: ", dump)

	if resp.StatusCode > 300 {
		logEntity.Error("Request failed")
		job.Checkin("Request failed")
		sentry.CaptureException(errors.New("Request failed"))
		return nil
	}

	sess := session.New(b.awsConf)
	svc := s3manager.NewUploader(sess)

	_, p, err := mime.ParseMediaType(resp.Header.Get("Content-Disposition"))
	if err != nil {
		logEntity.Error(err)
		job.Checkin("Looks like it's a html page")
		sentry.CaptureException(err)
		return nil
	}
	filename := p["filename"]

	h := sha3.New512()
	teeReader := io.TeeReader(resp.Body, h)

	defer resp.Body.Close()

	logEntity.Info("Start uploading to S3")
	job.Checkin("Start uploading to S3")

	s3key := "archives/" + accountNumber + "/" + filename
	_, err = svc.Upload(&s3manager.UploadInput{
		Bucket: aws.String(viper.GetString("aws.s3.bucket")),
		Key:    aws.String(s3key),
		Body:   teeReader,
		Metadata: map[string]*string{
			"url":        aws.String(fileURL),
			"archive_id": aws.String(strconv.FormatInt(archiveid, 10)),
		},
	})

	if err != nil {
		logEntity.Error(err)
		return err
	}

	// Get fingerprint
	fingerprintBytes := h.Sum(nil)
	fingerprint := hex.EncodeToString(fingerprintBytes)

	_, err = b.store.UpdateFBArchiveStatus(ctx, &store.FBArchiveQueryParam{
		ID: &archiveid,
	}, &store.FBArchiveQueryParam{
		S3Key:       &s3key,
		Status:      &store.FBArchiveStatusStored,
		ContentHash: &fingerprint,
	})
	if err != nil {
		logEntity.Error(err)
		return err
	}

	// enqueuer.EnqueueUniqueIn(jobUploadArchive, 3, map[string]interface{}{
	// 	"s3_key":         s3key,
	// 	"account_number": accountNumber,
	// 	"archive_id":     archiveid,
	// })

	logEntity.Info("Finish...")

	return nil
}
