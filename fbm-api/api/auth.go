package api

import (
	"crypto/md5"
	"crypto/x509"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/bitmark-inc/bitmark-sdk-go/account"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	jwt "github.com/dgrijalva/jwt-go"
	jwtrequest "github.com/dgrijalva/jwt-go/request"
	"github.com/gin-gonic/gin"
	uuid "github.com/satori/go.uuid"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

func (s *Server) requestJWT(c *gin.Context) {
	var req struct {
		Timestamp string `json:"timestamp"`
		Signature string `json:"signature"`
		Requester string `json:"requester"`
	}

	if err := c.BindJSON(&req); err != nil {
		c.Error(err)
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	sig, err := hex.DecodeString(req.Signature)
	if err != nil {
		c.AbortWithStatusJSON(401, errorInvalidParameters)
		return
	}

	if err := account.Verify(req.Requester, []byte(req.Timestamp), sig); err != nil {
		c.AbortWithStatusJSON(401, errorInvalidSignature)
		return
	}

	t, err := strconv.ParseInt(req.Timestamp, 10, 64)
	if err != nil {
		c.AbortWithStatusJSON(401, errorInvalidParameters)
		return
	}

	created := time.Unix(0, t*1000000)
	now := time.Unix(0, time.Now().UnixNano())
	duration := now.Sub(created)
	if math.Abs(duration.Minutes()) > float64(5) {
		c.AbortWithStatusJSON(401, errorAuthorizationExpired)
		return
	}

	exp := now.Add(time.Duration(viper.GetInt("jwt.expire")) * time.Hour)

	jwtPubKeyByte := x509.MarshalPKCS1PublicKey(&s.jwtPrivateKey.PublicKey)
	pubkeyMd5sum := md5.Sum(jwtPubKeyByte)
	clientID := base64.StdEncoding.EncodeToString(pubkeyMd5sum[:])

	// Create a new token object, specifying signing method and the claims
	// you would like it to contain.
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.StandardClaims{
		Issuer:    clientID,
		Subject:   req.Requester,
		ExpiresAt: exp.Unix(),
		IssuedAt:  now.Unix(),
		Id:        uuid.NewV4().String(),
		Audience:  "write",
	})

	tokenString, err := token.SignedString(s.jwtPrivateKey)
	if err != nil {
		c.Error(err)
		c.AbortWithStatusJSON(http.StatusInternalServerError, errorInternalServer)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"jwt_token": tokenString,
		"expire_in": time.Hour.Milliseconds(),
	})
}

// authMiddleware is a middleware to authorize users from using our APIs
// with new authentication method.
// Header format:
// - Authorization: 'Bearer xxxxxx.xxxxxxxx.xxxx' JWT payload
func (s *Server) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		claims := &jwt.StandardClaims{}
		token, err := jwtrequest.ParseFromRequest(c.Request,
			jwtrequest.AuthorizationHeaderExtractor,
			func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
					return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
				}

				return &s.jwtPrivateKey.PublicKey, nil
			},
			jwtrequest.WithClaims(claims),
		)

		if err != nil {
			log.WithError(err).Debug("authorization error")
			c.AbortWithStatusJSON(http.StatusBadRequest, errorInvalidAuthorizationFormat)
			return
		}

		if !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, errorInvalidAuthorizationFormat)
			return
		}

		c.Set("requester", claims.Subject)
		c.Next()
	}
}

func (s *Server) recognizeAccountMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requester := c.GetString("requester")
		account, err := s.store.QueryAccount(c, &store.AccountQueryParam{
			AccountNumber: &requester,
		})
		if shouldInterupt(err, c) {
			return
		}

		if account == nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, errorAccountNotFound)
			return
		}

		c.Set("account", account)
	}
}
