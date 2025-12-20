-- AurumHarmony D1 Database Schema
-- Run with: wrangler d1 execute aurum-harmony-db --file=worker/schema.sql

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    phone TEXT UNIQUE,
    password_hash TEXT NOT NULL,
    user_code TEXT UNIQUE NOT NULL,
    is_admin INTEGER DEFAULT 0 NOT NULL,
    is_active INTEGER DEFAULT 1 NOT NULL,
    date_of_birth TEXT,
    anniversary TEXT,
    initial_capital REAL DEFAULT 10000.0 NOT NULL,
    max_trades_per_index TEXT,
    max_accounts_allowed INTEGER DEFAULT 1 NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_user_code ON users(user_code);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    session_token TEXT UNIQUE NOT NULL,
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL,
    last_accessed TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);

-- Broker credentials table
CREATE TABLE IF NOT EXISTS broker_credentials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    broker_name TEXT NOT NULL,
    api_key TEXT,
    api_secret TEXT,
    token_id TEXT,
    access_token TEXT,
    refresh_token TEXT,
    is_active INTEGER DEFAULT 1 NOT NULL,
    expires_at TEXT,
    last_validated TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_broker_credentials_user_id ON broker_credentials(user_id);
CREATE INDEX IF NOT EXISTS idx_broker_credentials_broker_name ON broker_credentials(broker_name);
