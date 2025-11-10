#!/usr/bin/env bash
set -euo pipefail

# ----- CONFIG -----
BASE_URL="https://kt-sharelatex2.ijs.si"
EMAIL="your.email@ijs.si"
PASSWORD="YourLatexPassword"
PROJECT="ProjectIDCopiedFromURL"
BASE_PATH="/path/to/where/you/are/backing/up"

# ----- QUIET -----
exec >/dev/null 2>&1
ts() { date +"%Y-%m-%dT%H:%M:%S%z"; }
log(){ printf "%s %s\n" "$(ts)" "$1" >> "$LOG_FILE"; }
die(){ log "ERROR: $*"; exit 1; }
trap 'rc=$?; [ $rc -ne 0 ] && log "ERROR: unexpected exit $rc"' ERR

# ----- PREP -----
ZIP_PATH="$BASE_PATH/proj.zip"
EXTRACT_DIR="$BASE_PATH/Thesis"
LOG_FILE="$BASE_PATH/cron.log"
mkdir -p "$(dirname "$ZIP_PATH")" "$EXTRACT_DIR" || die "cannot create paths"
command -v curl >/dev/null || die "curl not found"
command -v unzip >/dev/null || die "unzip not found"
command -v git  >/dev/null || die "git not found"

cookie=$(mktemp); page=$(mktemp)
cleanup(){ rm -f "$cookie" "$page"; }
trap cleanup EXIT

# ----- LOGIN -----
curl -sS "$BASE_URL/login" -c "$cookie" -o "$page"

csrf="$(grep -oP '<meta[^>]*name=["'\'']csrf-token["'\''][^>]*content=["'\'']\K[^"'\''>]+' "$page" || true)"
[ -z "$csrf" ] && csrf="$(grep -oP '<input[^>]*name=["'\'']_csrf["'\''][^>]*value=["'\'']\K[^"'\''>]+' "$page" || true)"
[ -z "$csrf" ] && csrf="$(grep -oP 'csrf[-_ ]?token[^:=]*[:=]\s*["'\'']\K[^"'\'';]+' "$page" || true)"
[ -n "$csrf" ] || die "no CSRF token"

login_json=$(printf '{"_csrf":"%s","email":"%s","password":"%s"}' "$csrf" "$EMAIL" "$PASSWORD")
curl -sS "$BASE_URL/login" \
  -H 'Content-Type: application/json' -H "X-Csrf-Token: $csrf" \
  -b "$cookie" -c "$cookie" --data "$login_json" -o /dev/null

grep -q 'sharelatex.sid' "$cookie" || die "auth failed"

# ----- DOWNLOAD & EXTRACT -----
curl -sS -b "$cookie" "$BASE_URL/project/$PROJECT/download/zip" -o "$ZIP_PATH"
[ -s "$ZIP_PATH" ] || die "empty zip"
unzip -oq "$ZIP_PATH" -d "$EXTRACT_DIR" || die "extract failed"

# ----- GIT COMMIT -----
git -C "$EXTRACT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { git -C "$EXTRACT_DIR" init -q >/dev/null 2>&1 || true; }

git -C "$EXTRACT_DIR" add -A
if [ -n "$(git -C "$EXTRACT_DIR" status --porcelain)" ]; then
  msg="Update from KT-ShareLaTeX: $(ts)"
  git -C "$EXTRACT_DIR" commit -qm "$msg" || die "commit failed"
  hash=$(git -C "$EXTRACT_DIR" rev-parse --short HEAD || echo "?")
  log "COMMITTED $hash: $msg"
  git -C "$EXTRACT_DIR" push || die "push failed (either origin not set or some merge issue)"
else
  log "NO_CHANGES"
fi

