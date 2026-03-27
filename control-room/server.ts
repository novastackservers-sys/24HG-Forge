import { Hono } from "hono";
import { cors } from "hono/cors";
import { createHash } from "crypto";
import { statSync, readdirSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { execSync } from "child_process";

import {
  logDownload, getDownloadStats, getDownloadsByDay, getDownloadHistory,
  recordHeartbeat, getInstallStats, getHardwareStats, getInstallList,
  getRoadmap, createRoadmapEntry, updateRoadmapEntry, deleteRoadmapEntry,
  logActivity, getActivity, seedRoadmapFromParsed,
  getAnnouncements, createAnnouncement, updateAnnouncement, deleteAnnouncement,
  logPageView, getPageViewStats, getDownloadReferers,
} from "./db";
import { authMiddleware, verifyAuth, type AuthUser } from "./auth";

const app = new Hono();

app.use("/*", cors({
  origin: ["https://os.24hgaming.com", "http://localhost:3847"],
  credentials: true,
}));

const PORT = parseInt(process.env.PORT || "3847");
const ISO_DIR = process.env.ISO_DIR || "/srv/landing-page/iso";
const LANDING_DIR = process.env.LANDING_DIR || "/srv/landing-page";
const GITEA_URL = process.env.GITEA_URL || "https://git.raggi.is";
const GITEA_TOKEN = process.env.GITEA_TOKEN || "";
const GITEA_REPO = process.env.GITEA_REPO || "24hg/24hg-os";

// ── Helpers ──

function hashIP(ip: string): string {
  return createHash("sha256").update(ip + "24hg-salt-2026").digest("hex").slice(0, 16);
}

function getClientIP(c: any): string {
  return c.req.header("x-forwarded-for")?.split(",")[0]?.trim()
    || c.req.header("x-real-ip")
    || "unknown";
}

// ── Public: Download Tracking ──

app.get("/api/download/:variant", (c) => {
  const variant = c.req.param("variant");
  const validVariants: Record<string, string> = {
    desktop: "24hg-desktop-latest.iso",
    nvidia: "24hg-nvidia-latest.iso",
  };

  const filename = validVariants[variant];
  if (!filename) return c.json({ error: "Invalid variant" }, 400);

  const ip = getClientIP(c);
  const ipHash = hashIP(ip);
  const ua = c.req.header("user-agent") || "";
  const referer = c.req.header("referer") || "";

  logDownload(ipHash, variant, ua, referer);

  return c.redirect(`/iso/${filename}`, 302);
});

// ── Public: Heartbeat ──

app.post("/api/heartbeat", async (c) => {
  try {
    const body = await c.req.json();
    if (!body.machine_id || typeof body.machine_id !== "string") {
      return c.json({ error: "machine_id required" }, 400);
    }

    const accepted = recordHeartbeat({
      machine_id: body.machine_id,
      version: body.version,
      gpu: body.gpu,
      cpu: body.cpu,
      ram_gb: body.ram_gb,
      display: body.display,
    });

    return c.json({ ok: true, accepted });
  } catch {
    return c.json({ error: "Invalid JSON" }, 400);
  }
});

// ── Auth: Verify ──

app.post("/api/auth/verify", async (c) => {
  const authHeader = c.req.header("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return c.json({ error: "No token" }, 401);
  }
  const user = await verifyAuth(authHeader.slice(7));
  if (!user) return c.json({ error: "Invalid token" }, 401);
  return c.json({ user });
});

// ── Authenticated: Stats ──

app.get("/api/stats", authMiddleware(), (c) => {
  const downloads = getDownloadStats();
  const installs = getInstallStats();
  const dailyDownloads = getDownloadsByDay(90);
  const hardware = getHardwareStats();

  return c.json({
    downloads,
    installs,
    dailyDownloads,
    versionBreakdown: hardware.version,
  });
});

app.get("/api/stats/hardware", authMiddleware(), (c) => {
  return c.json(getHardwareStats());
});

app.get("/api/stats/downloads", authMiddleware(), (c) => {
  const days = parseInt(c.req.query("days") || "90");
  return c.json({
    daily: getDownloadsByDay(days),
    history: getDownloadHistory(200),
  });
});

// ── Authenticated: Health ──

app.get("/api/health", authMiddleware(), (c) => {
  let diskFree = "unknown";
  let diskTotal = "unknown";
  let diskUsedPct = "unknown";
  try {
    const df = execSync("df -h / | tail -1").toString().trim().split(/\s+/);
    diskTotal = df[1];
    diskFree = df[3];
    diskUsedPct = df[4];
  } catch {}

  let isoFiles: Array<{ name: string; size: string; modified: string }> = [];
  try {
    const files = readdirSync(ISO_DIR).filter((f) => f.endsWith(".iso"));
    isoFiles = files.map((f) => {
      const stat = statSync(join(ISO_DIR, f));
      return {
        name: f,
        size: (stat.size / (1024 * 1024 * 1024)).toFixed(2) + " GB",
        modified: stat.mtime.toISOString(),
      };
    });
  } catch {}

  let uptime = "unknown";
  try {
    uptime = execSync("uptime -p").toString().trim();
  } catch {}

  return c.json({
    disk: { total: diskTotal, free: diskFree, usedPct: diskUsedPct },
    isoFiles,
    uptime,
    serverTime: new Date().toISOString(),
  });
});

// ── Authenticated: Activity ──

app.get("/api/activity", authMiddleware(), (c) => {
  const limit = parseInt(c.req.query("limit") || "100");
  return c.json(getActivity(limit));
});

// ── Public: Page View Tracking ──

app.post("/api/pageview", async (c) => {
  try {
    const body = await c.req.json();
    const ip = getClientIP(c);
    const ipHash = hashIP(ip);
    logPageView(body.path || "/", body.referer || "", ipHash);
    return c.json({ ok: true });
  } catch {
    return c.json({ ok: false }, 400);
  }
});

// ── Public: Active Announcements ──

app.get("/api/announcements", (c) => {
  return c.json(getAnnouncements(true));
});

// ── Authenticated: Page View Stats ──

app.get("/api/stats/pageviews", authMiddleware(), (c) => {
  const days = parseInt(c.req.query("days") || "30");
  return c.json(getPageViewStats(days));
});

app.get("/api/stats/referers", authMiddleware(), (c) => {
  const days = parseInt(c.req.query("days") || "90");
  return c.json({ downloads: getDownloadReferers(days) });
});

// ── Admin Only: Announcements ──

app.get("/api/admin/announcements", authMiddleware(true), (c) => {
  return c.json(getAnnouncements(false));
});

app.post("/api/admin/announcements", authMiddleware(true), async (c) => {
  const user = c.get("user") as AuthUser;
  const body = await c.req.json();
  if (!body.title || !body.message) return c.json({ error: "title and message required" }, 400);
  const id = createAnnouncement({ title: body.title, message: body.message, type: body.type, author: user.username });
  logActivity("announcement_create", user.username, `Created announcement: ${body.title}`);
  return c.json({ id }, 201);
});

app.put("/api/admin/announcements/:id", authMiddleware(true), async (c) => {
  const user = c.get("user") as AuthUser;
  const id = parseInt(c.req.param("id"));
  const body = await c.req.json();
  updateAnnouncement(id, body);
  logActivity("announcement_update", user.username, `Updated announcement #${id}`);
  return c.json({ ok: true });
});

app.delete("/api/admin/announcements/:id", authMiddleware(true), async (c) => {
  const user = c.get("user") as AuthUser;
  const id = parseInt(c.req.param("id"));
  deleteAnnouncement(id);
  logActivity("announcement_delete", user.username, `Deleted announcement #${id}`);
  return c.json({ ok: true });
});

// ── Admin Only: Roadmap ──

app.get("/api/roadmap", authMiddleware(), (c) => {
  return c.json(getRoadmap());
});

app.post("/api/roadmap", authMiddleware(true), async (c) => {
  const user = c.get("user") as AuthUser;
  const body = await c.req.json();
  if (!body.version || !body.title || !body.status) {
    return c.json({ error: "version, title, status required" }, 400);
  }
  const id = createRoadmapEntry({
    version: body.version,
    title: body.title,
    status: body.status,
    target_date: body.target_date,
    sort_order: body.sort_order,
    items: body.items || "[]",
  });
  logActivity("roadmap_create", user.username, `Created roadmap: ${body.version} — ${body.title}`);
  return c.json({ id }, 201);
});

app.put("/api/roadmap/:id", authMiddleware(true), async (c) => {
  const user = c.get("user") as AuthUser;
  const id = parseInt(c.req.param("id"));
  const body = await c.req.json();
  updateRoadmapEntry(id, body);
  logActivity("roadmap_update", user.username, `Updated roadmap entry #${id}`);
  return c.json({ ok: true });
});

app.delete("/api/roadmap/:id", authMiddleware(true), async (c) => {
  const user = c.get("user") as AuthUser;
  const id = parseInt(c.req.param("id"));
  deleteRoadmapEntry(id);
  logActivity("roadmap_delete", user.username, `Deleted roadmap entry #${id}`);
  return c.json({ ok: true });
});

app.post("/api/roadmap/publish", authMiddleware(true), async (c) => {
  const user = c.get("user") as AuthUser;
  try {
    const entries = getRoadmap() as Array<any>;
    const html = generateRoadmapHTML(entries);
    const roadmapPath = join(LANDING_DIR, "roadmap.html");
    writeFileSync(roadmapPath, html);
    logActivity("roadmap_publish", user.username, "Published roadmap to website");
    return c.json({ ok: true });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// ── Admin Only: Build Trigger ──

app.post("/api/build/trigger", authMiddleware(true), async (c) => {
  const user = c.get("user") as AuthUser;
  const body = await c.req.json().catch(() => ({}));
  const variant = (body as any).variant || "desktop";

  if (!GITEA_TOKEN) {
    return c.json({ error: "Gitea token not configured" }, 500);
  }

  try {
    const res = await fetch(`${GITEA_URL}/api/v1/repos/${GITEA_REPO}/actions/dispatches`, {
      method: "POST",
      headers: {
        Authorization: `token ${GITEA_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ref: "main",
        inputs: { variant },
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      return c.json({ error: `Gitea API error: ${res.status} ${text}` }, 502);
    }

    logActivity("build_trigger", user.username, `Triggered ${variant} ISO build`);
    return c.json({ ok: true, variant });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

app.get("/api/build/status", authMiddleware(), async (c) => {
  if (!GITEA_TOKEN) {
    return c.json({ configured: false, runs: [] });
  }

  try {
    const res = await fetch(`${GITEA_URL}/api/v1/repos/${GITEA_REPO}/actions/runs?limit=10`, {
      headers: { Authorization: `token ${GITEA_TOKEN}` },
    });

    if (!res.ok) {
      return c.json({ configured: true, runs: [], error: "Failed to fetch" });
    }

    const data = await res.json();
    return c.json({ configured: true, runs: (data.workflow_runs || []).slice(0, 10) });
  } catch {
    return c.json({ configured: true, runs: [], error: "Connection failed" });
  }
});

// ── Roadmap HTML Generator ──

function generateRoadmapHTML(entries: Array<any>): string {
  const statusBadge: Record<string, { cls: string; label: string }> = {
    done: { cls: "done", label: "SHIPPED" },
    planned: { cls: "planned", label: "PLANNED" },
    next: { cls: "planned", label: "NEXT" },
    vision: { cls: "vision", label: "VISION" },
  };

  let currentVersion = "v1.9";
  const doneEntries = entries.filter((e) => e.status === "done");
  if (doneEntries.length > 0) {
    currentVersion = doneEntries[doneEntries.length - 1].version;
  }

  const sections = entries.map((entry) => {
    const items = JSON.parse(entry.items || "[]");
    const badge = statusBadge[entry.status] || statusBadge.planned;

    const itemsHTML = items.map((item: { text: string; done: boolean }) => {
      if (item.done) {
        return `            <div class="roadmap-item done"><span class="check">&#10003;</span> ${escapeHTML(item.text)}</div>`;
      }
      return `            <div class="roadmap-item"><span class="dot"></span> ${escapeHTML(item.text)}</div>`;
    }).join("\n");

    return `    <div class="roadmap-section">
        <div class="roadmap-header ${entry.status === 'done' ? 'done' : entry.status}">
            <span class="roadmap-badge ${badge.cls}">${badge.label}</span>
            <h2>${escapeHTML(entry.version)} — ${escapeHTML(entry.title)}</h2>
            <span class="roadmap-date">${escapeHTML(entry.target_date || "")}</span>
        </div>
        <div class="roadmap-items">
${itemsHTML}
        </div>
    </div>`;
  }).join("\n\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>24HG Roadmap — What's Coming Next</title>
    <meta name="description" content="24HG development roadmap. See what features are coming to the ultimate Linux gaming OS.">
    <meta property="og:image" content="https://os.24hgaming.com/og-image.png">
    <link rel="icon" href="favicon.ico" type="image/x-icon">
    <link rel="stylesheet" href="style.css">
    <script async src="https://analytics.24hgaming.com/track" data-website-id="a052da7e-3afe-40b1-9354-071901dd26e4"></script>
</head>
<body>

<nav class="nav">
    <a href="index.html" class="nav-logo">24HG</a>
    <div class="nav-links">
        <a href="download.html">Download</a>
        <a href="features.html">Features</a>
        <a href="install.html">Install</a>
        <a href="compatibility.html">Compatibility</a>
        <a href="roadmap.html" class="active">Roadmap</a>
        <a href="faq.html">FAQ</a>
        <a href="https://hub.24hgaming.com" class="btn-nav">Open Hub</a>
    </div>
</nav>

<main class="page">
    <h1>Roadmap</h1>
    <p class="subtitle">Where 24HG is going. Built in public, driven by the community.</p>

    <div class="roadmap-current">
        <h2>Current Release: ${escapeHTML(currentVersion)}</h2>
        <p>150+ tools · 89 servers · 20 development waves · Built on Bazzite (Fedora Atomic)</p>
        <a href="download.html" class="btn btn-primary">Download 24HG ${escapeHTML(currentVersion)}</a>
    </div>

${sections}

    <div class="roadmap-cta">
        <h2>Help shape 24HG</h2>
        <p>Have ideas? Found bugs? Want to contribute?</p>
        <div class="cta-group">
            <a href="https://discord.gg/ymfEjH6EJN" class="btn btn-primary">Join Discord</a>
            <a href="https://hub.24hgaming.com" class="btn btn-secondary">Visit the Hub</a>
        </div>
    </div>
</main>

<footer>
    <div class="footer-grid">
        <div class="footer-col">
            <h4>24HG</h4>
            <a href="download.html">Download</a>
            <a href="install.html">Install Guide</a>
            <a href="roadmap.html">Roadmap</a>
            <a href="faq.html">FAQ</a>
        </div>
        <div class="footer-col">
            <h4>Community</h4>
            <a href="https://hub.24hgaming.com">24HG Hub</a>
            <a href="https://discord.gg/ymfEjH6EJN">Discord</a>
            <a href="https://24hgaming.com">24hgaming.com</a>
        </div>
        <div class="footer-col">
            <h4>Built on</h4>
            <a href="https://bazzite.gg">Bazzite</a>
            <a href="https://universal-blue.org">Universal Blue</a>
            <a href="https://fedoraproject.org">Fedora</a>
        </div>
    </div>
    <div class="footer-bottom">
        <p>Made by <a href="https://24hgaming.com">24 Hour Gaming</a> &middot; MIT License</p>
    </div>
</footer>

<script>fetch("/api/pageview",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({path:location.pathname,referer:document.referrer})}).catch(()=>{})</script>

</body>
</html>`;
}

function escapeHTML(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

// ── Authenticated: Install List ──

app.get("/api/installs", authMiddleware(), (c) => {
  const limit = parseInt(c.req.query("limit") || "100");
  return c.json(getInstallList(limit));
});

// ── VPN Proxy Endpoints (forward to VPN API) ──

const VPN_API = process.env.VPN_API_URL || "http://10.0.0.1:3860";

async function vpnFetch(path: string, opts: RequestInit = {}) {
  return fetch(`${VPN_API}${path}`, {
    ...opts,
    headers: { "Content-Type": "application/json", ...opts.headers },
  });
}

app.get("/api/vpn/health", async (c) => {
  try {
    const res = await vpnFetch("/api/vpn/health");
    return c.json(await res.json(), res.status as any);
  } catch { return c.json({ error: "VPN API unreachable" }, 502); }
});

app.get("/api/vpn/status", authMiddleware(true), async (c) => {
  try {
    const user = c.get("user" as any) as AuthUser;
    const res = await vpnFetch("/api/vpn/status", {
      headers: { Authorization: `Bearer ${c.req.header("Authorization")?.split(" ")[1] || ""}` },
    });
    return c.json(await res.json(), res.status as any);
  } catch { return c.json({ error: "VPN API unreachable" }, 502); }
});

app.post("/api/vpn/add", authMiddleware(true), async (c) => {
  try {
    const { username } = await c.req.json();
    // Admin-initiated peer creation — generate keys and add
    const res = await vpnFetch("/api/vpn/admin/add", {
      method: "POST",
      headers: { Authorization: `Bearer ${c.req.header("Authorization")?.split(" ")[1] || ""}` },
      body: JSON.stringify({ username }),
    });
    const data = await res.json();
    if (res.ok) logActivity("vpn_add", `Added VPN peer: ${username} → ${data.assigned_ip}`);
    return c.json(data, res.status as any);
  } catch { return c.json({ error: "VPN API unreachable" }, 502); }
});

app.post("/api/vpn/remove", authMiddleware(true), async (c) => {
  try {
    const { username } = await c.req.json();
    const res = await vpnFetch("/api/vpn/admin/remove", {
      method: "POST",
      headers: { Authorization: `Bearer ${c.req.header("Authorization")?.split(" ")[1] || ""}` },
      body: JSON.stringify({ username }),
    });
    const data = await res.json();
    if (res.ok) logActivity("vpn_remove", `Removed VPN peer: ${username}`);
    return c.json(data, res.status as any);
  } catch { return c.json({ error: "VPN API unreachable" }, 502); }
});

// ── Admin Static Files ──

const ADMIN_DIR = join(import.meta.dir);

const MIME_TYPES: Record<string, string> = {
  ".html": "text/html",
  ".css": "text/css",
  ".js": "application/javascript",
  ".json": "application/json",
  ".png": "image/png",
  ".ico": "image/x-icon",
};

app.get("/admin/admin.css", (c) => {
  try {
    const content = readFileSync(join(ADMIN_DIR, "admin.css"), "utf-8");
    return c.text(content, 200, { "Content-Type": "text/css" });
  } catch {
    return c.text("Not found", 404);
  }
});

app.get("/admin*", (c) => {
  try {
    const content = readFileSync(join(ADMIN_DIR, "admin.html"), "utf-8");
    return c.html(content);
  } catch {
    return c.text("Not found", 404);
  }
});

// ── Seed Roadmap ──

app.post("/api/roadmap/seed", authMiddleware(true), async (c) => {
  const roadmapData = [
    { version: "v1.0", title: "Foundation", status: "done", target_date: "March 2026", items: [
      { text: "Bazzite base with 24HG branding (Plymouth, GRUB, SDDM, KDE theme)", done: true },
      { text: "Chromium hub kiosk with 24hg:// protocol handler", done: true },
      { text: "Auto-install Steam, Lutris, Heroic, Discord, OBS on first boot", done: true },
      { text: "65 game servers pre-configured in Steam favorites", done: true },
      { text: "Per-game optimized configs (CS2, TF2, CS 1.6, Rust)", done: true },
      { text: "MangoHud performance overlay pre-configured", done: true },
      { text: "GameMode with CPU/GPU/scheduler optimization", done: true },
      { text: "Gamescope session (console mode) + KDE desktop mode", done: true },
      { text: "First-boot setup wizard with GPU detection", done: true },
      { text: "Atomic auto-updates (gaming session aware)", done: true },
      { text: "Diagnostics tool + system info (24hg-diag, 24hg-neofetch)", done: true },
      { text: "Live bootable ISO — try before installing", done: true },
      { text: "OBS streaming pre-configured with 24HG scenes", done: true },
    ]},
    { version: "v1.1", title: "Performance & Integration", status: "done", target_date: "March 2026", items: [
      { text: "TCP BBR congestion control + kernel gaming params", done: true },
      { text: "Centralized servers.json powering tray, Steam, and shell", done: true },
      { text: "System tray with live player counts (A2S protocol queries)", done: true },
      { text: "Network Latency Guard — traffic shaping, gaming DNS, service pausing", done: true },
      { text: "Proton Troubleshooter — diagnose and fix game launch failures", done: true },
      { text: "Instant Replay — ShadowPlay equivalent with gpu-screen-recorder", done: true },
      { text: "Input Latency Optimizer — flat mouse accel, fast keyboard", done: true },
      { text: "Audio Optimizer — low-latency PipeWire, noise cancellation", done: true },
      { text: "Auto GameMode hooks — everything activates when you launch a game", done: true },
      { text: "Offline fallback page with server IPs for direct connect", done: true },
    ]},
    { version: "v1.2", title: "Quality of Life", status: "done", target_date: "March 2026", items: [
      { text: "Discord Rich Presence Flatpak bridge (auto-fix)", done: true },
      { text: "Proton-GE auto-install on first boot", done: true },
      { text: "Screenshot tool with clipboard + notifications", done: true },
      { text: "Game save backup system (auto-weekly + manual)", done: true },
      { text: "Night light / blue light filter with keyboard shortcut", done: true },
      { text: "Gaming benchmark suite with readiness check", done: true },
      { text: "Custom keyboard shortcuts (Print=screenshot, F9=replay, Meta+N=nightlight)", done: true },
      { text: "PipeWire gaming defaults out of the box", done: true },
      { text: "libinput gaming mouse quirks", done: true },
    ]},
    { version: "v1.3", title: "Hub Integration", status: "done", target_date: "March 2026", items: [
      { text: "Hub Bridge daemon — desktop notifications for DMs, mentions, friends", done: true },
      { text: "System tray shows hub status, unread counts, online friends", done: true },
      { text: "Hub login from first-boot wizard and system tray", done: true },
    ]},
    { version: "v1.4", title: "Advanced Gaming Tools", status: "done", target_date: "March 2026", items: [
      { text: "Per-game profiles — custom Proton, resolution, env vars per game", done: true },
      { text: "Controller manager — detect, calibrate, remap, profile switching", done: true },
      { text: "Auto Proton-GE updater — daily checks, auto-install, cleanup old versions", done: true },
      { text: "Playtime tracker — cross-launcher stats synced to Hub profile", done: true },
      { text: "One-click streaming — Twitch/YouTube/Kick with GPU encoding", done: true },
      { text: "Shader cache manager — optimize, clean, export/import caches", done: true },
    ]},
    { version: "v1.5", title: "User Experience Polish", status: "done", target_date: "March 2026", items: [
      { text: "Custom sound theme — login chime, notification dings, game launch fanfare", done: true },
      { text: "Animated KDE splash screen with 24HG branding", done: true },
      { text: "Desktop widget — live CPU/GPU/RAM stats + server status + Hub info", done: true },
      { text: "50+ rotating gaming tips in terminal and desktop notifications", done: true },
      { text: "Achievement system — 30+ unlockable OS-level achievements with points", done: true },
      { text: "Time-based wallpaper rotation (morning/afternoon/evening/night)", done: true },
      { text: "Gaming notification style — compact, non-intrusive, auto-DND in fullscreen", done: true },
    ]},
    { version: "v1.6", title: "Troubleshooting & Compatibility", status: "done", target_date: "March 2026", items: [
      { text: "Game compatibility checker — ProtonDB + anti-cheat DB + Steam library scan", done: true },
      { text: "Crash auto-diagnosis — detect OOM, GPU hang, missing libs, prefix corruption", done: true },
      { text: "Multi-monitor display manager — refresh rates, VRR, HDR, profiles", done: true },
      { text: "Discord Wayland screen share fix — xwaylandvideobridge + audio routing", done: true },
      { text: "Wine/Proton prefix manager — health check, deps, backup, cleanup", done: true },
      { text: "Dual-boot helper — quick reboot to Windows, GRUB fix, shared games, clock sync", done: true },
    ]},
    { version: "v1.7", title: "Adoption & Onboarding", status: "done", target_date: "March 2026", items: [
      { text: "Windows migration assistant — import game configs, keybinds, sensitivity from Windows", done: true },
      { text: "Benchmark comparison tool — FPS vs Windows with shareable result cards", done: true },
      { text: "24HG Perks — 30-day VIP trial, [24HG] badge, referral system, activity rewards", done: true },
      { text: "Game compatibility page — honest anti-cheat status for 50+ popular games", done: true },
      { text: "Content creator kit — OBS scenes, overlays, intros, clip tools, all 24HG branded", done: true },
      { text: "Polished live demo mode — guided 5-minute tour from bootable USB", done: true },
    ]},
    { version: "v1.8", title: "Intelligent Gaming", status: "done", target_date: "March 2026", items: [
      { text: "Smart Game Launch — auto-detect game, apply optimal Proton/MangoHud/performance per game", done: true },
      { text: "Session Summary — FPS stats, temps, playtime after every gaming session", done: true },
      { text: "Post-Crash Recovery — auto-restore resolution, audio, compositor after game crashes", done: true },
      { text: "Download Scheduler — auto-pause downloads during gaming, bandwidth prioritization", done: true },
      { text: "Unified Game Library — all games from Steam, Heroic, Lutris, native in one place", done: true },
      { text: "Thermal Guard — live temp monitoring, throttle warnings, fan control", done: true },
    ]},
    { version: "v1.9", title: "Community-Requested Fixes", status: "done", target_date: "March 2026", items: [
      { text: "Anti-cheat status tracker — 186-game database, daily checks, notify on Linux support changes", done: true },
      { text: "Mod manager bridge — Vortex/MO2 installer, prefix path mapping, Nexus nxm:// handler", done: true },
      { text: "HDR gaming wizard — monitor detection, KDE/gamescope config, per-game HDR profiles", done: true },
      { text: "Flatpak gaming permission fixer — auto-fix sandbox issues for 8 gaming apps", done: true },
      { text: "Update Guard — snapshot gaming stack, benchmark after updates, one-click rollback", done: true },
      { text: "Universal save game manager — find saves across all prefixes, backup/restore, cloud sync", done: true },
      { text: "NVIDIA Wayland auto-fix — tearing, flickering, shader cache, VRR, explicit sync", done: true },
    ]},
    { version: "v2.0", title: "Native Hub App", status: "next", target_date: "Q2 2026", items: [
      { text: "Replace Chromium kiosk with native Tauri desktop app", done: false },
      { text: "In-game overlay (server info, clan chat, voice controls)", done: false },
      { text: "Push-to-talk keybind for LiveKit voice chat", done: false },
      { text: "Clip auto-upload to hub gallery", done: false },
      { text: "NVIDIA ISO variant with proprietary drivers", done: false },
      { text: "Steam Deck / HTPC ISO variant", done: false },
      { text: "ISO downloads from os.24hgaming.com", done: false },
    ]},
    { version: "v2.1", title: "Community Features", status: "planned", target_date: "Q3 2026", items: [
      { text: "Tournament notifications — desktop alerts when tournaments start", done: false },
      { text: "Cloud save sync via 24HG account (already in 24hg-save-manager)", done: false },
      { text: "Download scheduler with community-set gaming hours", done: false },
      { text: "KDE Plasma widget — live server status on desktop (already built as Conky)", done: false },
      { text: "Plasma native widget rewrite (replace Conky)", done: false },
      { text: "Voice chat overlay (LiveKit integration)", done: false },
    ]},
    { version: "v3.0", title: "The Complete Gaming Platform", status: "vision", target_date: "2027", items: [
      { text: "AI-powered game optimization (auto-detect and configure per game)", done: false },
      { text: "P2P game server hosting (community members host servers via 24HG)", done: false },
      { text: "Game streaming from your 24HG PC to mobile/TV", done: false },
      { text: "24HG Companion mobile app (server status, clan chat, remote control)", done: false },
      { text: "Hardware compatibility database (community-verified)", done: false },
      { text: "Automatic anti-cheat compatibility layer", done: false },
      { text: "VR gaming support and setup wizard", done: false },
      { text: "Wayland game capture without performance loss", done: false },
    ]},
  ];

  const seeded = seedRoadmapFromParsed(roadmapData);
  if (seeded) {
    logActivity("roadmap_seed", (c.get("user") as AuthUser).username, "Seeded roadmap from existing data");
    return c.json({ ok: true, count: roadmapData.length });
  }
  return c.json({ ok: false, message: "Roadmap already has data" });
});

// ── Start ──

console.log(`24HG Control Room API running on port ${PORT}`);
export default {
  port: PORT,
  fetch: app.fetch,
};
