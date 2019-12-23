package api

import (
	"context"
	"crypto/rsa"
	"encoding/hex"
	log "github.com/sirupsen/logrus"
	"net/http"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/bitmark-inc/bitmark-sdk-go/account"
	"github.com/bitmark-inc/fbm-apps/fbm-api/external/fbarchive"
	"github.com/bitmark-inc/fbm-apps/fbm-api/external/onesignal"
	"github.com/bitmark-inc/fbm-apps/fbm-api/logmodule"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	sentrygin "github.com/getsentry/sentry-go/gin"
	"github.com/gin-gonic/gin"
	"github.com/gocraft/work"
	"github.com/spf13/viper"
)

// Server to run a http server instance
type Server struct {
	// Server instance
	server *http.Server

	// Stores
	store       store.Store
	fbDataStore store.FBDataStore

	// JWT private key
	jwtPrivateKey *rsa.PrivateKey

	// AWS Config
	awsConf *aws.Config

	// External services
	oneSignalClient *onesignal.OneSignalClient
	bitSocialClient *fbarchive.Client

	// account
	bitmarkAccount *account.AccountV2

	// http client for calling external services
	httpClient *http.Client

	// job pool enqueuer
	backgroundEnqueuer *work.Enqueuer
}

// NewServer new instance of server
func NewServer(store store.Store,
	fbDataStore store.FBDataStore,
	jwtKey *rsa.PrivateKey,
	awsConf *aws.Config,
	bitmarkAccount *account.AccountV2,
	backgroundEnqueuer *work.Enqueuer) *Server {
	httpClient := &http.Client{
		Timeout: 5 * time.Minute,
	}
	return &Server{
		store:              store,
		fbDataStore:        fbDataStore,
		jwtPrivateKey:      jwtKey,
		awsConf:            awsConf,
		httpClient:         httpClient,
		bitmarkAccount:     bitmarkAccount,
		oneSignalClient:    onesignal.NewClient(httpClient),
		bitSocialClient:    fbarchive.NewClient(httpClient),
		backgroundEnqueuer: backgroundEnqueuer,
	}
}

// Run to run the server
func (s *Server) Run(addr string) error {
	// Login to bitsocial server
	ctx := context.Background()
	if err := s.bitSocialClient.Login(ctx, viper.GetString("fbarchive.username"), viper.GetString("fbarchive.password")); err != nil {
		return err
	}
	log.Info("Success logged in to bitsocial server")

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(sentrygin.New(sentrygin.Options{
		Repanic:         true,
		WaitForDelivery: false,
		Timeout:         10 * time.Second,
	}))

	webhookRoute := r.Group("/webhook")
	webhookRoute.Use(logmodule.Ginrus("Webhook"))
	{
	}

	apiRoute := r.Group("/api")
	apiRoute.Use(logmodule.Ginrus("API"))
	apiRoute.GET("/information", s.information)

	apiRoute.POST("/auth", s.requestJWT)

	accountRoute := apiRoute.Group("/accounts")
	accountRoute.Use(s.authMiddleware())
	{
		accountRoute.POST("", s.accountRegister)
	}
	accountRoute.Use(s.meRoute("me"))
	accountRoute.Use(s.recognizeAccountMiddleware())
	{
		accountRoute.GET("/:account_number", s.accountDetail)
	}

	archivesRoute := apiRoute.Group("/archives")
	archivesRoute.Use(s.authMiddleware())
	archivesRoute.Use(s.recognizeAccountMiddleware())
	{
		archivesRoute.POST("", s.downloadFBArchive)
		archivesRoute.GET("", s.getAllArchives)
	}

	postRoute := apiRoute.Group("/posts")
	{
		postRoute.GET("", s.getAllPosts)
	}

	reactionRoute := apiRoute.Group("/reactions")
	{
		reactionRoute.GET("", s.getAllReactions)
	}

	usageRoute := apiRoute.Group("/usage")
	{
		usageRoute.GET("/:period", s.getPostStats)
	}

	assetRoute := r.Group("/assets")
	assetRoute.Use(logmodule.Ginrus("Asset"))
	{
		assetRoute.Static("", viper.GetString("server.assetdir"))
	}

	r.GET("/healthz", s.healthz)
	r.GET("/test", s.parseArchive)
	r.GET("/prepare-reactions", s.prepareReactionsData)

	srv := &http.Server{
		Addr:    addr,
		Handler: r,
	}

	s.server = srv

	return srv.ListenAndServe()
}

// Shutdown to shutdown the server
func (s *Server) Shutdown(ctx context.Context) error {
	return s.server.Shutdown(ctx)
}

// shouldInterupt sends error message and determine if it should interupt the current flow
func shouldInterupt(err error, c *gin.Context) bool {
	if err == nil {
		return false
	}

	c.Error(err)
	c.AbortWithStatusJSON(http.StatusInternalServerError, errorInternalServer)

	return true
}

func (s *Server) healthz(c *gin.Context) {
	// Ping db
	err := s.store.Ping(c)
	if shouldInterupt(err, c) {
		return
	}

	// Check status of bitSocial client
	if !s.bitSocialClient.IsReady() {
		c.JSON(http.StatusOK, gin.H{
			"status": "booting up",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "OK",
		"version": viper.GetString("server.version"),
	})
}

func (s *Server) information(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"information": map[string]map[string]interface{}{
			"server": map[string]interface{}{
				"version":                viper.GetString("server.version"),
				"enc_pub_key":            hex.EncodeToString(s.bitmarkAccount.EncrKey.PublicKeyBytes()),
				"bitmark_account_number": s.bitmarkAccount.AccountNumber(),
			},
			"android": viper.GetStringMap("clients.android"),
			"ios":     viper.GetStringMap("clients.ios"),
		},
	})
}
