-- Forge Linux Distro - Hub API Schema
-- SQLite schema for 24HG Hub integration

CREATE TABLE IF NOT EXISTS forge_installations (
    machine_id   TEXT PRIMARY KEY,
    os_version   TEXT NOT NULL,
    gpu          TEXT,
    cpu          TEXT,
    username     TEXT,
    first_seen   DATETIME NOT NULL DEFAULT (datetime('now')),
    last_seen    DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_forge_installations_last_seen ON forge_installations(last_seen);
CREATE INDEX idx_forge_installations_username  ON forge_installations(username);

CREATE TABLE IF NOT EXISTS forge_rig_scores (
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

CREATE INDEX idx_forge_rig_scores_total    ON forge_rig_scores(total_score DESC);
CREATE INDEX idx_forge_rig_scores_cpu      ON forge_rig_scores(cpu_score DESC);
CREATE INDEX idx_forge_rig_scores_gpu      ON forge_rig_scores(gpu_score DESC);
CREATE INDEX idx_forge_rig_scores_username ON forge_rig_scores(username);

CREATE TABLE IF NOT EXISTS forge_achievements (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    username       TEXT NOT NULL,
    achievement_id TEXT NOT NULL,
    unlocked_at    DATETIME NOT NULL,
    synced_at      DATETIME NOT NULL DEFAULT (datetime('now')),
    UNIQUE(username, achievement_id)
);

CREATE INDEX idx_forge_achievements_username ON forge_achievements(username);

CREATE TABLE IF NOT EXISTS forge_cloud_saves (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT NOT NULL,
    machine_id TEXT NOT NULL,
    game       TEXT NOT NULL,
    save_path  TEXT NOT NULL,
    checksum   TEXT NOT NULL,
    size_bytes INTEGER NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_forge_cloud_saves_username ON forge_cloud_saves(username);
CREATE INDEX idx_forge_cloud_saves_game     ON forge_cloud_saves(username, game);

CREATE TABLE IF NOT EXISTS forge_game_compat (
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

CREATE INDEX idx_forge_game_compat_appid ON forge_game_compat(steam_appid);
CREATE INDEX idx_forge_game_compat_game  ON forge_game_compat(game_name);

CREATE TABLE IF NOT EXISTS forge_gallery (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT NOT NULL,
    filename   TEXT NOT NULL,
    game       TEXT,
    caption    TEXT,
    file_path  TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_forge_gallery_username ON forge_gallery(username);
CREATE INDEX idx_forge_gallery_game     ON forge_gallery(game);
CREATE INDEX idx_forge_gallery_created  ON forge_gallery(created_at DESC);

CREATE TABLE IF NOT EXISTS forge_voice_rooms (
    room_name   TEXT PRIMARY KEY,
    created_at  DATETIME NOT NULL DEFAULT (datetime('now')),
    last_active DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_forge_voice_rooms_active ON forge_voice_rooms(last_active);
