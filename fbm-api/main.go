package main

import (
	"context"
	"encoding/hex"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	bitmarksdk "github.com/bitmark-inc/bitmark-sdk-go"
	"github.com/bitmark-inc/bitmark-sdk-go/account"
	"github.com/bitmark-inc/fbm-apps/fbm-api/api"
	"github.com/bitmark-inc/fbm-apps/fbm-api/logmodule"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/dgrijalva/jwt-go"
	"github.com/getsentry/sentry-go"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	prefixed "github.com/x-cray/logrus-prefixed-formatter"
)

var (
	server *api.Server
	s      store.Store
)

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

	initialCtx, cancelInitialization := context.WithCancel(context.Background())

	c := make(chan os.Signal, 2)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-c
		log.Info("Server is preparing to shutdown")

		if initialCtx != nil && cancelInitialization != nil {
			log.Info("Cancelling initialization")
			cancelInitialization()
			<-initialCtx.Done()
		}

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if server != nil {
			log.Info("Shutdown mobile api server")
			if err := server.Shutdown(ctx); err != nil {
				log.Error("Server Shutdown:", err)
			}
		}

		if s != nil {
			log.Info("Shuting down db store")
			if err := s.Close(ctx); err != nil {
				log.Error(err)
			}
		}

		os.Exit(1)
	}()

	flag.StringVar(&configFile, "c", "./config.yaml", "[optional] path of configuration file")
	flag.Parse()

	loadConfig(configFile)

	initLog()

	httpClient := &http.Client{
		Timeout: 10 * time.Second,
	}

	// Sentry
	if err := sentry.Init(sentry.ClientOptions{
		Dsn:              viper.GetString("sentry.dsn"),
		AttachStacktrace: true,
		Environment:      viper.GetString("bitmarksdk.network"),
		Dist:             viper.GetString("sentry.dist"),
	}); err != nil {
		log.Error(err)
	}
	log.WithField("prefix", "init").Info("Initilized sentry")

	// Init Bitmark SDK
	bitmarksdk.Init(&bitmarksdk.Config{
		Network:    bitmarksdk.Network(viper.GetString("bitmarksdk.network")),
		APIToken:   viper.GetString("bitmarksdk.token"),
		HTTPClient: httpClient,
	})
	log.WithField("prefix", "init").Info("Initilized bitmark sdk")

	// Load global bitmark account
	a, err := account.FromSeed(viper.GetString("account.seed"))
	if err != nil {
		log.Panic(err)
	}
	globalAccount := a.(*account.AccountV2)
	log.WithField("prefix", "init").Info("Global account: ", globalAccount.AccountNumber())
	log.WithField("prefix", "init").Info("Global enc pub key: ", hex.EncodeToString(globalAccount.EncrKey.PublicKeyBytes()))

	// Init AWS SDK
	awsLogLevel := aws.LogDebugWithRequestErrors
	awsConf := &aws.Config{
		Region:     aws.String(viper.GetString("aws.region")),
		Logger:     &logmodule.AWSLog{},
		LogLevel:   &awsLogLevel,
		HTTPClient: httpClient,
	}
	log.WithField("prefix", "init").Info("Initilized aws sdk")

	// Load JWT private key
	jwtSecretByte, err := ioutil.ReadFile(viper.GetString("jwt.keyfile"))
	if err != nil {
		log.Panic(err)
	}
	jwtPrivateKey, err := jwt.ParseRSAPrivateKeyFromPEMWithPassword(jwtSecretByte, viper.GetString("jwt.password"))
	if err != nil {
		log.Panic(err)
	}
	log.WithField("prefix", "init").Info("Loaded global jwt key")

	// Init db
	pgstore, err := store.NewPGStore(initialCtx)
	if err != nil {
		log.Panic(err)
	}
	s = pgstore
	log.WithField("prefix", "init").Info("Initilized db store")

	// Init http server
	server = api.NewServer(s,
		jwtPrivateKey,
		awsConf,
		globalAccount)
	log.WithField("prefix", "init").Info("Initilized http server")

	// Remove initial context
	initialCtx = nil
	cancelInitialization = nil

	log.Fatal(server.Run(":" + viper.GetString("server.port")))
}
