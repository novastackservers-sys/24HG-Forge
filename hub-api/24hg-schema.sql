-- 24HG Linux Distro - Hub API Schema
-- SQLite schema for 24HG Hub integration

CREATE TABLE IF NOT EXISTS hg24_installations (
    machine_id   TEXT PRIMARY KEY,
    os_version   TEXT NOT NULL,
    gpu          TEXT,
    cpu          TEXT,
    username     TEXT,
    first_seen   DATETIME NOT NULL DEFAULT (datetime('now')),
    last_seen    DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_hg24_installations_last_seen ON hg24_installations(last_seen);
CREATE INDEX idx_hg24_installations_username  ON hg24_installations(username);

CREATE TABLE IF NOT EXISTS hg24_rig_scores (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_id    TEXT NOT NULL,
    username      TEXT NOT NULL,
    cpu_score     REAL NOT NULL DEFAULT 0,
    gpu_score     REAL NOT NULL DEFAULT 0,
    ram_score     REAL NOT NULL DEFAULT 0,
    storage_score REAL NOT NULL DEFAULT 0,
    total_score   REAL NOT NULL DEFAULT 0,
    cpu_model     TEXT,
    gpu_model     TEXT,
    ram_gb        REAL,
    created_at    DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_hg24_rig_scores_total    ON hg24_rig_scores(total_score DESC);
CREATE INDEX idx_hg24_rig_scores_cpu      ON hg24_rig_scores(cpu_score DESC);
CREATE INDEX idx_hg24_rig_scores_gpu      ON hg24_rig_scores(gpu_score DESC);
CREATE INDEX idx_hg24_rig_scores_username ON hg24_rig_scores(username);

CREATE TABLE IF NOT EXISTS hg24_achievements (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    username       TEXT NOT NULL,
    achievement_id TEXT NOT NULL,
    unlocked_at    DATETIME NOT NULL,
    synced_at      DATETIME NOT NULL DEFAULT (datetime('now')),
    UNIQUE(username, achievement_id)
);

CREATE INDEX idx_hg24_achievements_username ON hg24_achievements(username);

CREATE TABLE IF NOT EXISTS hg24_cloud_saves (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT NOT NULL,
    machine_id TEXT NOT NULL,
    game       TEXT NOT NULL,
    save_path  TEXT NOT NULL,
    checksum   TEXT NOT NULL,
    size_bytes INTEGER NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_hg24_cloud_saves_username ON hg24_cloud_saves(username);
CREATE INDEX idx_hg24_cloud_saves_game     ON hg24_cloud_saves(username, game);

CREATE TABLE IF NOT EXISTS hg24_game_compat (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    game_name      TEXT NOT NULL,
    steam_appid    INTEGER,
    works          INTEGER NOT NULL DEFAULT 1,
    rating         INTEGER CHECK(rating BETWEEN 1 AND 5),
    gpu            TEXT,
    proton_version TEXT,
    notes          TEXT,
    username       TEXT,
    created_at     DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_hg24_game_compat_appid ON hg24_game_compat(steam_appid);
CREATE INDEX idx_hg24_game_compat_game  ON hg24_game_compat(game_name);

CREATE TABLE IF NOT EXISTS hg24_gallery (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT NOT NULL,
    filename   TEXT NOT NULL,
    game       TEXT,
    caption    TEXT,
    file_path  TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_hg24_gallery_username ON hg24_gallery(username);
CREATE INDEX idx_hg24_gallery_game     ON hg24_gallery(game);
CREATE INDEX idx_hg24_gallery_created  ON hg24_gallery(created_at DESC);

CREATE TABLE IF NOT EXISTS hg24_voice_rooms (
    room_name   TEXT PRIMARY KEY,
    created_at  DATETIME NOT NULL DEFAULT (datetime('now')),
    last_active DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_hg24_voice_rooms_active ON hg24_voice_rooms(last_active);
