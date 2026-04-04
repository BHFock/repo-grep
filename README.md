# repo-grep

[![Tutorial](https://img.shields.io/badge/Tutorial-View-blue)](https://github.com/BHFock/repo-grep/blob/main/docs/repo-grep-tutorial.md)
[![Story](https://img.shields.io/badge/Story-Origin-lightgrey)](docs/history.md)
[![MELPA](https://melpa.org/packages/repo-grep-badge.svg)](https://melpa.org/#/repo-grep)
[![MELPA Stable](https://stable.melpa.org/packages/repo-grep-badge.svg)](https://stable.melpa.org/#/repo-grep)
[![GitHub stars](https://img.shields.io/github/stars/BHFock/repo-grep?style=social)](https://github.com/BHFock/repo-grep/stargazers)

## Search the symbol at point across repositories in Emacs

Use the symbol at point as the default term for recursive search in the current repository or across sibling repositories, with results shown in Emacs’ standard `*grep*` buffer.


**repo-grep** runs a recursive grep through the folder structure of your Git repository, SVN working copy, or plain folder. It uses the symbol under the cursor as the default search term, which you can edit interactively. The search term can include a regular expression, and you can configure regex patterns as a prefix or suffix to further refine the search.

**repo-grep-multi** searches across all sibling folders under the parent directory of the current project. 

## Dependencies

- Emacs ≥ 27.1
- `grep` (available on Unix-like systems)
- `rg` (optional — [ripgrep](https://github.com/BurntSushi/ripgrep), for the rg backend)

## Quickstart

### 1. Clone the repository (or install via MELPA)

```
git clone https://github.com/BHFock/repo-grep.git ~/repo-grep
```

### 2. Add this to your Emacs configuration (`~/.emacs` or `~/.emacs.d/init.el`)

```
(add-to-list 'load-path "~/repo-grep")
(autoload 'repo-grep "repo-grep")
(autoload 'repo-grep-multi "repo-grep")
(global-set-key [f12] 'repo-grep)
(global-set-key [C-f12] 'repo-grep-multi)
```

### 3. Open any file and start searching

- Place the cursor over a symbol (e.g., variable or function name)
- Press `F12` to search the current repository or `Ctrl + F12` to search across sibling repositories
- Edit the suggested term or press `Enter` to accept
- Browse results in the clickable `*grep*` buffer — use `n` and `p` to move between matches, `RET` to jump to the source, and `q` to quit

For a detailed guide to all features, see the [repo-grep tutorial](docs/repo-grep-tutorial.md).

## Advanced Usage & Customisation

| Setting | Variable | Default | Toggle |
|---|---|---|---|
| Case sensitivity | `repo-grep-case-sensitive` | off | `M-x repo-grep-set-case-sensitivity` |
| Ignore binary files | `repo-grep-ignore-binary` | on | `M-x repo-grep-set-ignore-binary` |
| Search backend | `repo-grep-backend` | `grep` (alternative: `rg`) | `M-x repo-grep-set-backend` |
| Respect .gitignore (rg only) | `repo-grep-rg-use-gitignore` | off | `M-x repo-grep-set-rg-use-gitignore` |
| Multiple grep buffers | `repo-grep-new-buffer` | off | `M-x repo-grep-set-new-buffer` |
| Restrict to subfolder | `repo-grep-subfolder` | nil | `M-x repo-grep-set-subfolder` |

All settings can also be set directly in your configuration, e.g. `(setq repo-grep-case-sensitive t)`.

### File type filters

Use `:include-ext` to restrict search to specific file types, or `:exclude-ext` to ignore them. See the [tutorial](docs/repo-grep-tutorial.md) for examples.

### Regex context

Use `:left-regex` and `:right-regex` to match a symbol only in specific code contexts, such as assignments or subroutine calls. See the [tutorial](docs/repo-grep-tutorial.md) for examples.

### Filter grep results

`M-x repo-grep-filter` clones the current `*grep*` buffer and filters it to lines matching a regexp, leaving the original intact. To bind it to `f` in grep buffers, add this to your init.el:
```elisp
(repo-grep-setup-keybindings)
```

## Security

repo-grep performs local, read-only searches using standard grep or rg and core Emacs functionality. It does not initiate network connections, execute remote code, or require elevated permissions. Inputs to shell commands are sanitised to reduce shell-injection risk.

The package is available via [MELPA](https://melpa.org/#/repo-grep), which performs an initial manual review but builds updates automatically from the main branch. Users concerned about supply-chain integrity are encouraged to install from a tagged release or known commit.

For the full security policy, trust model, and instructions for reporting issues, see [SECURITY.md](./SECURITY.md).

## License

BSD 3-Clause License — see [LICENSE](./LICENSE) for details. For the story behind the tool, see [History](docs/history.md).
