/**
 * 24HG Linux Distro - Hub API Router
 *
 * Express router providing endpoints for 24HG OS installations to
 * communicate with the 24HG Hub backend. Handles heartbeats, hardware
 * benchmarks, achievements, cloud saves, game compatibility reports,
 * voice chat tokens, and a community screenshot gallery.
 *
 * Mount at: app.use('/api/24hg', hg24Router)
 *
 * @module 24hg-api
 */

const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const crypto = require('crypto');
const { AccessToken } = require('livekit-server-sdk');

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

const Database = require('better-sqlite3');

const DB_PATH = process.env.HG24_DB_PATH || path.join(__dirname, '..', 'data', '24hg.db');
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY || '';
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET || '';
const LIVEKIT_URL = process.env.LIVEKIT_URL || 'wss://voice.24hgaming.com';

const GALLERY_DIR = process.env.HG24_GALLERY_DIR || path.join(__dirname, '..', 'data', 'gallery');

// ---------------------------------------------------------------------------
// Multer config for gallery uploads
// ---------------------------------------------------------------------------

const upload = multer({
  dest: GALLERY_DIR,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (_req, file, cb) => {
    const allowed = ['image/png', 'image/jpeg', 'image/webp'];
    cb(null, allowed.includes(file.mimetype));
  },
});

// ---------------------------------------------------------------------------
// Middleware: requireAuth
// ---------------------------------------------------------------------------

/**
 * Validate Bearer token against the Hub user system.
 * Expects the Hub's `users` table to have an `api_token` column.
 * Attaches `req.user` with `{ id, username }` on success.
 */
function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  const token = header.slice(7).trim();
  if (!token) {
    return res.status(401).json({ error: 'Empty token' });
  }

  try {
    const user = db.prepare('SELECT id, username FROM users WHERE api_token = ?').get(token);
    if (!user) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  } catch (err) {
    console.error('[24hg-api] Auth error:', err.message);
    return res.status(500).json({ error: 'Authentication check failed' });
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Wrap a route handler so thrown errors become 500 responses.
 * @param {Function} fn - async or sync route handler
 * @returns {Function}
 */
function wrap(fn) {
  return (req, res, next) => {
    try {
      const result = fn(req, res, next);
      if (result && typeof result.catch === 'function') {
        result.catch(next);
      }
    } catch (err) {
      next(err);
    }
  };
}

// ---------------------------------------------------------------------------
// 1. POST /heartbeat — Receive heartbeat from 24HG installations
// ---------------------------------------------------------------------------

/**
 * @route POST /api/24hg/heartbeat
 * @body {string} machine_id - Unique machine identifier
 * @body {string} os_version - 24HG OS version string
 * @body {string} [gpu] - GPU model
 * @body {string} [cpu] - CPU model
 * @body {number} [uptime_hours] - Current uptime in hours
 * @body {string} [username] - Hub username if logged in
 */
router.post('/heartbeat', wrap((req, res) => {
  const { machine_id, os_version, gpu, cpu, uptime_hours, username } = req.body;

  if (!machine_id || !os_version) {
    return res.status(400).json({ error: 'machine_id and os_version are required' });
  }

  const stmt = db.prepare(`
    INSERT INTO hg24_installations (machine_id, os_version, gpu, cpu, username, first_seen, last_seen)
    VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    ON CONFLICT(machine_id) DO UPDATE SET
      os_version = excluded.os_version,
      gpu        = COALESCE(excluded.gpu, hg24_installations.gpu),
      cpu        = COALESCE(excluded.cpu, hg24_installations.cpu),
      username   = COALESCE(excluded.username, hg24_installations.username),
      last_seen  = datetime('now')
  `);

  stmt.run(machine_id, os_version, gpu || null, cpu || null, username || null);

  return res.json({ ok: true });
}));

// ---------------------------------------------------------------------------
// 2. GET /stats — Public stats
// ---------------------------------------------------------------------------

/**
 * @route GET /api/24hg/stats
 * @returns {object} Aggregate 24HG installation statistics
 */
router.get('/stats', wrap((_req, res) => {
  const total = db.prepare('SELECT COUNT(*) AS count FROM hg24_installations').get().count;

  const active = db.prepare(
    "SELECT COUNT(*) AS count FROM hg24_installations WHERE last_seen >= datetime('now', '-24 hours')"
  ).get().count;

  const playtime = db.prepare(
    "SELECT COALESCE(SUM(ROUND((julianday(last_seen) - julianday(first_seen)) * 24, 1)), 0) AS hours FROM hg24_installations"
  ).get().hours;

  const topGpus = db.prepare(
    "SELECT gpu, COUNT(*) AS count FROM hg24_installations WHERE gpu IS NOT NULL GROUP BY gpu ORDER BY count DESC LIMIT 10"
  ).all();

  const topCpus = db.prepare(
    "SELECT cpu, COUNT(*) AS count FROM hg24_installations WHERE cpu IS NOT NULL GROUP BY cpu ORDER BY count DESC LIMIT 10"
  ).all();

  return res.json({ total_installs: total, active_24h: active, total_playtime_hours: playtime, top_gpus: topGpus, top_cpus: topCpus });
}));

// ---------------------------------------------------------------------------
// 3. POST /rig-score — Submit hardware benchmark score
// ---------------------------------------------------------------------------

/**
 * @route POST /api/24hg/rig-score
 * @auth Bearer token required
 * @body {string} machine_id
 * @body {string} username
 * @body {number} cpu_score
 * @body {number} gpu_score
 * @body {number} ram_score
 * @body {number} storage_score
 * @body {number} total_score
 * @body {string} [cpu_model]
 * @body {string} [gpu_model]
 * @body {number} [ram_gb]
 */
router.post('/rig-score', requireAuth, wrap((req, res) => {
  const { machine_id, username, cpu_score, gpu_score, ram_score, storage_score, total_score, cpu_model, gpu_model, ram_gb } = req.body;

  if (!machine_id || !username || total_score == null) {
    return res.status(400).json({ error: 'machine_id, username, and total_score are required' });
  }

  const stmt = db.prepare(`
    INSERT INTO hg24_rig_scores (machine_id, username, cpu_score, gpu_score, ram_score, storage_score, total_score, cpu_model, gpu_model, ram_gb)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const info = stmt.run(
    machine_id, username,
    cpu_score || 0, gpu_score || 0, ram_score || 0, storage_score || 0, total_score,
    cpu_model || null, gpu_model || null, ram_gb || null
  );

  return res.json({ ok: true, id: info.lastInsertRowid });
}));

// ---------------------------------------------------------------------------
// 4. GET /rig-score/leaderboard — Top benchmark scores
// ---------------------------------------------------------------------------

/**
 * @route GET /api/24hg/rig-score/leaderboard
 * @query {number} [limit=50] - Number of results
 * @query {string} [sort=total] - Sort column: total, cpu, or gpu
 */
router.get('/rig-score/leaderboard', wrap((req, res) => {
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 200);
  const sortMap = { total: 'total_score', cpu: 'cpu_score', gpu: 'gpu_score' };
  const sortCol = sortMap[req.query.sort] || 'total_score';

  const rows = db.prepare(`
    SELECT username, cpu_score, gpu_score, ram_score, storage_score, total_score,
           cpu_model, gpu_model, ram_gb, created_at
    FROM hg24_rig_scores
    ORDER BY ${sortCol} DESC
    LIMIT ?
  `).all(limit);

  const ranked = rows.map((row, i) => ({ rank: i + 1, ...row }));

  return res.json({ leaderboard: ranked });
}));

// ---------------------------------------------------------------------------
// 5. POST /voice/token — Get LiveKit room token
// ---------------------------------------------------------------------------

/**
 * @route POST /api/24hg/voice/token
 * @auth Bearer token required
 * @body {string} room - Room name to join
 * @body {string} username - Display name
 * @returns {object} { token, url }
 */
router.post('/voice/token', requireAuth, wrap(async (req, res) => {
  const { room, username } = req.body;

  if (!room || !username) {
    return res.status(400).json({ error: 'room and username are required' });
  }

  if (!LIVEKIT_API_KEY || !LIVEKIT_API_SECRET) {
    return res.status(503).json({ error: 'Voice service not configured' });
  }

  const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
    identity: username,
    name: username,
    ttl: '6h',
  });
  at.addGrant({ roomJoin: true, room, canPublish: true, canSubscribe: true });

  const token = await at.toJwt();

  // Upsert voice room tracking
  db.prepare(`
    INSERT INTO hg24_voice_rooms (room_name, created_at, last_active)
    VALUES (?, datetime('now'), datetime('now'))
    ON CONFLICT(room_name) DO UPDATE SET last_active = datetime('now')
  `).run(room);

  return res.json({ token, url: LIVEKIT_URL });
}));

// ---------------------------------------------------------------------------
// 6. GET /voice/rooms — List active voice rooms
// ---------------------------------------------------------------------------

/**
 * @route GET /api/24hg/voice/rooms
 * @returns {Array} Active rooms with participant counts (rooms active in last 5 min)
 */
router.get('/voice/rooms', wrap((_req, res) => {
  const rooms = db.prepare(`
    SELECT room_name, created_at, last_active
    FROM hg24_voice_rooms
    WHERE last_active >= datetime('now', '-5 minutes')
    ORDER BY last_active DESC
  `).all();

  return res.json({ rooms });
}));

// ---------------------------------------------------------------------------
// 7. POST /achievements — Sync achievement progress
// ---------------------------------------------------------------------------

/**
 * @route POST /api/24hg/achievements
 * @auth Bearer token required
 * @body {string} machine_id
 * @body {string} username
 * @body {Array<{id: string, unlocked_at: string}>} achievements
 */
router.post('/achievements', requireAuth, wrap((req, res) => {
  const { machine_id, username, achievements } = req.body;

  if (!machine_id || !username || !Array.isArray(achievements)) {
    return res.status(400).json({ error: 'machine_id, username, and achievements array are required' });
  }

  const stmt = db.prepare(`
    INSERT INTO hg24_achievements (username, achievement_id, unlocked_at, synced_at)
    VALUES (?, ?, ?, datetime('now'))
    ON CONFLICT(username, achievement_id) DO UPDATE SET
      unlocked_at = excluded.unlocked_at,
      synced_at   = datetime('now')
  `);

  const insertMany = db.transaction((items) => {
    let synced = 0;
    for (const ach of items) {
      if (ach.id && ach.unlocked_at) {
        stmt.run(username, ach.id, ach.unlocked_at);
        synced++;
      }
    }
    return synced;
  });

  const synced = insertMany(achievements);

  return res.json({ ok: true, synced });
}));

// ---------------------------------------------------------------------------
// 8. GET /achievements/:username — Get user achievements
// ---------------------------------------------------------------------------

/**
 * @route GET /api/24hg/achievements/:username
 * @param {string} username
 * @returns {Array} User's unlocked achievements
 */
router.get('/achievements/:username', wrap((req, res) => {
  const { username } = req.params;

  const achievements = db.prepare(
    'SELECT achievement_id, unlocked_at, synced_at FROM hg24_achievements WHERE username = ? ORDER BY unlocked_at DESC'
  ).all(username);

  return res.json({ username, achievements });
}));

// ---------------------------------------------------------------------------
// 9. POST /cloud-saves/sync — Upload save data metadata
// ---------------------------------------------------------------------------

/**
 * @route POST /api/24hg/cloud-saves/sync
 * @auth Bearer token required
 * @body {string} machine_id
 * @body {string} game
 * @body {string} save_path
 * @body {string} checksum
 * @body {number} size_bytes
 */
router.post('/cloud-saves/sync', requireAuth, wrap((req, res) => {
  const { machine_id, game, save_path, checksum, size_bytes } = req.body;

  if (!machine_id || !game || !save_path || !checksum) {
    return res.status(400).json({ error: 'machine_id, game, save_path, and checksum are required' });
  }

  const username = req.user.username;

  // Upsert: same user + game + save_path = update
  const existing = db.prepare(
    'SELECT id FROM hg24_cloud_saves WHERE username = ? AND game = ? AND save_path = ?'
  ).get(username, game, save_path);

  if (existing) {
    db.prepare(
      "UPDATE hg24_cloud_saves SET machine_id = ?, checksum = ?, size_bytes = ?, updated_at = datetime('now') WHERE id = ?"
    ).run(machine_id, checksum, size_bytes || 0, existing.id);
    return res.json({ ok: true, id: existing.id, action: 'updated' });
  }

  const info = db.prepare(
    "INSERT INTO hg24_cloud_saves (username, machine_id, game, save_path, checksum, size_bytes) VALUES (?, ?, ?, ?, ?, ?)"
  ).run(username, machine_id, game, save_path, checksum, size_bytes || 0);

  return res.json({ ok: true, id: info.lastInsertRowid, action: 'created' });
}));

// ---------------------------------------------------------------------------
// 10. GET /cloud-saves/:username — List user's cloud saves
// ---------------------------------------------------------------------------

/**
 * @route GET /api/24hg/cloud-saves/:username
 * @param {string} username
 * @returns {Array} Cloud save entries for the user
 */
router.get('/cloud-saves/:username', wrap((req, res) => {
  const { username } = req.params;

  const saves = db.prepare(
    'SELECT id, machine_id, game, save_path, checksum, size_bytes, updated_at FROM hg24_cloud_saves WHERE username = ? ORDER BY updated_at DESC'
  ).all(username);

  return res.json({ username, saves });
}));

// ---------------------------------------------------------------------------
// 11. POST /game-compat — Submit game compatibility report
// ---------------------------------------------------------------------------

/**
 * @route POST /api/24hg/game-compat
 * @auth Bearer token required
 * @body {string} game_name
 * @body {number} [steam_appid]
 * @body {boolean} works
 * @body {number} [rating] - 1-5
 * @body {string} [gpu]
 * @body {string} [proton_version]
 * @body {string} [notes]
 */
router.post('/game-compat', requireAuth, wrap((req, res) => {
  const { game_name, steam_appid, works, rating, gpu, proton_version, notes } = req.body;

  if (!game_name || works == null) {
    return res.status(400).json({ error: 'game_name and works are required' });
  }

  if (rating != null && (rating < 1 || rating > 5)) {
    return res.status(400).json({ error: 'rating must be between 1 and 5' });
  }

  const username = req.user.username;

  const info = db.prepare(`
    INSERT INTO hg24_game_compat (game_name, steam_appid, works, rating, gpu, proton_version, notes, username)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(game_name, steam_appid || null, works ? 1 : 0, rating || null, gpu || null, proton_version || null, notes || null, username);

  return res.json({ ok: true, id: info.lastInsertRowid });
}));

// ---------------------------------------------------------------------------
// 12. GET /game-compat/:appid — Get compatibility reports for a game
// ---------------------------------------------------------------------------

/**
 * @route GET /api/24hg/game-compat/:appid
 * @param {number} appid - Steam App ID
 * @returns {object} Compatibility reports and summary
 */
router.get('/game-compat/:appid', wrap((req, res) => {
  const appid = parseInt(req.params.appid, 10);
  if (isNaN(appid)) {
    return res.status(400).json({ error: 'Invalid appid' });
  }

  const reports = db.prepare(
    'SELECT id, game_name, works, rating, gpu, proton_version, notes, username, created_at FROM hg24_game_compat WHERE steam_appid = ? ORDER BY created_at DESC'
  ).all(appid);

  // Compute summary
  const total = reports.length;
  const working = reports.filter((r) => r.works).length;
  const avgRating = total > 0
    ? reports.reduce((sum, r) => sum + (r.rating || 0), 0) / reports.filter((r) => r.rating).length || 0
    : 0;

  return res.json({
    steam_appid: appid,
    summary: { total_reports: total, working, broken: total - working, avg_rating: Math.round(avgRating * 10) / 10 },
    reports,
  });
}));

// ---------------------------------------------------------------------------
// 13. GET /vpn/peers — List active VPN peers
// ---------------------------------------------------------------------------

/**
 * @route GET /api/24hg/vpn/peers
 * @auth Bearer token required
 * @returns {Array} Active 24HG installations seen in the last 5 minutes
 */
router.get('/vpn/peers', requireAuth, wrap((_req, res) => {
  const peers = db.prepare(`
    SELECT machine_id, username, os_version, last_seen
    FROM hg24_installations
    WHERE last_seen >= datetime('now', '-5 minutes') AND username IS NOT NULL
    ORDER BY last_seen DESC
  `).all();

  return res.json({ peers });
}));

// ---------------------------------------------------------------------------
// 14. POST /gallery/share — Share screenshot to community gallery
// ---------------------------------------------------------------------------

/**
 * @route POST /api/24hg/gallery/share
 * @auth Bearer token required
 * @consumes multipart/form-data
 * @field {File} image - The screenshot file (PNG, JPEG, or WebP, max 10 MB)
 * @field {string} [game] - Game the screenshot is from
 * @field {string} [caption] - Description
 */
router.post('/gallery/share', requireAuth, upload.single('image'), wrap((req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No image file uploaded or invalid format (PNG/JPEG/WebP only)' });
  }

  const username = req.user.username;
  const { game, caption } = req.body;
  const filename = `${Date.now()}_${crypto.randomBytes(4).toString('hex')}${path.extname(req.file.originalname)}`;

  // Multer already saved the file; rename to our convention
  const destPath = path.join(GALLERY_DIR, filename);
  const fs = require('fs');
  fs.renameSync(req.file.path, destPath);

  const info = db.prepare(
    'INSERT INTO hg24_gallery (username, filename, game, caption, file_path) VALUES (?, ?, ?, ?, ?)'
  ).run(username, filename, game || null, caption || null, destPath);

  return res.json({ ok: true, id: info.lastInsertRowid, filename });
}));

// ---------------------------------------------------------------------------
// 15. GET /gallery — Browse community screenshots
// ---------------------------------------------------------------------------

/**
 * @route GET /api/24hg/gallery
 * @query {number} [page=1]
 * @query {number} [limit=20]
 * @query {string} [game] - Filter by game
 * @returns {object} Paginated gallery entries
 */
router.get('/gallery', wrap((req, res) => {
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 100);
  const offset = (page - 1) * limit;
  const game = req.query.game || null;

  let countSql = 'SELECT COUNT(*) AS count FROM hg24_gallery';
  let selectSql = 'SELECT id, username, filename, game, caption, created_at FROM hg24_gallery';
  const params = [];

  if (game) {
    const whereClause = ' WHERE game = ?';
    countSql += whereClause;
    selectSql += whereClause;
    params.push(game);
  }

  const total = db.prepare(countSql).get(...params).count;

  selectSql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
  const rows = db.prepare(selectSql).all(...params, limit, offset);

  return res.json({
    page,
    limit,
    total,
    total_pages: Math.ceil(total / limit),
    items: rows,
  });
}));

// ---------------------------------------------------------------------------
// Error handler
// ---------------------------------------------------------------------------

router.use((err, _req, res, _next) => {
  console.error('[24hg-api] Error:', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

module.exports = router;
