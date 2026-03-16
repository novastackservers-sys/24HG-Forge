/**
 * 24HG Hub — Electron Desktop App
 *
 * Features:
 * - Loads hub.24hgaming.com with native window chrome
 * - System tray with quick-connect to game servers
 * - Protocol handler: 24hg://connect/<game>/<server>
 * - Native notifications for chat, tournaments, events
 * - Game launch integration (Steam, Lutris protocol URIs)
 * - Gamescope-aware: goes kiosk mode when in 24HG Mode session
 * - Overlay mode: mini floating window for in-game use
 */

const {
  app,
  BrowserWindow,
  Tray,
  Menu,
  nativeImage,
  shell,
  ipcMain,
  Notification,
  screen,
  session,
} = require("electron");
const path = require("path");
const { exec } = require("child_process");

// ─── Constants ───
const HUB_URL = "https://hub.24hgaming.com";
const PROTOCOL = "24hg";
const IS_GAMESCOPE =
  !!process.env.GAMESCOPE_WAYLAND_DISPLAY ||
  process.env.XDG_CURRENT_DESKTOP === "gamescope";

let mainWindow = null;
let overlayWindow = null;
let tray = null;

// ─── Single Instance Lock ───
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
} else {
  app.on("second-instance", (_event, argv) => {
    // Handle protocol URL from second instance
    const url = argv.find((arg) => arg.startsWith(`${PROTOCOL}://`));
    if (url) handleProtocol(url);
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });
}

// ─── Protocol Handler ───
app.setAsDefaultProtocolClient(PROTOCOL);

// 24hg://connect/rust → steam://connect/91.99.37.118:27021
// 24hg://connect/cs2/competitive → steam://connect/91.99.37.118:27015
// 24hg://hub/servers → navigate to servers page
// 24hg://hub/chat → navigate to chat
const SERVER_MAP = {
  rust: { ip: "91.99.37.118:27021", appId: "252490", protocol: "steam" },
  cs2: { ip: "91.99.37.118:27015", appId: "730", protocol: "steam" },
  "tf2-2fort": { ip: "91.99.37.118:27025", appId: "440", protocol: "steam" },
  "tf2-dustbowl": {
    ip: "91.99.37.118:27026",
    appId: "440",
    protocol: "steam",
  },
  "cs16-dust2": {
    ip: "91.99.37.118:27030",
    appId: "10",
    protocol: "steam",
  },
};

function handleProtocol(url) {
  try {
    const parsed = new URL(url);
    const pathParts = parsed.pathname.replace(/^\/+/, "").split("/");

    if (parsed.host === "connect" || pathParts[0] === "connect") {
      const serverKey = pathParts[1] || parsed.host;
      const server = SERVER_MAP[serverKey];
      if (server) {
        const connectUrl = `steam://connect/${server.ip}`;
        shell.openExternal(connectUrl);
        showNotification(
          "Connecting...",
          `Launching ${serverKey.toUpperCase()} server`
        );
      }
    } else if (parsed.host === "hub") {
      const page = pathParts[0] || "servers";
      if (mainWindow) {
        mainWindow.loadURL(`${HUB_URL}/${page}`);
        mainWindow.show();
        mainWindow.focus();
      }
    }
  } catch (e) {
    console.error("Protocol handler error:", e);
  }
}

// ─── Notifications ───
function showNotification(title, body) {
  if (Notification.isSupported()) {
    new Notification({ title, body, icon: getIconPath() }).show();
  }
}

function getIconPath() {
  return path.join(__dirname, "assets", "icons", "256x256.png");
}

// ─── Main Window ───
function createMainWindow() {
  const { width, height } = screen.getPrimaryDisplay().workAreaSize;

  const windowOpts = {
    width: IS_GAMESCOPE ? width : Math.min(1600, width),
    height: IS_GAMESCOPE ? height : Math.min(900, height),
    minWidth: 800,
    minHeight: 600,
    icon: getIconPath(),
    title: "24HG Hub",
    backgroundColor: "#0a0a14",
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      webviewTag: false,
    },
  };

  // Gamescope mode: fullscreen, no frame
  if (IS_GAMESCOPE) {
    windowOpts.fullscreen = true;
    windowOpts.frame = false;
    windowOpts.kiosk = true;
  } else {
    windowOpts.frame = true;
    windowOpts.titleBarStyle = "hidden";
    windowOpts.titleBarOverlay = {
      color: "#0a0a14",
      symbolColor: "#a0a0c0",
      height: 36,
    };
  }

  mainWindow = new BrowserWindow(windowOpts);

  // Custom user agent to identify HubOS app
  const defaultUA = mainWindow.webContents.getUserAgent();
  mainWindow.webContents.setUserAgent(`${defaultUA} HubOS/1.0`);

  // Load hub
  mainWindow.loadURL(HUB_URL);

  // Handle external links — open in system browser
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (
      url.startsWith("steam://") ||
      url.startsWith("lutris://") ||
      url.startsWith("heroic://")
    ) {
      shell.openExternal(url);
      return { action: "deny" };
    }
    if (!url.startsWith(HUB_URL)) {
      shell.openExternal(url);
      return { action: "deny" };
    }
    return { action: "allow" };
  });

  // Inject custom CSS for HubOS branding
  mainWindow.webContents.on("did-finish-load", () => {
    mainWindow.webContents.insertCSS(`
      :root {
        --hubos-accent: #58a6ff;
        --hubos-bg: #0a0a14;
      }
      /* Custom scrollbar */
      ::-webkit-scrollbar { width: 8px; }
      ::-webkit-scrollbar-track { background: #0a0a14; }
      ::-webkit-scrollbar-thumb { background: #2a2a3e; border-radius: 4px; }
      ::-webkit-scrollbar-thumb:hover { background: #3a3a4e; }
    `);
  });

  // Minimize to tray instead of closing
  mainWindow.on("close", (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  return mainWindow;
}

// ─── Overlay Window (mini floating panel for in-game) ───
function createOverlayWindow() {
  if (overlayWindow) {
    overlayWindow.show();
    overlayWindow.focus();
    return;
  }

  const { width, height } = screen.getPrimaryDisplay().workAreaSize;

  overlayWindow = new BrowserWindow({
    width: 400,
    height: 600,
    x: width - 420,
    y: 20,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: true,
    icon: getIconPath(),
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  overlayWindow.loadURL(`${HUB_URL}/overlay`);
  overlayWindow.setVisibleOnAllWorkspaces(true, {
    visibleOnFullScreen: true,
  });

  overlayWindow.webContents.on("did-finish-load", () => {
    overlayWindow.webContents.insertCSS(`
      body { background: rgba(10, 10, 20, 0.85) !important; border-radius: 12px; }
      ::-webkit-scrollbar { width: 4px; }
      ::-webkit-scrollbar-thumb { background: #58a6ff40; border-radius: 2px; }
    `);
  });

  overlayWindow.on("closed", () => {
    overlayWindow = null;
  });
}

// ─── System Tray ───
function createTray() {
  const icon = nativeImage.createFromPath(
    path.join(__dirname, "assets", "icons", "32x32.png")
  );
  tray = new Tray(icon);
  tray.setToolTip("24HG Hub");

  const contextMenu = Menu.buildFromTemplate([
    {
      label: "Open Hub",
      click: () => {
        mainWindow.show();
        mainWindow.focus();
      },
    },
    {
      label: "Overlay Mode",
      click: () => createOverlayWindow(),
    },
    { type: "separator" },
    {
      label: "Quick Connect",
      submenu: [
        {
          label: "Rust — No Man's Land",
          click: () => shell.openExternal("steam://connect/91.99.37.118:27021"),
        },
        {
          label: "CS2 — Competitive",
          click: () => shell.openExternal("steam://connect/91.99.37.118:27015"),
        },
        {
          label: "TF2 — 2Fort",
          click: () => shell.openExternal("steam://connect/91.99.37.118:27025"),
        },
        {
          label: "TF2 — Dustbowl",
          click: () => shell.openExternal("steam://connect/91.99.37.118:27026"),
        },
        {
          label: "CS 1.6 — Dust2",
          click: () => shell.openExternal("steam://connect/91.99.37.118:27030"),
        },
        { type: "separator" },
        {
          label: "Browse All Servers...",
          click: () => {
            mainWindow.loadURL(`${HUB_URL}/servers`);
            mainWindow.show();
          },
        },
      ],
    },
    { type: "separator" },
    {
      label: "Settings",
      click: () => {
        mainWindow.loadURL(`${HUB_URL}/settings`);
        mainWindow.show();
      },
    },
    {
      label: "Discord",
      click: () => shell.openExternal("https://discord.gg/ymfEjH6EJN"),
    },
    { type: "separator" },
    {
      label: "Quit",
      click: () => {
        app.isQuitting = true;
        app.quit();
      },
    },
  ]);

  tray.setContextMenu(contextMenu);
  tray.on("click", () => {
    if (mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      mainWindow.show();
      mainWindow.focus();
    }
  });
}

// ─── IPC Handlers ───
ipcMain.handle("get-server-list", () => SERVER_MAP);
ipcMain.handle("connect-server", (_event, serverKey) => {
  handleProtocol(`${PROTOCOL}://connect/${serverKey}`);
});
ipcMain.handle("toggle-overlay", () => {
  if (overlayWindow) {
    overlayWindow.close();
  } else {
    createOverlayWindow();
  }
});
ipcMain.handle("is-gamescope", () => IS_GAMESCOPE);
ipcMain.handle("get-system-info", () => {
  return {
    platform: process.platform,
    arch: process.arch,
    isGamescope: IS_GAMESCOPE,
    electronVersion: process.versions.electron,
    chromeVersion: process.versions.chrome,
  };
});

// ─── App Lifecycle ───
app.whenReady().then(() => {
  // Handle protocol URL on launch (Linux)
  const protocolUrl = process.argv.find((arg) =>
    arg.startsWith(`${PROTOCOL}://`)
  );

  createMainWindow();

  if (!IS_GAMESCOPE) {
    createTray();
  }

  if (protocolUrl) {
    handleProtocol(protocolUrl);
  }

  // Permission handler — allow notifications, media, etc
  session.defaultSession.setPermissionRequestHandler(
    (_webContents, permission, callback) => {
      const allowed = [
        "notifications",
        "media",
        "mediaKeySystem",
        "fullscreen",
        "clipboard-read",
        "clipboard-sanitized-write",
      ];
      callback(allowed.includes(permission));
    }
  );
});

app.on("window-all-closed", () => {
  // Don't quit on window close — tray keeps it alive
  if (IS_GAMESCOPE) {
    app.quit();
  }
});

app.on("activate", () => {
  if (!mainWindow) createMainWindow();
});

app.on("open-url", (_event, url) => {
  handleProtocol(url);
});
