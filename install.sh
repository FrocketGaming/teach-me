#!/usr/bin/env bash
# Installs (or resyncs) this repo into Claude Code's global skills/agents
# directories. Safe to re-run any time after pulling/editing this repo - it
# will pick up the change without you copying anything by hand (when a real
# link could be established - see the verification note below).
#
# Usage: ./install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILL_DEST="$CLAUDE_DIR/skills/teach-me"
AGENT_DEST="$CLAUDE_DIR/agents/diagram-maker.md"

mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"

is_windows() {
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) [ -n "${WINDIR:-}" ] && return 0 ;;
  esac
  return 1
}

# Passing an mklink command as LIVE cmd.exe arguments from bash is not
# reliable: MSYS's argument translation for native (non-MSYS) executables can
# mangle absolute Windows paths on the way over - tested during development,
# it turned `C:\Users\...\teach-me` into something cmd.exe read as a switch
# ("Invalid switch"). Writing the exact command into a real temporary .bat
# file and running that avoids the live-argument translation entirely.
# $1: mklink flag ("/J" for a directory junction, "" for a file symlink)
# $2: link path to create   $3: existing target it should point to
# All paths - INCLUDING THE .bat FILE'S OWN PATH - must be converted to real
# Windows form (backslashes, drive letter) with `cygpath -w` before use here.
# Tested during development: bash's own $PWD-derived paths are POSIX-style
# (`/c/Users/...`) under Git Bash, and cmd.exe - a native, non-MSYS process -
# silently failed to even find/run a .bat file passed at a POSIX-style path,
# no error, nothing created. Do not skip this conversion for any of the three
# paths below, including ones that "look like" they're already fine.
windows_mklink() {
  local flag="$1"
  local link target bat_posix bat_win
  link="$(cygpath -w "$2")"
  target="$(cygpath -w "$3")"
  # bash writes to / removes the .bat via its POSIX-style path; only the
  # argument handed to cmd.exe needs the converted Windows-style one.
  bat_posix="$(mktemp -u "${REPO_DIR}/.install-tmp-XXXXXX.bat")"
  bat_win="$(cygpath -w "$bat_posix")"
  {
    printf '@echo off\r\n'
    if [ -n "$flag" ]; then
      printf 'mklink %s "%s" "%s"\r\n' "$flag" "$link" "$target"
    else
      printf 'mklink "%s" "%s"\r\n' "$link" "$target"
    fi
  } > "$bat_posix"
  cmd //c "$bat_win" >/dev/null 2>&1 || true
  rm -f "$bat_posix"
}

# Neither `ln -s`'s exit code NOR "does a known file show up at the
# destination" is trustworthy proof of a real link: tested on Windows/Git-Bash,
# `ln -s` on a directory reported success (exit 0) while actually performing a
# ONE-TIME SILENT COPY - SKILL.md was present at the destination, so an
# existence check alone would have called it a live link when it very much
# was not. The only real proof is round-tripping a unique sentinel file
# through the SOURCE dir and confirming it shows up (then disappears) at the
# DESTINATION - a copy can't do either, since the sentinel didn't exist yet
# when the copy happened.
verify_live_dir_link() {
  local src="$1" dest="$2"
  local sentinel=".install-link-check-$$-$RANDOM"
  : > "$src/$sentinel"
  local ok=1
  [ -f "$dest/$sentinel" ] && ok=0
  rm -f "$src/$sentinel" "$dest/$sentinel" 2>/dev/null || true
  return $ok
}

# Same idea for a single file: append a unique marker to the source, check it
# shows up at the destination, then revert the source to its exact original
# content either way.
verify_live_file_link() {
  local src="$1" dest="$2"
  local marker="<!-- install-link-check-$$-$RANDOM -->"
  printf '%s\n' "$marker" >> "$src"
  local ok=1
  grep -qF "$marker" "$dest" 2>/dev/null && ok=0
  sed -i "\#$(printf '%s' "$marker" | sed 's/[.[\*^$/]/\\&/g')#d" "$src"
  return $ok
}

# --- the skill directory (SKILL.md + assets/) ---
# Prefer a real symlink (works out of the box on macOS/Linux, and on Windows
# with Developer Mode or an elevated shell): editing this repo then instantly
# updates what Claude Code reads, with nothing to resync. If that's not
# available, fall back to a Windows directory junction (works without admin
# rights, still live-synced, just Windows-only), then finally a plain copy
# (works everywhere, but you must re-run this script after editing the repo).
if [ -e "$SKILL_DEST" ] || [ -L "$SKILL_DEST" ]; then
  rm -rf "$SKILL_DEST"
fi

ln -s "$REPO_DIR" "$SKILL_DEST" 2>/dev/null || true
if [ -d "$SKILL_DEST" ] && verify_live_dir_link "$REPO_DIR" "$SKILL_DEST"; then
  echo "skill: symlinked (verified live) -> $SKILL_DEST"
else
  rm -rf "$SKILL_DEST"
  if is_windows; then
    windows_mklink "/J" "$SKILL_DEST" "$REPO_DIR"
  fi
  if [ -d "$SKILL_DEST" ] && verify_live_dir_link "$REPO_DIR" "$SKILL_DEST"; then
    echo "skill: junctioned (Windows, verified live) -> $SKILL_DEST"
  else
    rm -rf "$SKILL_DEST"
    cp -r "$REPO_DIR" "$SKILL_DEST"
    rm -rf "$SKILL_DEST/.git" "$SKILL_DEST/assets/visualize/node_modules"
    echo "skill: copied (not live-linked) -> $SKILL_DEST — re-run ./install.sh after editing this repo to resync"
  fi
fi

# --- the diagram-maker agent (a single file among unrelated ones in the same
# directory, so the whole agents/ dir can't be linked) ---
AGENT_SRC="$REPO_DIR/agents/diagram-maker.md"
rm -f "$AGENT_DEST"

ln -s "$AGENT_SRC" "$AGENT_DEST" 2>/dev/null || true
if [ -f "$AGENT_DEST" ] && verify_live_file_link "$AGENT_SRC" "$AGENT_DEST"; then
  echo "agent: symlinked (verified live) -> $AGENT_DEST"
else
  rm -f "$AGENT_DEST"
  if is_windows; then
    windows_mklink "" "$AGENT_DEST" "$AGENT_SRC"
  fi
  if [ -f "$AGENT_DEST" ] && verify_live_file_link "$AGENT_SRC" "$AGENT_DEST"; then
    echo "agent: symlinked (Windows, verified live) -> $AGENT_DEST"
  else
    rm -f "$AGENT_DEST"
    cp "$AGENT_SRC" "$AGENT_DEST"
    echo "agent: copied (not live-linked) -> $AGENT_DEST — re-run ./install.sh after editing agents/diagram-maker.md to resync"
  fi
fi

# --- native dependency for the diagram-maker subagent's renderer ---
# Not committed to the repo (it bundles a Chromium build, ~250MB) - fetched
# here instead. Safe to re-run; npm no-ops if already installed.
echo "installing diagram renderer dependencies (downloads a bundled Chromium, ~250MB, one time)..."
( cd "$REPO_DIR/assets/visualize" && npm install --no-fund --no-audit )

echo
echo "Done. Restart Claude Code (or start a new session) and /teach-me will be available."
