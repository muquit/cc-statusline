#!/bin/bash
########################################################################
# statusline-command.sh - Claude Code status line
#
# Shows: 5-hour session and 7-day weekly usage with time until each resets
# (colored dot follows whichever is higher), context window use,
# model, working directory, git branch, and other live Claude Code sessions.
#
#   ● Session: 34% (2h 47m) Week: 41% (3d 5h) Context: 12% [Opus 5.5] obidos (main) +2 (1 here)
#
# Requires: bash, jq. git is optional (branch is skipped without it).
#
# Environment (optional):
#   STATUSLINE_DIR_STYLE      base (default) = last path component
#                             full           = full path, $HOME shown as ~
#   STATUSLINE_SESSIONS_DIR   where live sessions register themselves
#                             (default: ~/.claude/live-sessions)
########################################################################

input=$(cat)

# ---- parse input (single jq call) ------------------------------------------
SEP=$'\x1f'
IFS="$SEP" read -r MODEL USAGE RESETS_AT WEEK WEEK_RESETS_AT CTX SESSION_ID DIR < <(
  jq -r '[
    (.model.display_name // "?"),
    ((.rate_limits.five_hour.used_percentage // "") | tostring),
    ((.rate_limits.five_hour.resets_at // "") | tostring),
    ((.rate_limits.seven_day.used_percentage // "") | tostring),
    ((.rate_limits.seven_day.resets_at // "") | tostring),
    ((.context_window.used_percentage // 0) | tostring),
    (.session_id // ""),
    (.workspace.current_dir // .cwd // "")
  ] | join("\u001f")' <<<"$input"
)

CTX=${CTX%%.*}
[ -z "$DIR" ] && DIR=$PWD

# ---- session (5h) and week (7d) usage ---------------------------------------
# Time left until an epoch timestamp: "3d 5h" when a day or more, else "2h 47m".
until_str() {
  local at=${1%%.*} diff
  if [ -z "$at" ]; then
    echo "--"
    return
  fi
  diff=$(( at - $(date +%s) ))
  [ "$diff" -lt 0 ] && diff=0
  if [ "$diff" -ge 86400 ]; then
    echo "$((diff/86400))d $(((diff%86400)/3600))h"
  else
    echo "$((diff/3600))h $(((diff%3600)/60))m"
  fi
}

USAGE_INT=$(printf '%.0f' "${USAGE:-0}" 2>/dev/null) || USAGE_INT=0
RESET_STR=$(until_str "$RESETS_AT")

WEEK_DISP=""
WEEK_INT=0
if [ -n "$WEEK" ]; then
  WEEK_INT=$(printf '%.0f' "$WEEK" 2>/dev/null) || WEEK_INT=0
  WEEK_DISP=" Week: ${WEEK_INT}% ($(until_str "$WEEK_RESETS_AT"))"
fi

# The dot follows whichever limit is closer to its cap.
MAX_INT=$USAGE_INT
[ "$WEEK_INT" -gt "$MAX_INT" ] && MAX_INT=$WEEK_INT

# ---- colors -----------------------------------------------------------------
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

if [ "$MAX_INT" -ge 80 ]; then
  COLOR="$RED"
elif [ "$MAX_INT" -ge 50 ]; then
  COLOR="$YELLOW"
else
  COLOR="$GREEN"
fi
DOT="${COLOR}●${RESET}"

# ---- directory --------------------------------------------------------------
case "${STATUSLINE_DIR_STYLE:-base}" in
  full)
    if [ "$DIR" = "$HOME" ] || [ "${DIR#"$HOME"/}" != "$DIR" ]; then
      DIR_DISP="~${DIR#"$HOME"}"
    else
      DIR_DISP=$DIR
    fi
    ;;
  *)
    DIR_DISP=${DIR##*/}
    [ -z "$DIR_DISP" ] && DIR_DISP=/
    ;;
esac

# ---- git branch -------------------------------------------------------------
# Branch name, or short commit hash when detached. Empty outside a repo.
BRANCH=$(git -C "$DIR" symbolic-ref --short -q HEAD 2>/dev/null) ||
  BRANCH=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
BR_DISP=""
[ -n "$BRANCH" ] && BR_DISP=" ($BRANCH)"

# Sessions count as "here" when they share a repo (or the same dir if no repo).
REPO_KEY=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_KEY" ] && REPO_KEY=$DIR

# ---- live session registry --------------------------------------------------
# Claude Code may run this script through a shell, so walk up the process
# tree past any shells to find the long-lived Claude Code process.
find_cc_pid() {
  local pid=$PPID comm i
  for i in 1 2 3 4 5 6; do
    { [ -z "$pid" ] || [ "$pid" -le 1 ]; } && return
    comm=$(ps -o comm= -p "$pid" 2>/dev/null)
    comm=${comm##*/}
    comm=${comm#-}
    case "$comm" in
      sh|bash|zsh|dash|ksh|fish|env|timeout|"")
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        ;;
      *)
        echo "$pid"
        return
        ;;
    esac
  done
}

REG_DIR="${STATUSLINE_SESSIONS_DIR:-$HOME/.claude/live-sessions}"
CC_PID=$(find_cc_pid)
OTHERS=0
HERE=0

if mkdir -p "$REG_DIR" 2>/dev/null; then
  # Register (or refresh) this session. Write to a temp file, then rename,
  # so other sessions never read a half-written file.
  if [ -n "$SESSION_ID" ] && [ -n "$CC_PID" ]; then
    tmp="$REG_DIR/.$SESSION_ID.$$"
    printf '%s\n%s\n%s\n' "$CC_PID" "$REPO_KEY" "$DIR" >"$tmp" &&
      mv -f "$tmp" "$REG_DIR/$SESSION_ID"
  fi

  for f in "$REG_DIR"/*; do
    [ -f "$f" ] || continue
    [ "${f##*/}" = "$SESSION_ID" ] && continue
    pid="" key=""
    { read -r pid; read -r key; } <"$f" 2>/dev/null
    # Same process under an old session id (e.g. after /clear): stale.
    if [ -n "$CC_PID" ] && [ "$pid" = "$CC_PID" ]; then
      rm -f "$f"
      continue
    fi
    # Process gone: stale.
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$f"
      continue
    fi
    OTHERS=$((OTHERS + 1))
    [ "$key" = "$REPO_KEY" ] && HERE=$((HERE + 1))
  done
fi

SESS=""
if [ "$OTHERS" -gt 0 ]; then
  SESS=" +$OTHERS"
  [ "$HERE" -gt 0 ] && SESS="$SESS ${YELLOW}(${HERE} here)${RESET}"
fi

# ---- output -----------------------------------------------------------------
# Colors go through %b; data goes through %s so paths and names are printed
# literally (a backslash in a directory name will not be interpreted).
printf '%b Session: %s%% (%s)%s Context: %s%% [%s] %b%s%b%s%b\n' \
  "$DOT" "$USAGE_INT" "$RESET_STR" "$WEEK_DISP" "$CTX" "$MODEL" \
  "$CYAN" "$DIR_DISP" "$RESET" "$BR_DISP" "$SESS"
