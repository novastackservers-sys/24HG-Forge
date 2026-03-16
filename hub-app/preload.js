/**
 * 24HG Hub — Preload Script
 * Exposes a safe bridge between the web hub and native Electron features
 */

const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("hubos", {
  // System info
  isDesktopApp: true,
  isGamescope: () => ipcRenderer.invoke("is-gamescope"),
  getSystemInfo: () => ipcRenderer.invoke("get-system-info"),

  // Game server integration
  getServers: () => ipcRenderer.invoke("get-server-list"),
  connectServer: (key) => ipcRenderer.invoke("connect-server", key),

  // Overlay
  toggleOverlay: () => ipcRenderer.invoke("toggle-overlay"),

  // Notifications (native OS notifications)
  notify: (title, body) => {
    new Notification(title, { body });
  },

  // Platform detection for the web app to adapt its UI
  platform: {
    os: process.platform,
    arch: process.arch,
    isHubOS: true,
    version: "1.0.0",
  },
});
