# dotfiles

Cross-platform personal configuration managed directly by
[chezmoi](https://www.chezmoi.io/). Portable Zsh, SSH, and Neovim settings are
shared between macOS and Linux; macOS-only applications are selected by
chezmoi templates.

## New machine

Install chezmoi, initialize the repository, and choose whether this machine
should manage SSH configuration and personal Git identity:

```sh
# macOS
brew install chezmoi age

# Ubuntu/Debian
sudo apt-get install chezmoi age

# Initialization prompts separately control SSH and Git identity.
chezmoi init <repository-url>

# Restore the age identity when either encrypted domain was enabled.
install -d -m 700 ~/.config/chezmoi
(umask 077; op read 'op://<vault>/<item>/<field>' > ~/.config/chezmoi/age-key.txt)
chmod 600 ~/.config/chezmoi/age-key.txt

# When SSH was enabled, also enable the 1Password SSH Agent and bookmarked-host
# config generation before applying.

chezmoi apply
```

For this existing local checkout:

```sh
chezmoi init --source ~/.dotfiles
chezmoi apply
```

On macOS, the first apply runs the tracked Brewfile through `brew bundle`.
Linux package automation is intentionally deferred until the desired Ubuntu
package policy is defined.

## Daily workflow

```sh
# Show destination drift.
chezmoi status
chezmoi diff

# Edit source state and apply the result.
chezmoi edit --apply ~/.zshrc

# Or edit ~/.zshrc normally, then capture it back into source state.
chezmoi re-add ~/.zshrc

# Pull the Git repository and apply it.
chezmoi update

# Commit source changes.
chezmoi cd
git diff
git add .
git commit
```

Oh My Zsh remains a Git repository and is updated explicitly with
`omz update`. A normal `chezmoi apply` does not pull it. Third-party Zsh
plugins and Powerlevel10k remain pinned by this repository.

## Managed configuration

- Zsh, Git-managed Oh My Zsh, Powerlevel10k, and pinned plugins.
- Portable Git behavior, with personal identity and commit signing separately
  opt-in and encrypted using age.
- Opt-in SSH client configuration, with host topology encrypted using age and
  host-to-key selection delegated to 1Password SSH Bookmarks.
- LazyVim configuration with a locked plugin set.
- Markdown image and Mermaid rendering through Snacks and Kitty graphics.
- Herdr configuration and plugins on macOS.
- An opt-in rewritable iTerm2 Dynamic Profile on macOS.
- Non-secret 1Password SSH Agent vault selection on macOS.

The age identity and SSH private keys remain in 1Password and are not tracked.
Git name, email, signing key, and signing configuration are stored only in an
age-encrypted source file. The 1Password app locally generates its bookmark
config and public identity selectors; neither enters Git. Runtime state,
histories, logs, caches, sockets, and generated credentials are also excluded.

SSH management is selected per machine with `data.enableSSH`. When disabled,
chezmoi leaves any existing SSH files untouched; it does not remove them.
Personal Git identity is controlled independently with
`data.enableGitIdentity`; portable aliases and fetch behavior remain enabled.

See [DESIGN.md](DESIGN.md) for platform boundaries and future secret-management
extensions.
