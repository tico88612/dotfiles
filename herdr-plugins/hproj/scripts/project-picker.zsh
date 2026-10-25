#!/bin/zsh

# Colon-separated roots may be overridden for a single invocation.
# Example: HPROJ_ROOTS="$HOME/src:$HOME/work" project-picker.zsh
local roots_value=${HPROJ_ROOTS:-"$HOME/working:$HOME/Learning"}
local max_depth=${HPROJ_MAX_DEPTH:-4}
local -a roots existing_roots
roots=("${(@s/:/)roots_value}")

for root in "${roots[@]}"; do
  [[ -d "$root" ]] && existing_roots+=("${root:A}")
done

fail() {
  print -u2 -- "hproj: $1"
  if [[ -t 0 ]]; then
    print -u2 -- ""
    read -rk 1 "?Press any key to close..."
  fi
  exit 1
}

[[ ${HERDR_ENV:-} == 1 ]] || fail "this picker must run inside Herdr"
(( ${#existing_roots[@]} > 0 )) || fail "none of the configured project roots exist"

local fd_bin fzf_bin jq_bin
fd_bin=$(command -v fd) || fail "fd is not installed"
fzf_bin=$(command -v fzf) || fail "fzf is not installed"
jq_bin=$(command -v jq) || fail "jq is not installed"
command -v herdr >/dev/null 2>&1 || fail "herdr is not on PATH"

list_projects() {
  "$fd_bin" --hidden --type d --type f --max-depth "$max_depth" '^\.git$' "${existing_roots[@]}" 2>/dev/null |
    while IFS= read -r git_dir; do
      git_dir=${git_dir%/}
      print -r -- "${git_dir%/.git}"
    done |
    /usr/bin/sort -u
}

list_picker_items() {
  local project_path root display

  list_projects |
    while IFS= read -r project_path; do
      display=$project_path
      for root in "${existing_roots[@]}"; do
        if [[ "$project_path" == "$root" ]]; then
          display=${root:t}
          break
        elif [[ "$project_path" == "$root"/* ]]; then
          display="${root:t}/${project_path#$root/}"
          break
        fi
      done
      printf '%s\t%s\n' "$display" "$project_path"
    done
}

if [[ ${1:-} == "--list" ]]; then
  list_projects
  exit 0
fi

local project
project=$(
  list_picker_items |
    "$fzf_bin" \
      --delimiter=$'\t' \
      --with-nth=1 \
      --accept-nth=2 \
      --prompt='Project > ' \
      --border \
      --height='100%' \
      --layout=reverse \
      --info=inline \
      --header='Enter: open · Esc: cancel' \
      --preview='/bin/ls -la {2} 2>/dev/null | /usr/bin/head -40' \
      --preview-window='right,55%,border-left'
) || exit 0

[[ -n "$project" ]] || exit 0
[[ -d "$project" ]] || fail "selected project no longer exists: $project"

local label=${project:t}
local created workspace_id nvim_tab_id nvim_pane_id
local codex_created codex_tab_id codex_pane_id terminal_created

created=$(
  herdr workspace create \
    --cwd "$project" \
    --label "$label" \
    --env TMUX= \
    --env TMUX_PANE= \
    --no-focus
) || fail "could not create workspace"

workspace_id=$(print -r -- "$created" | "$jq_bin" -er '.result.workspace.workspace_id') ||
  fail "workspace response did not contain a workspace id"
nvim_tab_id=$(print -r -- "$created" | "$jq_bin" -er '.result.tab.tab_id') ||
  fail "workspace response did not contain a tab id"
nvim_pane_id=$(print -r -- "$created" | "$jq_bin" -er '.result.root_pane.pane_id') ||
  fail "workspace response did not contain a pane id"

herdr tab rename "$nvim_tab_id" nvim >/dev/null || fail "could not rename the Neovim tab"
herdr pane run "$nvim_pane_id" "nvim ." >/dev/null || fail "could not start Neovim"

codex_created=$(
  herdr tab create \
    --workspace "$workspace_id" \
    --cwd "$project" \
    --label codex \
    --env TMUX= \
    --env TMUX_PANE= \
    --no-focus
) || fail "could not create the Codex tab"

codex_tab_id=$(print -r -- "$codex_created" | "$jq_bin" -er '.result.tab.tab_id') ||
  fail "Codex tab response did not contain a tab id"
codex_pane_id=$(print -r -- "$codex_created" | "$jq_bin" -er '.result.root_pane.pane_id') ||
  fail "Codex tab response did not contain a pane id"
herdr pane run "$codex_pane_id" codex >/dev/null || fail "could not start Codex"

terminal_created=$(
  herdr tab create \
    --workspace "$workspace_id" \
    --cwd "$project" \
    --label terminal \
    --env TMUX= \
    --env TMUX_PANE= \
    --no-focus
) || fail "could not create the terminal tab"

herdr workspace focus "$workspace_id" >/dev/null || fail "could not focus the new workspace"
herdr tab focus "$nvim_tab_id" >/dev/null || fail "could not focus the Neovim tab"
