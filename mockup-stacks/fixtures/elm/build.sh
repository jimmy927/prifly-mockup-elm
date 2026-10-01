#!/usr/bin/env bash
# needs: elm
# Compiles the fixture app with the real Elm compiler (--optimize) and packs it into one self-contained page.
# Needs the packages elm/core, elm/html, elm/browser in ELM_HOME (the first run downloads them, about 1 MB).
set -euo pipefail
export ELM_HOME="${ELM_HOME:-$HOME/.cache/mockup-toolchains/elm/home}"
cd "$(dirname "$0")"
out="${1:-dist/index.html}"
mkdir -p "$(dirname "$out")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
elm make src/Main.elm --optimize --output="$tmp/elm.js" >/dev/null
python3 - "$tmp/elm.js" "$out" <<'PY'
import sys
js = open(sys.argv[1], encoding="utf-8").read().replace("</script", "<\\/script")
page = open("index.html", encoding="utf-8").read()
css = open("style.css", encoding="utf-8").read()
page = page.replace("/*@@CSS@@*/", css).replace("/*@@ELM@@*/", js)
open(sys.argv[2], "w", encoding="utf-8").write(page)
PY
if grep -Eq 'https?://[a-z]' "$out" && grep -Eoq '(src|href)="https?://' "$out"; then
  echo "page loads something from the network" >&2; exit 1
fi
test -s "$out"
echo "built $out ($(wc -c <"$out") bytes)"
