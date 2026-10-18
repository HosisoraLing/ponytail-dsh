#!/usr/bin/env bash
# Install or remove the ponytail-dsh adapter for DeepSeek Harness (dsh).
#   bash install.sh              install
#   bash install.sh --uninstall  remove (restores any AGENTS.md content you wrote)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
dsh_home="${DSH_HOME:-$HOME/.dsh}"
names="ponytail ponytail-review ponytail-audit ponytail-debt ponytail-gain ponytail-help"
begin='<!-- ponytail-dsh:begin'
end='<!-- ponytail-dsh:end -->'

strip_block() {
  awk -v b="$begin" -v e="$end" 'index($0,b){skip=1} !skip{print} index($0,e){skip=0}'
}

skills_root="$dsh_home/skills"
target="$dsh_home/AGENTS.md"
flag="$dsh_home/.ponytail-active"

if [ "${1:-}" = "--uninstall" ]; then
  for n in $names; do rm -rf "$skills_root/$n"; done
  if [ -f "$target" ]; then
    kept="$(strip_block < "$target")"
    if [ -n "$(printf '%s' "$kept" | tr -d '[:space:]')" ]; then
      printf '%s\n' "$kept" > "$target"
    else
      rm -f "$target"
    fi
  fi
  rm -f "$flag"
  echo 'ponytail-dsh uninstalled'
  exit 0
fi

mkdir -p "$skills_root"
for n in $names; do rm -rf "$skills_root/$n"; cp -R "$here/skills/$n" "$skills_root/"; done

block="$(cat "$here/AGENTS.md")"
kept=''
[ -f "$target" ] && kept="$(strip_block < "$target")"
if [ -n "$(printf '%s' "$kept" | tr -d '[:space:]')" ]; then
  printf '%s\n\n%s\n' "$kept" "$block" > "$target"
else
  printf '%s\n' "$block" > "$target"
fi

echo "skills  -> $skills_root/{ponytail,...}"
echo "rules   -> $target (managed block '<!-- ponytail-dsh:begin -->')"
echo "level   -> $flag (lite|full|ultra|off, written on level switch)"
echo 'ponytail-dsh installed'
