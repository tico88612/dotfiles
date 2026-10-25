# Dotfiles design

## Goals

1. A new macOS or Linux machine can restore its configuration with
   `chezmoi init --apply`.
2. Portable files are shared and platform differences are explicit templates.
3. Configuration domains remain independent even though chezmoi applies them
   together.
4. External repositories and setup actions use chezmoi-native externals and
   scripts.
5. Secrets remain optional and can later use 1Password or age without changing
   unrelated configuration.

## Non-goals

- Tracking runtime state, logs, sockets, caches, histories, or sessions.
- Tracking SSH private keys.
- Exporting complete application preferences databases.
- Installing an opinionated Linux package set before an Ubuntu policy is
  selected.

## Layout

```text
dotfiles/
├── .chezmoiroot                   # source state is home/
├── home/
│   ├── .chezmoi.toml.tmpl         # remembers the Git working tree as sourceDir
│   ├── .chezmoiignore.tmpl        # Darwin/Linux selection
│   ├── .chezmoiexternal.toml      # Git-managed OMZ and pinned plugins
│   ├── .chezmoiscripts/
│   ├── .chezmoitemplates/
│   │   └── Brewfile
│   ├── dot_zshrc
│   ├── dot_zprofile.tmpl
│   ├── dot_zshenv
│   ├── dot_p10k.zsh
│   ├── private_dot_ssh/
│   ├── dot_config/
│   │   ├── nvim/
│   │   ├── herdr/
│   │   └── private_1Password/     # target directory mode 0700
│   └── private_Library/           # mode 0700; ignored outside Darwin
├── manifests/
│   └── herdr-plugins.tsv
└── herdr-plugins/
    └── hproj/
```

The root-level `.chezmoiroot` lets project metadata remain outside the source
state applied to `$HOME`.

## Data flow

```text
Git repository
      |
      v
chezmoi source state + OS templates + externals
      |
      +--> run_onchange_before: macOS Brew bundle
      |
      v
rendered destination files in $HOME
      |
      +--> run_after: uv completion, Herdr plugins, iTerm2 default
      +--> run_onchange_after: LazyVim plugin synchronization

live edit -> chezmoi re-add -> Git commit
source edit -> chezmoi edit --apply -> Git commit
```

Chezmoi owns rendering, target permissions, diffing, application, and script
state. There is no additional wrapper or module orchestration layer.

## Platform policy

### Shared by macOS and Linux

- Zsh startup files and Powerlevel10k configuration.
- Git-managed Oh My Zsh and pinned third-party plugin archives.
- SSH host configuration and public identity selectors.
- Neovim and LazyVim configuration.

### Darwin only

- iTerm2 Dynamic Profile and default-profile selection.
- Herdr configuration and plugin setup.
- 1Password SSH Agent selection.
- OrbStack, JetBrains Toolbox, and the macOS 1Password agent socket.
- Homebrew packages and casks.

The SSH and Zsh templates omit Darwin-only lines when rendered on Linux.
`.chezmoiignore.tmpl` prevents macOS application configuration from being
created on Linux.

## Native chezmoi mechanisms

### Externals

`.chezmoiexternal.toml` keeps Oh My Zsh as a shallow Git repository so its
native `omz update` command remains available. Its zero refresh period prevents
a normal `chezmoi apply` from pulling it implicitly. `ZSH_CUSTOM` points to the
separate `~/.zsh-custom` tree, where Powerlevel10k and third-party plugins are
installed from immutable archives pinned to commits. Locally-generated
1Password and UV completions, compiled Zsh files, and dynamic zsh-nvm
completions are ignored so they do not create permanent drift.

### Scripts

Scripts are deliberately small and idempotent:

- The Darwin package script runs only when the embedded Brewfile checksum
  changes.
- UV completion refreshes after apply when `uv` exists.
- Herdr plugin reconciliation runs after apply on Darwin.
- iTerm2 default-profile selection runs after apply on Darwin.
- LazyVim synchronization runs when `lazy-lock.json` changes.

Missing optional applications cause their setup script to skip with a warning
rather than blocking portable configuration.

## Ownership boundaries

### Zsh

Tracked:

- Startup files and Powerlevel10k configuration.
- The Oh My Zsh Git external and pinned plugin archive definitions.

Not tracked:

- External framework/plugin contents after chezmoi downloads them.
- Completion caches and compiled files.

### SSH and 1Password

Tracked:

- SSH client template.
- Public identity files.
- Non-secret 1Password vault selection metadata.

Not tracked:

- Private keys, `known_hosts`, sockets, or generated agent state.

The source attributes make `~/.ssh`, its config, and the 1Password agent
configuration private. The 1Password socket and OrbStack include are emitted
only on Darwin.

### Herdr

Tracked:

- Herdr configuration.
- The user-authored `hproj` plugin.
- Desired third-party plugin revisions.

Not tracked:

- Sessions, registries, logs, sockets, managed plugin checkouts, or build output.

### iTerm2

Tracked:

- One rewritable Dynamic Profile.

Not tracked:

- The full preferences database, chat data, sockets, caches, or saved state.

The target is ignored outside Darwin. UI edits can be intentionally captured
with `chezmoi re-add`.

### Neovim

Tracked:

- LazyVim configuration and `lazy-lock.json`.
- Snacks Markdown image and Mermaid settings.

Not tracked:

- Installed plugins, Mason packages, parsers, caches, logs, sessions, or
  generated images.

## Existing-machine migration

Before the first apply:

1. Run `chezmoi init --source /path/to/repo`.
2. Review `chezmoi diff`.
3. Back up existing targets outside the repository if desired.
4. Run `chezmoi apply`.
5. Run `chezmoi doctor` and application-specific health checks.

Live destination edits do not modify Git automatically. Use
`chezmoi re-add <target>` to capture them.

## Future secrets

Chezmoi can retrieve values from 1Password template functions or transparently
manage age-encrypted source files. A future AWS module may use either mechanism
without making Zsh, SSH, or Neovim depend on a secret provider.

## Decisions to revisit

- Define a conservative Ubuntu package manifest and installation script.
- Decide whether Herdr and 1Password Desktop should be opt-in on Linux.
- Add Ghostty as a separate terminal target.
- Add automated secret scanning before configuring a remote.
