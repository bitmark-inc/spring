\connect postgres

-- note: the install-schema will use the password from etc/fbm.conf
--       in place of the tag below when loading this file into the database
CREATE USER fbm ENCRYPTED PASSWORD '@CHANGE-TO-SECURE-PASSWORD@';
-- connect to the database
\connect fbm

-- drop schema and all its objects, create the schema and use it by default
DROP SCHEMA IF EXISTS fbm CASCADE;
CREATE SCHEMA IF NOT EXISTS fbm;

SET search_path = fbm;                              -- everything in this schema for schema loading
ALTER ROLE fbm SET search_path TO fbm, PUBLIC;    -- ensure user sees the schema first

--- grant to fbm ---
GRANT USAGE ON SCHEMA fbm TO fbm;
ALTER DEFAULT PRIVILEGES IN SCHEMA fbm GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO fbm;
ALTER DEFAULT PRIVILEGES IN SCHEMA fbm GRANT SELECT, UPDATE ON SEQUENCES TO fbm;

-- account table
CREATE TABLE fbm.account (
    account_number TEXT NOT NULL PRIMARY KEY,
    enc_pub_key BYTEA DEFAULT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::json,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE fbm.token (
    id TEXT NOT NULL PRIMARY KEY,
    account_number TEXT NOT NULL REFERENCES fbm.account(account_number),
    info JSONB NOT NULL DEFAULT '{}'::json, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expired_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TYPE archive_status AS ENUM ('submitted', 'stored', 'processed', 'invalid');
CREATE TABLE fbm.fbarchive (
    id SERIAL PRIMARY KEY,
    account_number TEXT NOT NULL REFERENCES fbm.account(account_number), 
    file_key TEXT NOT NULL,
    starting_time TIMESTAMP WITH TIME ZONE NOT NULL,
    ending_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    analyzed_task_id TEXT DEFAULT '',
    content_hash TEXT DEFAULT '',
    processing_status archive_status DEFAULT 'submitted',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE fbm.fbdata (
    data_name TEXT PRIMARY KEY,
    data_value JSONB
);

CREATE INDEX fbarchive_filekey ON fbm.fbarchive (file_key);
CREATE INDEX fbarchive_account_number ON fbm.fbarchive (account_number);

-- finished
SET search_path TO DEFAULT;
