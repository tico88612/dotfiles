# Dotfiles design

## Goals

1. A new macOS or Linux machine can restore its selected configuration with
   `chezmoi init` followed by `chezmoi apply`.
2. Portable files are shared and platform differences are explicit templates.
3. Configuration domains remain independent even though chezmoi applies them
   together.
4. External repositories and setup actions use chezmoi-native externals and
   scripts.
5. Sensitive configuration is isolated so adding another encrypted domain does
   not couple it to unrelated configuration.

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
│   ├── .chezmoiignore.tmpl        # platform and opt-in selection
│   ├── .chezmoiexternal.toml      # Git-managed OMZ and pinned plugins
│   ├── .chezmoiscripts/
│   ├── .chezmoitemplates/
│   │   └── Brewfile
│   ├── dot_zshrc
│   ├── dot_zprofile.tmpl
│   ├── dot_zshenv
│   ├── dot_p10k.zsh
│   ├── private_dot_ssh/            # opt-in base + encrypted host topology
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
      +--> run_after: UV completion, Herdr plugins, iTerm2 default
      +--> run_onchange_after: LazyVim lockfile restoration

live edit -> chezmoi re-add -> Git commit
source edit -> chezmoi edit --apply -> Git commit
```

Chezmoi owns rendering, target permissions, diffing, application, and script
state. There is no additional wrapper or module orchestration layer.

## Platform policy

### Shared by macOS and Linux

- Zsh startup files and Powerlevel10k configuration.
- Git-managed Oh My Zsh and pinned third-party plugin archives.
- Opt-in SSH base configuration.
- Opt-in age-encrypted SSH host topology.
- Host-to-key selection through locally generated 1Password SSH Bookmarks.
- Neovim and LazyVim configuration.

### Darwin only

- Opt-in iTerm2 Dynamic Profile and default-profile selection.
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
- LazyVim restoration runs when `lazy-lock.json` changes.

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

- SSH client base template.
- Age-encrypted private host topology.
- Non-secret 1Password vault selection metadata.

Not tracked:

- Private keys, 1Password-generated bookmark configuration and public identity
  files, `known_hosts`, sockets, or generated agent state.

The source attributes make `~/.ssh`, its config, and the 1Password agent
configuration private. The base config includes `~/.ssh/config.d/hosts.conf`,
whose source is encrypted with age. The age identity is restored separately
from 1Password and never enters Git. It also includes the 1Password-managed
`~/.ssh/1Password/config`, which maps bookmarked host aliases to locally
generated public identity selectors. Those generated files never enter Git.
The 1Password socket and OrbStack include are emitted only on Darwin.

`data.enableSSH` is selected during `chezmoi init`. When false,
`.chezmoiignore.tmpl` excludes the complete SSH target and the 1Password SSH
Agent configuration. Opting out is non-destructive: existing destination files
are left untouched.

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

The target is ignored outside Darwin and defaults to disabled on macOS. The
iTerm2 cask is also intentionally absent from the base Brewfile. Install the
application separately and enable the profile per machine with
`data.enableIterm2 = true`. UI edits can then be intentionally captured with
`chezmoi re-add`.

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

## Secrets

Chezmoi transparently decrypts the SSH host inventory with an age identity kept
in 1Password. Future secret domains, such as AWS credentials, may independently
use age-encrypted files or 1Password template functions without making Zsh,
SSH, or Neovim depend on them.

## Decisions to revisit

- Define a conservative Ubuntu package manifest and installation script.
- Decide whether Herdr and 1Password Desktop should be opt-in on Linux.
- Add Ghostty as a separate terminal target.
- Add automated secret scanning before configuring a remote.
