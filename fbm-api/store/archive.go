package store

import (
	"context"
	"time"

	sq "github.com/Masterminds/squirrel"
	"github.com/jackc/pgx/v4"
)

// AddFBArchive to add an archive record from an account
func (p *PGStore) AddFBArchive(ctx context.Context, accountNumber string, starting, ending time.Time) (*FBArchive, error) {
	var fbArchive FBArchive

	q := psql.
		Insert("fbm.fbarchive").
		Columns("account_number", "file_key", "starting_time", "ending_time").
		Values(accountNumber, "", starting, ending).
		Suffix("RETURNING *")

	st, val, _ := q.ToSql()

	if err := p.pool.
		QueryRow(ctx, st, val...).
		Scan(&fbArchive.ID,
			&fbArchive.AccountNumber,
			&fbArchive.S3Key,
			&fbArchive.StartingTime,
			&fbArchive.EndingTime,
			&fbArchive.ProcessingStatus,
			&fbArchive.CreatedAt,
			&fbArchive.UpdatedAt); err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}

		return nil, err
	}

	return &fbArchive, nil
}

// UpdateFBArchiveStatus to update status for a particular fb archive record with s3 key
func (p *PGStore) UpdateFBArchiveStatus(ctx context.Context, params *FBArchiveQueryParam, values *FBArchiveQueryParam) ([]FBArchive, error) {
	q := psql.Update("fbm.fbarchive").
		Set("updated_at", time.Now()).
		Suffix("RETURNING *")

	if params.ID != nil {
		q = q.Where(sq.Eq{"id": *params.ID})
	}

	if params.S3Key != nil {
		q = q.Where(sq.Eq{"file_key": *params.S3Key})
	}

	if values.S3Key != nil {
		q = q.Set("file_key", *values.S3Key)
	}

	if values.Status != nil {
		q = q.Set("processing_status", *values.Status)
	}

	st, val, _ := q.ToSql()

	rows, err := p.pool.Query(ctx, st, val...)
	if err != nil {
		return nil, err
	}

	fbarchives := make([]FBArchive, 0)

	for rows.Next() {
		var fbArchive FBArchive

		if rows.Scan(&fbArchive.ID,
			&fbArchive.AccountNumber,
			&fbArchive.S3Key,
			&fbArchive.StartingTime,
			&fbArchive.EndingTime,
			&fbArchive.ProcessingStatus,
			&fbArchive.CreatedAt,
			&fbArchive.UpdatedAt); err != nil {
			return nil, err
		}

		fbarchives = append(fbarchives, fbArchive)
	}

	return fbarchives, nil
}

func (p *PGStore) GetFBArchives(ctx context.Context, params *FBArchiveQueryParam) ([]FBArchive, error) {
	q := psql.Select("*").
		From("fbm.fbarchive")

	if params.ID != nil {
		q = q.Where(sq.Eq{"id": *params.ID})
	}

	if params.S3Key != nil {
		q = q.Where(sq.Eq{"file_key": *params.S3Key})
	}

	if params.AccountNumber != nil {
		q = q.Where(sq.Eq{"account_number": *params.AccountNumber})
	}

	st, val, _ := q.ToSql()

	rows, err := p.pool.Query(ctx, st, val...)
	if err != nil {
		return nil, err
	}

	fbarchives := make([]FBArchive, 0)

	for rows.Next() {
		var fbArchive FBArchive

		if rows.Scan(&fbArchive.ID,
			&fbArchive.AccountNumber,
			&fbArchive.S3Key,
			&fbArchive.StartingTime,
			&fbArchive.EndingTime,
			&fbArchive.ProcessingStatus,
			&fbArchive.CreatedAt,
			&fbArchive.UpdatedAt); err != nil {
			return nil, err
		}

		fbarchives = append(fbarchives, fbArchive)
	}

	return fbarchives, nil
}