#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"
usage() { printf '%s\n' 'Usage: web-search.sh' 'Prompt for a query and open an encoded DuckDuckGo search URL (override with WEB_SEARCH_BASE_URL).'; }
[[ ${1:-} == --help ]] && { usage; exit 0; }
[[ $# == 0 ]] || { usage >&2; exit 2; }
require python3
require xdg-open
query=$(printf '' | fuzzel_dmenu --prompt='Web › ' --placeholder='Search the web') || exit 0
[[ -n $query ]] || exit 0
base=${WEB_SEARCH_BASE_URL:-https://duckduckgo.com/?q=}
url=$(python3 -c 'import sys, urllib.parse; print(sys.argv[1] + urllib.parse.quote_plus(sys.argv[2]))' "$base" "$query")
setsid -f xdg-open "$url" >/dev/null 2>&1
