# Contributing to 24HG

Thank you for your interest in contributing to 24HG. This guide covers everything you need to know to get started.

## Ways to Contribute

- **Report bugs** -- Found something broken? Open an issue.
- **Suggest features** -- Have an idea? Open a discussion or issue.
- **Write code** -- Fix bugs, add tools, improve existing tools.
- **Improve documentation** -- Fix typos, add examples, write guides.
- **Test** -- Try 24HG on different hardware and report results.
- **Help others** -- Answer questions in Discord or on GitHub issues.

## Getting Started

### 1. Set Up Your Development Environment

```bash
# Clone the repository
git clone https://git.raggi.is/24hg/24hg.git
cd 24hg

# Install build dependencies
sudo dnf install podman git shellcheck python3-pylint  # Fedora
sudo apt install podman git shellcheck pylint            # Ubuntu/Debian
```

### 2. Understand the Codebase

Read the [Building from Source](Building) page for the full project structure. Key directories:

- `scripts/` -- All 53 `24hg-*` tools live here. Most are bash or Python scripts.
- `hub-app/` -- The Hub application and tray icon.
- `system_files/` -- System configuration files deployed to the image.
- `branding/` -- Visual assets (wallpapers, icons, themes).
- `installer/` -- Calamares installer configuration.

### 3. Pick Something to Work On

Check the Gitea Issues for items tagged `good first issue` or `help wanted`. Or pick something from the roadmap.

## Adding a New Tool

24HG tools follow a consistent pattern. Here is how to add a new one:

### 1. Create the Script

Create your tool in `scripts/`:

```bash
#!/bin/bash
# 24HG Tool Name — One-line description of what it does
# Usage: 24hg-tool-name [command] [options]
#
# Commands:
#   status     Show current status
#   configure  Set up configuration
#   help       Show this help

set -euo pipefail

ACTION="${1:-help}"

case "$ACTION" in
    status)
        echo "Tool status: OK"
        ;;
    configure)
        echo "Configuring..."
        ;;
    help|*)
        echo "Usage: 24hg-tool-name [status|configure|help]"
        echo ""
        echo "24HG Tool Name — One-line description"
        echo ""
        echo "Commands:"
        echo "  status      Show current status"
        echo "  configure   Set up configuration"
        ;;
esac
```

For Python tools, use the same pattern as `24hg-smart-launch` or `24hg-games`:

```python
#!/usr/bin/env python3
"""24HG Tool Name — One-line description

Commands:
    status     Show current status
    configure  Set up configuration
"""

import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="24HG Tool Name")
    sub = parser.add_subparsers(dest="command")
    sub.add_parser("status", help="Show current status")
    sub.add_parser("configure", help="Set up configuration")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(0)

    # Handle commands...

if __name__ == "__main__":
    main()
```

### 2. Add to the Containerfile

Add two lines to the Containerfile:

```dockerfile
# In the COPY section (near the top)
COPY scripts/24hg-tool-name /tmp/24hg-build/bin/24hg-tool-name

# In the RUN section (CLI tools area)
&& install -m 755 /tmp/24hg-build/bin/24hg-tool-name /usr/bin/24hg-tool-name \
```

### 3. Add a Systemd Service (If Needed)

If your tool runs as a background daemon or on a timer:

1. Create the service file in `system_files/etc/systemd/user/`:

```ini
[Unit]
Description=24HG Tool Name

[Service]
Type=simple
ExecStart=/usr/bin/24hg-tool-name daemon

[Install]
WantedBy=default.target
```

2. Add COPY and enable lines to the Containerfile.

### 4. Update Documentation

- Add your tool to the [Tools Reference](Tools-Reference) wiki page.
- Add it to the appropriate category.
- Include usage examples.

### 5. Test

```bash
# Test the script locally
chmod +x scripts/24hg-tool-name
./scripts/24hg-tool-name help
./scripts/24hg-tool-name status

# Build the image and verify
./scripts/build-local.sh desktop

# Test in a VM
./build-iso.sh
```

## Coding Style Guide

### Bash Scripts

- Use `#!/bin/bash` shebang (not `#!/bin/sh`).
- Always `set -euo pipefail` at the top.
- Use `${VARIABLE}` syntax for variable expansion in strings.
- Quote variables: `"$var"` not `$var`.
- Use `[[ ]]` for conditionals, not `[ ]`.
- Use `$(command)` for command substitution, not backticks.
- Add a comment header with tool name, description, and usage.
- Use functions for reusable logic.
- Color output is encouraged (use ANSI codes) but must support `--no-color` or `NO_COLOR` env var.
- Exit codes: 0 for success, 1 for general error, 2 for usage error.

Run shellcheck before submitting:

```bash
shellcheck scripts/24hg-tool-name
```

### Python Scripts

- Use `#!/usr/bin/env python3` shebang.
- Target Python 3.9+ (what ships with Fedora).
- Use only standard library modules (no pip dependencies -- the OS image cannot run pip).
- Use argparse for argument parsing.
- Use type hints where practical.
- Include a module docstring with tool description and commands.
- Use the color helper pattern from existing tools (see `24hg-games` for reference).

Run pylint before submitting:

```bash
pylint scripts/24hg-tool-name
```

### General

- Tool names are always `24hg-<name>` (lowercase, hyphens).
- Config files go in `~/.config/24hg/<tool>/`.
- Data files go in `~/.local/share/24hg/<tool>/`.
- Cache files go in `~/.cache/24hg/<tool>/`.
- Log files go in `~/.local/share/24hg/logs/`.
- Use zenity for GUI dialogs (check for `DISPLAY`/`WAYLAND_DISPLAY` and zenity availability).
- Notifications use `notify-send` with the `24hg` icon category.
- Tools must work offline (gracefully degrade if network is unavailable).

## Testing

### Local Testing

Test your changes before building the full image:

```bash
# Run the tool directly
./scripts/24hg-tool-name status

# Run shellcheck on all bash tools
for f in scripts/24hg-*; do
    [[ "$(head -1 "$f")" == *bash* ]] && shellcheck "$f"
done

# Run pylint on all Python tools
for f in scripts/24hg-*; do
    [[ "$(head -1 "$f")" == *python* ]] && pylint "$f"
done
```

### Image Testing

```bash
# Build the image
./scripts/build-local.sh desktop

# Build the ISO
./build-iso.sh

# Test in a VM (QEMU)
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \
  -cdrom iso-output/24hg-desktop-latest.iso \
  -drive file=test.qcow2,format=qcow2 -boot d
```

## Submitting Pull Requests

### 1. Fork and Branch

```bash
# Fork on GitHub, then:
git clone https://github.com/YOUR_USERNAME/24hg-os.git
cd 24hg
git checkout -b feature/my-new-tool
```

### 2. Make Your Changes

Follow the coding style guide above. Keep commits focused and atomic.

### 3. Write a Good Commit Message

```
Add 24hg-my-tool for <purpose>

- Implements <feature> using <approach>
- Configures <what> for <why>
- Adds systemd timer for background operation
```

### 4. Open the PR

Push to your fork and open a pull request on GitHub. Include:

- **What** the change does
- **Why** it is needed
- **How** to test it
- **Screenshots** if it has visual output

### 5. Code Review

A maintainer will review your PR. Common feedback:

- Missing error handling
- Hardcoded paths (use variables)
- Missing `set -euo pipefail`
- Tools that require pip/npm packages (not allowed -- standard library only)
- Missing documentation

## Community Guidelines

- **Be respectful.** Treat everyone with kindness.
- **Be constructive.** When reporting issues or reviewing code, offer suggestions, not just criticism.
- **Be patient.** Maintainers are volunteers. PRs may take a few days to review.
- **Ask questions.** If you are not sure about something, ask in Discord or open a discussion.
- **Test your changes.** Do not submit untested code.
- **Keep scope small.** Large PRs are hard to review. Break big features into smaller PRs.

## License

By contributing to 24HG, you agree that your contributions will be licensed under the MIT License (matching the project license).

## Contact

- **Discord:** [discord.gg/ymfEjH6EJN](https://discord.gg/ymfEjH6EJN)
- **Gitea Issues:** [git.raggi.is/24hg/24hg/issues](https://git.raggi.is/24hg/24hg/issues)
- **Hub:** [hub.24hgaming.com](https://hub.24hgaming.com)
