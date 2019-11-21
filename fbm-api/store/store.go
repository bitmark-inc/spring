package store

import (
	"context"
	"time"
)

// Store an interface to determine what to store in server
type Store interface {
	// Operation

	// Ping to ping the existing db for liveness proof
	Ping(ctx context.Context) error

	// Close to close the current db connection
	Close(ctx context.Context) error

	// Account

	// InsertAccount insert an account to the db with account number, alias and stripe's customer id
	// returns an Account object.
	InsertAccount(ctx context.Context, accountNumber string, encPubKey []byte) (*Account, error)

	// QueryAccount query for an account with condition from account number OR alias
	// leaves one of the condition empty to ignore.
	QueryAccount(ctx context.Context, params *AccountQueryParam) (*Account, error)

	// UpdateAccount to update account information
	UpdateAccount(ctx context.Context, a *Account) (bool, error)

	// AddToken to add a random token represent to an account for validating something
	AddToken(ctx context.Context, accountNumber string, info map[string]interface{}, expire time.Duration) (*Token, error)

	// UseToken to consume a token and
	UseToken(ctx context.Context, token string) (*Account, map[string]interface{}, error)
}

// AccountQueryParam params for querying an account
type AccountQueryParam struct {
	AccountNumber *string
}
