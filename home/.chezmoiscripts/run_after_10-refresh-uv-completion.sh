#!/usr/bin/env bash

set -euo pipefail

command -v uv >/dev/null 2>&1 || exit 0

destination="$HOME/.oh-my-zsh/custom/plugins/uv/uv.plugin.zsh"
temporary="$(mktemp "${TMPDIR:-/tmp}/chezmoi-uv.XXXXXX")"
trap 'rm -f "$temporary"' EXIT

uv generate-shell-completion zsh > "$temporary"
if [[ -f "$destination" ]] && cmp -s "$temporary" "$destination"; then
  exit 0
fi

mkdir -p "$(dirname "$destination")"
chmod 0644 "$temporary"
mv "$temporary" "$destination"
trap - EXIT
printf '[chezmoi] refreshed uv completion\n'
