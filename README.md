# dotfiles

Cross-platform personal configuration managed directly by
[chezmoi](https://www.chezmoi.io/). Portable Zsh, SSH, and Neovim settings are
shared between macOS and Linux; macOS-only applications are selected by
chezmoi templates.

## New machine

Install chezmoi, then initialize and apply this repository:

```sh
# macOS
brew install chezmoi

# Ubuntu/Debian
sudo apt-get install chezmoi

chezmoi init --apply <repository-url>
```

For this existing local checkout:

```sh
chezmoi init --source ~/.dotfiles --apply
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
- SSH client configuration and public identity selectors.
- LazyVim configuration with a locked plugin set.
- Markdown image and Mermaid rendering through Snacks and Kitty graphics.
- Herdr configuration and plugins on macOS.
- An opt-in rewritable iTerm2 Dynamic Profile on macOS.
- Non-secret 1Password SSH Agent vault selection on macOS.

Private SSH keys, runtime state, histories, logs, caches, sockets, and generated
credentials are not tracked.

See [DESIGN.md](DESIGN.md) for platform boundaries and future secret-management
extensions.
