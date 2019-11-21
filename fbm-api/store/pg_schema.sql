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

-- finished
SET search_path TO DEFAULT;
