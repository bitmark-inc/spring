package store

import (
	"time"
)

// Account represents a seller or buyer
type Account struct {
	AccountNumber       string                 `json:"account_number"`
	EncryptionPublicKey []byte                 `json:"-"`
	Metadata            map[string]interface{} `json:"metadata"`
	CreatedAt           time.Time              `json:"created_at"`
	UpdatedAt           time.Time              `json:"updated_at"`
}

// Token represents an token on behalf of an account
type Token struct {
	Token         string
	AccountNumber string
	Info          map[string]interface{}
	CreatedAt     time.Time
	ExpireAt      time.Time
}

// FBArchive represents a fb archive information
type FBArchive struct {
	ID               int64     `json:"id"`
	AccountNumber    string    `json:"-"`
	S3Key            string    `json:"-"`
	StartingTime     time.Time `json:"started_at"`
	EndingTime       time.Time `json:"ended_at"`
	ProcessingStatus string    `json:"status"`
	AnalyzedTaskID   string    `json:"analyzed_task_id,omitempty"`
	ContentHash      string    `json:"content_hash,omitempty"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}
