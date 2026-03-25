-- schema.sql — SQLite database schema for the EA's operational state
-- Initialize: sqlite3 ~/.config/ziggy/memory.db < schema.sql

CREATE TABLE IF NOT EXISTS contacts (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT NOT NULL,
    email           TEXT,
    phone           TEXT,
    relationship    TEXT DEFAULT 'unknown',
    persona         TEXT DEFAULT 'executive_assistant',
    notes           TEXT,
    first_seen      TEXT,
    last_seen       TEXT,
    nickname        TEXT,
    title           TEXT,
    bio             TEXT,
    instruments     TEXT
);

CREATE TABLE IF NOT EXISTS emails (
    message_id      TEXT PRIMARY KEY,
    thread_id       TEXT,
    from_email      TEXT,
    from_name       TEXT,
    subject         TEXT,
    received_at     TEXT,
    replied         INTEGER DEFAULT 0,
    replied_at      TEXT,
    reply_message_id TEXT
);

CREATE TABLE IF NOT EXISTS sms_messages (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    sid             TEXT UNIQUE,
    direction       TEXT NOT NULL,
    from_number     TEXT NOT NULL,
    to_number       TEXT NOT NULL,
    body            TEXT,
    status          TEXT,
    date_sent       TEXT,
    date_created    TEXT,
    replied         INTEGER DEFAULT 0,
    reply_sid       TEXT,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sms_opt_outs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    phone_number    TEXT UNIQUE NOT NULL,
    opted_out_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmation_sent INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS calendar_events (
    event_id        TEXT PRIMARY KEY,
    calendar_id     TEXT,
    title           TEXT,
    start_time      TEXT,
    end_time        TEXT,
    location        TEXT,
    description     TEXT,
    status          TEXT,
    last_polled     TEXT
);

CREATE TABLE IF NOT EXISTS state (
    key             TEXT PRIMARY KEY,
    value           TEXT,
    updated_at      TEXT
);
