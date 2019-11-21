package api

import "github.com/gin-gonic/gin"

var (
	errorMessageMap = map[int]string{
		999:  "internal server error",
		1000: "invalid signature",
		1001: "invalid authorization format",
		1002: "authorization expired",
		1003: "his account has been registered or has been taken",
		1004: "invalid parameters",
		1005: "cannot parse request",
		1006: "account not found",
	}

	errorInternalServer             = errorJSON(999)
	errorInvalidSignature           = errorJSON(1000)
	errorInvalidAuthorizationFormat = errorJSON(1001)
	errorAuthorizationExpired       = errorJSON(1002)
	errorAccountTaken               = errorJSON(1003)
	errorInvalidParameters          = errorJSON(1004)
	errorCannotParseRequest         = errorJSON(1005)
	errorAccountNotFound            = errorJSON(1006)
)

// errorJSON converts an error code to a standardized error object
func errorJSON(code int) gin.H {
	var message string
	if msg, ok := errorMessageMap[code]; ok {
		message = msg
	} else {
		message = "unknown"
	}

	return gin.H{
		"error": gin.H{
			"code":    code,
			"message": message,
		},
	}
}
