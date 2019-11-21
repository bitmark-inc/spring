package store

import (
	"context"

	"github.com/bitmark-inc/fbm-apps/fbm-api/logmodule"

	sq "github.com/Masterminds/squirrel"
	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/spf13/viper"
)

type contextKey int

const (
	pgTransactionCtx contextKey = iota
)

// PGStore will store on postgres
type PGStore struct {
	Store
	pool *pgxpool.Pool
}

var psql = sq.StatementBuilder.PlaceholderFormat(sq.Dollar)

// NewPGStore new instance of postgres store
func NewPGStore(ctx context.Context) (*PGStore, error) {
	conf, err := pgxpool.ParseConfig(viper.GetString("db.conn"))
	conf.ConnConfig.Logger = &logmodule.PgxLogger{}

	p, err := pgxpool.ConnectConfig(ctx, conf)
	if err != nil {
		return nil, err
	}
	return &PGStore{
		pool: p,
	}, nil
}

func (s *PGStore) Ping(ctx context.Context) error {
	_, err := s.pool.Exec(ctx, ";")
	return err
}

func (s *PGStore) Close(ctx context.Context) error {
	s.pool.Close()
	return nil
}

func (s *PGStore) BeginTransaction(ctx context.Context) (context.Context, error) {
	tx, err := s.pool.Begin(ctx)
	return context.WithValue(ctx, pgTransactionCtx, tx), err
}

func (s *PGStore) CommitTransaction(ctx context.Context) error {
	if tx := s.transactionFromContext(ctx); tx != nil {
		return tx.Commit(ctx)
	}

	return nil
}

func (s *PGStore) transactionFromContext(ctx context.Context) pgx.Tx {
	if tx, ok := ctx.Value(pgTransactionCtx).(pgx.Tx); ok {
		return tx
	}

	return nil
}
