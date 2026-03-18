import { Database } from "bun:sqlite";
import { readFileSync } from "fs";
import { join } from "path";

const DB_PATH = join(import.meta.dir, "data", "control-room.db");

const db = new Database(DB_PATH, { create: true });
db.exec("PRAGMA journal_mode = WAL");
db.exec("PRAGMA foreign_keys = ON");

// Initialize schema
const schema = readFileSync(join(import.meta.dir, "schema.sql"), "utf-8");
db.exec(schema);

// ── Downloads ──

export function logDownload(ipHash: string, variant: string, userAgent: string, referer: string) {
  db.prepare(
    "INSERT INTO downloads (ip_hash, variant, user_agent, referer) VALUES (?, ?, ?, ?)"
  ).run(ipHash, variant, userAgent, referer);
  logActivity("download", null, `${variant} ISO downloaded`);
}

export function getDownloadStats() {
  const total = db.prepare("SELECT COUNT(*) as count FROM downloads").get() as any;
  const last30 = db.prepare(
    "SELECT COUNT(*) as count FROM downloads WHERE timestamp >= datetime('now', '-30 days')"
  ).get() as any;
  const byVariant = db.prepare(
    "SELECT variant, COUNT(*) as count FROM downloads GROUP BY variant ORDER BY count DESC"
  ).all();
  return { total: total.count, last30: last30.count, byVariant };
}

export function getDownloadsByDay(days: number = 90) {
  return db.prepare(`
    SELECT date(timestamp) as date, variant, COUNT(*) as count
    FROM downloads
    WHERE timestamp >= datetime('now', '-${days} days')
    GROUP BY date(timestamp), variant
    ORDER BY date
  `).all();
}

export function getDownloadHistory(limit: number = 100, offset: number = 0) {
  return db.prepare(
    "SELECT id, timestamp, ip_hash, variant, user_agent, referer FROM downloads ORDER BY timestamp DESC LIMIT ? OFFSET ?"
  ).all(limit, offset);
}

// ── Heartbeats ──

const heartbeatRateLimit = new Map<string, number>();

export function recordHeartbeat(data: {
  machine_id: string;
  version?: string;
  gpu?: string;
  cpu?: string;
  ram_gb?: number;
  display?: string;
}) {
  const now = Date.now();
  const last = heartbeatRateLimit.get(data.machine_id);
  if (last && now - last < 3600_000) return false; // 1hr rate limit
  heartbeatRateLimit.set(data.machine_id, now);

  const existing = db.prepare("SELECT machine_id FROM heartbeats WHERE machine_id = ?").get(data.machine_id);

  if (existing) {
    db.prepare(`
      UPDATE heartbeats SET version = ?, gpu = ?, cpu = ?, ram_gb = ?, display = ?,
        last_seen = datetime('now'), boot_count = boot_count + 1
      WHERE machine_id = ?
    `).run(data.version ?? null, data.gpu ?? null, data.cpu ?? null, data.ram_gb ?? null, data.display ?? null, data.machine_id);
  } else {
    db.prepare(`
      INSERT INTO heartbeats (machine_id, version, gpu, cpu, ram_gb, display)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(data.machine_id, data.version ?? null, data.gpu ?? null, data.cpu ?? null, data.ram_gb ?? null, data.display ?? null);
    logActivity("new_install", null, `New 24HG Forge install: ${data.version || "unknown"}`);
  }
  return true;
}

export function getInstallStats() {
  const total = db.prepare("SELECT COUNT(*) as count FROM heartbeats").get() as any;
  const active30 = db.prepare(
    "SELECT COUNT(*) as count FROM heartbeats WHERE last_seen >= datetime('now', '-30 days')"
  ).get() as any;
  const active7 = db.prepare(
    "SELECT COUNT(*) as count FROM heartbeats WHERE last_seen >= datetime('now', '-7 days')"
  ).get() as any;
  return { total: total.count, active30: active30.count, active7: active7.count };
}

export function getHardwareStats() {
  const gpu = db.prepare(
    "SELECT gpu as label, COUNT(*) as count FROM heartbeats WHERE gpu IS NOT NULL GROUP BY gpu ORDER BY count DESC"
  ).all();
  const cpu = db.prepare(
    "SELECT cpu as label, COUNT(*) as count FROM heartbeats WHERE cpu IS NOT NULL GROUP BY cpu ORDER BY count DESC"
  ).all();
  const ram = db.prepare(
    "SELECT ram_gb as label, COUNT(*) as count FROM heartbeats WHERE ram_gb IS NOT NULL GROUP BY ram_gb ORDER BY count DESC"
  ).all();
  const display = db.prepare(
    "SELECT display as label, COUNT(*) as count FROM heartbeats WHERE display IS NOT NULL GROUP BY display ORDER BY count DESC"
  ).all();
  const version = db.prepare(
    "SELECT version as label, COUNT(*) as count FROM heartbeats WHERE version IS NOT NULL GROUP BY version ORDER BY count DESC"
  ).all();
  return { gpu, cpu, ram, display, version };
}

export function getInstallList(limit: number = 100) {
  return db.prepare(
    "SELECT * FROM heartbeats ORDER BY last_seen DESC LIMIT ?"
  ).all(limit);
}

// ── Roadmap ──

export function getRoadmap() {
  return db.prepare("SELECT * FROM roadmap ORDER BY sort_order ASC, id ASC").all();
}

export function createRoadmapEntry(data: { version: string; title: string; status: string; target_date?: string; sort_order?: number; items: string }) {
  const result = db.prepare(
    "INSERT INTO roadmap (version, title, status, target_date, sort_order, items) VALUES (?, ?, ?, ?, ?, ?)"
  ).run(data.version, data.title, data.status, data.target_date || null, data.sort_order || 0, data.items);
  return result.lastInsertRowid;
}

export function updateRoadmapEntry(id: number, data: { version?: string; title?: string; status?: string; target_date?: string; sort_order?: number; items?: string }) {
  const fields: string[] = [];
  const values: any[] = [];
  for (const [key, val] of Object.entries(data)) {
    if (val !== undefined) {
      fields.push(`${key} = ?`);
      values.push(val);
    }
  }
  if (fields.length === 0) return;
  values.push(id);
  db.prepare(`UPDATE roadmap SET ${fields.join(", ")} WHERE id = ?`).run(...values);
}

export function deleteRoadmapEntry(id: number) {
  db.prepare("DELETE FROM roadmap WHERE id = ?").run(id);
}

// ── Activity Log ──

export function logActivity(type: string, actor: string | null, detail: string) {
  db.prepare(
    "INSERT INTO activity_log (type, actor, detail) VALUES (?, ?, ?)"
  ).run(type, actor, detail);
}

export function getActivity(limit: number = 100) {
  return db.prepare(
    "SELECT * FROM activity_log ORDER BY timestamp DESC LIMIT ?"
  ).all(limit);
}

// ── Announcements ──

export function getAnnouncements(activeOnly: boolean = false) {
  if (activeOnly) {
    return db.prepare("SELECT * FROM announcements WHERE active = 1 ORDER BY timestamp DESC").all();
  }
  return db.prepare("SELECT * FROM announcements ORDER BY timestamp DESC").all();
}

export function createAnnouncement(data: { title: string; message: string; type?: string; author?: string }) {
  const result = db.prepare(
    "INSERT INTO announcements (title, message, type, author) VALUES (?, ?, ?, ?)"
  ).run(data.title, data.message, data.type || "info", data.author || null);
  return result.lastInsertRowid;
}

export function updateAnnouncement(id: number, data: { title?: string; message?: string; type?: string; active?: number }) {
  const fields: string[] = [];
  const values: any[] = [];
  for (const [key, val] of Object.entries(data)) {
    if (val !== undefined) { fields.push(`${key} = ?`); values.push(val); }
  }
  if (fields.length === 0) return;
  values.push(id);
  db.prepare(`UPDATE announcements SET ${fields.join(", ")} WHERE id = ?`).run(...values);
}

export function deleteAnnouncement(id: number) {
  db.prepare("DELETE FROM announcements WHERE id = ?").run(id);
}

// ── Page Views ──

export function logPageView(path: string, referer: string, ipHash: string) {
  db.prepare("INSERT INTO page_views (path, referer, ip_hash) VALUES (?, ?, ?)").run(path, referer, ipHash);
}

export function getPageViewStats(days: number = 30) {
  const byPage = db.prepare(`
    SELECT path, COUNT(*) as count FROM page_views
    WHERE timestamp >= datetime('now', '-${days} days')
    GROUP BY path ORDER BY count DESC
  `).all();
  const byDay = db.prepare(`
    SELECT date(timestamp) as date, COUNT(*) as count FROM page_views
    WHERE timestamp >= datetime('now', '-${days} days')
    GROUP BY date(timestamp) ORDER BY date
  `).all();
  const byReferer = db.prepare(`
    SELECT referer, COUNT(*) as count FROM page_views
    WHERE timestamp >= datetime('now', '-${days} days') AND referer != ''
    GROUP BY referer ORDER BY count DESC LIMIT 20
  `).all();
  const total = db.prepare(`
    SELECT COUNT(*) as count FROM page_views
    WHERE timestamp >= datetime('now', '-${days} days')
  `).get() as any;
  return { byPage, byDay, byReferer, total: total.count };
}

// ── Download Referer Breakdown ──

export function getDownloadReferers(days: number = 90) {
  return db.prepare(`
    SELECT referer, COUNT(*) as count FROM downloads
    WHERE timestamp >= datetime('now', '-${days} days') AND referer != ''
    GROUP BY referer ORDER BY count DESC LIMIT 20
  `).all();
}

// ── Roadmap seed from HTML ──

export function seedRoadmapFromParsed(entries: Array<{ version: string; title: string; status: string; target_date: string; items: Array<{ text: string; done: boolean }> }>) {
  const existing = db.prepare("SELECT COUNT(*) as count FROM roadmap").get() as any;
  if (existing.count > 0) return false;

  const insert = db.prepare(
    "INSERT INTO roadmap (version, title, status, target_date, sort_order, items) VALUES (?, ?, ?, ?, ?, ?)"
  );
  const tx = db.transaction(() => {
    entries.forEach((entry, i) => {
      insert.run(entry.version, entry.title, entry.status, entry.target_date, i, JSON.stringify(entry.items));
    });
  });
  tx();
  return true;
}

export default db;
