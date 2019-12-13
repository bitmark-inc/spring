package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/bitmark-inc/fbm-apps/fbm-api/external/onesignal"
	"github.com/gocraft/work"
	"github.com/gomodule/redigo/redis"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	prefixed "github.com/x-cray/logrus-prefixed-formatter"
)

var (
	enqueuer *work.Enqueuer
)

const (
	jobDownloadArchive = "download_archive"
	jobExtract         = "extract_zip"
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

	b := &BackgroundContext{
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
	pool := work.NewWorkerPool(*b, 2, "fbm", redisPool)
	enqueuer = work.NewEnqueuer("fbm", redisPool)

	// Add middleware for logging for each job
	pool.Middleware(b.log)

	// Map the name of jobs to handler functions
	pool.JobWithOptions(jobDownloadArchive, work.JobOptions{Priority: 10, MaxFails: 1}, b.downloadArchive)
	pool.JobWithOptions(jobExtract, work.JobOptions{Priority: 5, MaxFails: 1}, b.extractMedia)

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

func (b *BackgroundContext) log(job *work.Job, next work.NextMiddlewareFunc) error {
	log.WithField("args", job.Args).Info("Starting job: ", job.Name)
	return next()
}
