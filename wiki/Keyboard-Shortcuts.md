# Keyboard Shortcuts

24HG ships with pre-configured keyboard shortcuts for gaming, screenshots, recording, and system control. These are set during installation and work out of the box.

## 24HG Custom Shortcuts

These are unique to 24HG and are configured in `~/.config/kglobalshortcutsrc.d/24hg.conf`:

| Shortcut | Action | Tool |
|----------|--------|------|
| `Print` | Full-screen screenshot | `24hg-screenshot full` |
| `Shift+Print` | Select area screenshot | `24hg-screenshot area` |
| `Meta+Print` | Active window screenshot | `24hg-screenshot window` |
| `F9` | Save instant replay clip | `24hg-replay save` |
| `Meta+N` | Toggle night light | `24hg-nightlight toggle` |

## KDE Plasma Defaults

These come from KDE Plasma and are available on any KDE system, but are listed here for reference:

| Shortcut | Action |
|----------|--------|
| `Meta` | Open application launcher |
| `Meta+L` | Lock screen |
| `Meta+E` | Open file manager (Dolphin) |
| `Meta+T` | Open terminal (Konsole) |
| `Alt+Tab` | Switch windows |
| `Alt+F4` | Close window |
| `Meta+D` | Show desktop |
| `Ctrl+Alt+Del` | Log out dialog |
| `Meta+Tab` | Switch activities |
| `Meta+Up` | Maximize window |
| `Meta+Down` | Restore / minimize window |
| `Meta+Left` | Tile window to left half |
| `Meta+Right` | Tile window to right half |
| `Ctrl+Alt+T` | Open terminal (alternative) |

## Gaming Overlays

These shortcuts control gaming overlays and are configured through the respective tools:

| Shortcut | Action | Notes |
|----------|--------|-------|
| `F12` | Toggle MangoHud | FPS counter, frame times, GPU/CPU stats. Configured in `~/.config/MangoHud/MangoHud.conf` |
| `Shift+F12` | Cycle MangoHud display levels | Minimal → Standard → Full → Hidden |
| `F11` | Toggle fullscreen | Standard across most applications |

## OBS Studio Shortcuts

If you use `24hg-stream` with OBS Studio, these are the default scene/recording shortcuts:

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+R` | Start/stop recording |
| `Ctrl+Shift+S` | Start/stop streaming |
| `Ctrl+Shift+P` | Pause recording |

## GameMode

GameMode does not have keyboard shortcuts -- it activates automatically when a game launches (via `24hg-smart-launch` daemon) and deactivates when the game closes. You can check its status:

```bash
gamemoded -s     # Check if GameMode is active
```

## Customizing Shortcuts

### Via KDE System Settings

1. Open **System Settings** (right-click desktop, or `Meta` then search).
2. Go to **Keyboard** -> **Shortcuts**.
3. Find 24HG shortcuts under **Custom Shortcuts**.
4. Click any shortcut to rebind it.

### Via Config File

Edit `~/.config/kglobalshortcutsrc.d/24hg.conf` directly:

```ini
[24hg-replay-save]
Comment=Save Instant Replay Clip
Exec=/usr/bin/24hg-replay save
Name=Save Replay
Shortcut=F9
```

Change the `Shortcut=` line to your preferred key combo, then log out and back in (or run `kquitapp6 kglobalaccel && kglobalaccel6`).

## Tips

- **Screenshot location:** Screenshots are saved to `~/Pictures/24HG Screenshots/` by default.
- **Replay clips:** Replay clips are saved to `~/Videos/24HG Clips/`.
- **MangoHud config:** Edit `~/.config/MangoHud/MangoHud.conf` to customize what the overlay shows.
- **Night light:** The night light reduces blue light in the evening. Toggle it anytime with `Meta+N`.
