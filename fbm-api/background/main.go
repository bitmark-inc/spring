package main

import (
	"context"
	"flag"
	"fmt"
	"mime"
	"net/http"
	"net/http/httputil"
	"os"
	"os/signal"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/bitmark-inc/fbm-apps/fbm-api/background/onesignal"
	"github.com/gocraft/work"
	"github.com/gomodule/redigo/redis"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	prefixed "github.com/x-cray/logrus-prefixed-formatter"
)

type BackgroundContext struct {
	// AWS Config
	awsConf *aws.Config

	// http client
	httpClient *http.Client

	// External services
	oneSignalClient *onesignal.OneSignalClient
}

func initLog() {
	// Log
	logLevel, err := log.ParseLevel(viper.GetString("log.level"))
	if err != nil {
		log.SetLevel(log.DebugLevel)
	} else {
		log.SetLevel(logLevel)
	}

	log.SetOutput(os.Stdout)

	log.SetFormatter(&prefixed.TextFormatter{
		ForceFormatting: true,
		FullTimestamp:   true,
	})
}

func loadConfig(file string) {
	// Config from file
	viper.SetConfigType("yaml")
	if file != "" {
		viper.SetConfigFile(file)
	}

	viper.AddConfigPath("/.config/")
	viper.AddConfigPath(".")
	err := viper.ReadInConfig()
	if err != nil {
		fmt.Println("No config file. Read config from env.")
		viper.AllowEmptyEnv(false)
	}

	// Config from env if possible
	viper.AutomaticEnv()
	viper.SetEnvPrefix("fbm")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
}

func main() {
	var configFile string

	flag.StringVar(&configFile, "c", "./config.yaml", "[optional] path of configuration file")
	flag.Parse()

	loadConfig(configFile)

	initLog()

	httpClient := &http.Client{
		Timeout: 10 * time.Second,
	}

	awsConf := &aws.Config{
		Region:     aws.String(viper.GetString("aws.region")),
		HTTPClient: httpClient,
	}

	oneSignalClient := onesignal.NewClient(httpClient)

	b := BackgroundContext{
		awsConf:         awsConf,
		httpClient:      httpClient,
		oneSignalClient: oneSignalClient,
	}

	redisPool := &redis.Pool{
		MaxActive: 5,
		MaxIdle:   5,
		Wait:      true,
		Dial: func() (redis.Conn, error) {
			return redis.Dial("tcp", viper.GetString("redis.conn"), redis.DialPassword(viper.GetString("redis.password")))
		},
	}
	pool := work.NewWorkerPool(b, 2, "fbm", redisPool)

	// Add middleware for logging for each job
	pool.Middleware(b.Log)

	// Map the name of jobs to handler functions
	pool.Job("download_archive", b.DownloadArchive)

	log.Info("Start listening")

	// Start processing jobs
	pool.Start()

	// Wait for a signal to quit:
	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, os.Interrupt, os.Kill)
	<-signalChan

	// Stop the pool
	pool.Stop()
}

func (b *BackgroundContext) Log(job *work.Job, next work.NextMiddlewareFunc) error {
	log.WithField("args", job.Args).Info("Starting job: ", job.Name)
	return next()
}

func (b *BackgroundContext) DownloadArchive(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	fileURL := job.ArgString("file_url")
	rawCookie := job.ArgString("raw_cookie")
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

	// Print out the response in console log
	dumpBytes, err := httputil.DumpResponse(resp, false)
	if err != nil {
		logEntity.Error(err)
	}
	dump := string(dumpBytes)
	logEntity.Info("response: ", dump)

	if resp.StatusCode > 300 {
		logEntity.Error("Request failed")
		return nil
	}

	sess := session.New(b.awsConf)
	svc := s3manager.NewUploader(sess)

	_, p, err := mime.ParseMediaType(resp.Header.Get("Content-Disposition"))
	if err != nil {
		logEntity.Error(err)
		return nil
	}
	filename := p["filename"]

	defer resp.Body.Close()

	logEntity.Info("Start uploading to S3")

	_, err = svc.Upload(&s3manager.UploadInput{
		Bucket: aws.String(viper.GetString("aws.s3.bucket")),
		Key:    aws.String("archives/" + accountNumber + "/" + filename),
		Body:   resp.Body,
		Metadata: map[string]*string{
			"url": aws.String(fileURL),
		},
	})

	if err != nil {
		logEntity.Error(err)
		return err
	}

	logEntity.Info("Send notification to: ", accountNumber)
	if err := b.oneSignalClient.NotifyFBArchiveAvailable(ctx, accountNumber); err != nil {
		logEntity.Error(err)
		return err
	}

	logEntity.Info("Finish...")

	return nil
}
