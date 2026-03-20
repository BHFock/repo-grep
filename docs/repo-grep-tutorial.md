# repo-grep Tutorial

## Table of Contents
1. [Introduction to repo-grep](#1-introduction-to-repo-grep)
2. [Installation & setup](#2-installation--setup)
3. [Basic usage](#3-basic-usage)
4. [Scope Control](#4-scope-control)
5. [File Filtering](#5-file-filtering)
6. [Search Behaviour](#6-search-behaviour)

## 1. Introduction to repo-grep

Navigating large codebases in Emacs can be fast and seamless with `repo-grep`. It brings project-wide search directly into Emacs — eliminating the need to switch to a terminal or external tools.

### Key features:

- **One-keystroke search:** Instantly grep for the symbol under your cursor — with minimal prompts and no setup required.
- **Smart project root detection:** Automatically locates your Git or SVN root; falls back to the current directory if needed.
- **Multi-repo search:** Scan all sibling repos with `repo-grep-multi`.
- **Searches all files:** Non-binary files are searched by default, even if untracked by version control.
- **Optional binary file search:** Skip binary files by default, or include them when needed.
- **Regex support:** Add prefix/suffix patterns to fine-tune matches.
- **Custom file exclusions and case sensitivity:** Tailor results to your workflow.
- **ripgrep backend:** Optional rg backend for significantly faster searches on large repositories.

`repo-grep` keeps you focused inside Emacs — no context-switching, no distractions.

For a quick overview, installation instructions, and access to the source code, visit the `repo-grep` GitHub [repository](https://github.com/BHFock/repo-grep).

[Back to top ↑](#table-of-contents)

## 2. Installation & setup

### Prerequisites

Before installing `repo-grep`, make sure the following is available:

- **Emacs**: Version 27.1 or newer is required.
- **Grep**: `repo-grep` executes shell-based grep commands to perform searches.
- **rg** (optional): If [ripgrep](https://github.com/BurntSushi/ripgrep) is installed, 
  you can use it as an alternative search backend for faster searches on large repositories.

No additional tools or packages are required. This makes setup simple. `repo-grep` uses VCS roots to detect project directories and works independently of Emacs's built-in `project.el` package.

### Installing repo-grep

#### Clone the repository

Run the following command in your terminal:

```
git clone https://github.com/BHFock/repo-grep.git ~/repo-grep
```

You may use a different folder, but be sure to update your Emacs configuration accordingly.

#### Load repo-grep in Emacs

Edit your Emacs configuration file (`~/.emacs` or `~/.emacs.d/init.el`) and add:

```elisp
;; Add repo-grep to your Emacs load path
(add-to-list 'load-path "~/repo-grep")

;; Autoload repo-grep functions for efficient project-wide search
(autoload 'repo-grep "repo-grep")
(autoload 'repo-grep-multi "repo-grep")
```

Make sure `~/repo-grep` matches the actual path where you cloned the repository.

#### Define keybindings

To enable instant searching, bind the functions to convenient keys:

```elisp
(global-set-key [f12] 'repo-grep)         ;; Single-repository search
(global-set-key [C-f12] 'repo-grep-multi) ;; Multi-repository search
```

Once you've saved these changes, reload your Emacs configuration or restart Emacs to apply them. You're now ready to start searching with `repo-grep` using just a keystroke. Next, we’ll look at basic usage patterns and how to refine your searches.

[Back to top ↑](#table-of-contents)

## 3. Basic usage

### Starting a search from the cursor position

To start a search, place your cursor over a symbol — such as a variable, function name, or keyword — and press `F12` (or run `M-x repo-grep`). `repo-grep` will automatically detect the symbol under the cursor and use it as the default search term. This uses Emacs’ built-in `thing-at-point`, which works best when your cursor is on a meaningful name in the code, like a variable or subroutine.

### Interactive query

You'll be prompted in the minibuffer with the detected symbol pre-filled. Press `Enter` to search as-is, or edit the term before confirming. This prompt supports regular expressions, so you can write more flexible patterns — for example `variable.*=` to match lines where a variable is assigned.

### Executing the search

Once confirmed, `repo-grep` locates the appropriate folder to search from:

* If you're in a Git repository or SVN working copy, it uses Emacs' built-in VCS root detection.
* If no VCS root is found, it defaults to the current directory.
* If repo-grep-subfolder is set, the search is restricted to that subfolder under the root.
* If repo-grep-from-folder-above is non-nil (as in `repo-grep-multi`), the search starts from the parent directory of the detected root.

Regardless of how the root is detected, `repo-grep` searches all files within that root — not just those tracked by version control. This makes it ideal for scanning generated files, uncommitted changes, and legacy code alongside source files.

### Reviewing results

Search results appear in a dedicated `*grep*` buffer. Each result is a clickable link — click (or press `RET`) to jump directly to the matching line in its file. You can also navigate between matches using `n` (next) and `p` (previous) within the grep buffer, making it easy to browse through results without using the mouse or switching windows. `q` will quit the `*grep*` buffer if you want to return to your file quickly.

With just one keystroke, `repo-grep` turns symbol lookup into a fast, interactive process — no need to leave Emacs or set up project metadata.

[Back to top ↑](#table-of-contents)

## 4. Scope Control

### Multi-repository search

If your projects are structured as multiple repositories or directories under a common parent folder, `repo-grep-multi` can search across all of them in one go. For example, if you have several sibling folders like `~/projects/repo1`, `~/projects/repo2`, and `~/projects/repo3`, `repo-grep-multi` will search across all subdirectories under `~/projects`.

Internally, it works by moving up one level from the detected Git or SVN root — effectively broadening the search scope. This makes multi-repo or multi-project searches automatic, flexible, and context-aware, without requiring any manual path configuration.

#### Example: Bind to `Ctrl + F12`

```elisp
(global-set-key [C-f12] 'repo-grep-multi)
```

Now pressing `Ctrl + F12` will search through all folders under the parent directory — no need to manually navigate or run multiple searches.


### Restrict search to a specific subfolder

Sometimes you don’t want to search your entire project — just a focused part of it. That’s where `repo-grep-subfolder` comes in.

You can use this setting to limit your search to a specific subdirectory under the project root. This is especially useful when your project has a typical structure like:

```
project-root/
├── src/
├── test/
└── build/
```

Let’s say you only want to search inside `src/` and ignore everything in `test/` and `build/`. You can do that by setting:

```elisp
(setq repo-grep-subfolder "src")
```

Now, all searches will be scoped to `project-root/src/` — and nothing outside it. It also works for nested subdirectories. For example, if you want to search only within `src/physics/` and ignore `src/io/`, just set:

```elisp
(setq repo-grep-subfolder "src/physics")
```

You can set this manually in your config, or interactively using:

```elisp
M-x repo-grep-set-subfolder
```

This will prompt you to select a subfolder from your project root.

Alternatively, if you're already browsing in Dired, you can set the subfolder directly from there:

```elisp
M-x repo-grep-set-subfolder-from-dired
```

This makes it easy to narrow your search to exactly the part of the codebase you care about — without touching the rest.

Note: `repo-grep-subfolder` is ignored when using `repo-grep-multi`, since multi-repo search always starts from the parent directory of the detected root.

[Back to top ↑](#table-of-contents)

## 5. File Filtering

### Exclude unwanted file types

To keep your results clean, you can tell `repo-grep` to ignore specific file extensions — such as logs, compiled outputs, or Emacs backups.

#### Example: Exclude `.log` and `~` files

```elisp
(global-set-key [f9]
  (lambda () (interactive)
    (repo-grep :exclude-ext '(".log" "~"))))
```

This ensures that temporary or irrelevant files don’t clutter your search output.

### Include only specific file types

To narrow your search to certain file types — like just Fortran source files — use the `:include-ext` keyword.

#### Example: Search only `.f90` and `.F90` files

```elisp
(global-set-key [f8]
  (lambda () (interactive)
    (repo-grep :include-ext '(".f90" ".F90"))))
```

This restricts results to Fortran files, ignoring others like `.txt`, `.md`, or `.log`.

If both `:include-ext` and `:exclude-ext` are set, `:include-ext` takes precedence.

[Back to top ↑](#table-of-contents)

## 6. Search Behaviour

### Case sensitivity (default: insensitive)

By default, `repo-grep` performs case-insensitive searches, which is often useful for general-purpose code scanning. If you want to enforce case-sensitive matching, you have two options:

#### Option 1: Set it in your configuration

```elisp
(setq repo-grep-case-sensitive t)
```

To restore the default (case-insensitive):

```elisp
(setq repo-grep-case-sensitive nil)
```

#### Option 2: Toggle it interactively

You can also toggle case sensitivity at any time using the built-in interactive command:

```elisp
M-x repo-grep-set-case-sensitivity
```

You will be prompted to select between ON and OFF. The setting is updated immediately — no need to edit your configuration or restart Emacs.

### Binary file search (default: off)

By default, `repo-grep` is configured to skip binary files, preventing matches inside compiled objects, images, and other non-text content. This keeps your search results clean and focused on source code.

If you want to include binary files in your search — for example, when debugging binary logs or examining non-ASCII data — you can control this behaviour using the `repo-grep-ignore-binary` setting.

#### Option 1: Set it in your configuration

To include binary files in searches:

```elisp
(setq repo-grep-ignore-binary nil)
```

To skip binary files (default behaviour):

```elisp
(setq repo-grep-ignore-binary t)
```

When enabled, this setting adds `--binary-files=without-match` to the grep command, which tells grep to ignore binary content entirely.

#### Option 2: Toggle it interactively

You can also change this setting on the fly without editing your config:

```elisp
M-x repo-grep-set-ignore-binary
```

You'll be prompted to choose whether to skip binary files (ON, default) or include them (OFF). Your choice takes effect immediately and applies to the next search you perform.

### Customise match context with regex prefixes and suffixes

You can customise searches to match specific code patterns using `:left-regex` or `:right-regex`. These options allow you to match a symbol only when it appears in a specific context — such as the left-hand side of an assignment or in a subroutine call. You can do this by prepending or appending regular expression fragments to your search term.

#### Example 1: Match variable assignments (symbol on the left-hand side)

To find where a variable is being assigned a value — and not just used in a calculation — you can append an equals sign using `:right-regex`.

```elisp
(global-set-key [f11]
  (lambda () (interactive)
    (repo-grep :right-regex ".*=")))
```

This searches for cases where the symbol appears to the left of an equals sign. For example, if your cursor is on `gravity_at_sea_level`, this pattern would match:

```
gravity_at_sea_level = 9.81
```

But it would not match if the variable is only used on the right-hand side:

```
weight = mass * gravity_at_sea_level
```

#### Example 2: Build an interactive call tree (subroutine calls)

If you're exploring a large Fortran or procedural codebase, you might want to trace which routines call a given subroutine — essentially building a lightweight, interactive call tree.

You can do this using a prefix regex that matches subroutine call sites, e.g., lines starting with `CALL`. This allows you to quickly jump to all points where a subroutine is invoked.

```elisp
(global-set-key [f10]
  (lambda () (interactive)
    (repo-grep :left-regex "CALL.*")))
```

With this setup, place your cursor over the name of a subroutine, press F10, and Emacs will list every line where it is called. Since results are clickable in the `*grep*` buffer, you can walk through each call site interactively — making it easy to understand control flow and dependencies, without any plugins or static analysis tools.

### Search backend (default: grep)

By default, `repo-grep` uses `grep`. If [ripgrep](https://github.com/BurntSushi/ripgrep)
is installed, you can switch to it as the search backend.

#### Option 1: Set it in your configuration

```elisp
(setq repo-grep-backend 'rg)
```

To restore the default:

```elisp
(setq repo-grep-backend 'grep)
```

#### Option 2: Toggle it interactively

```elisp
M-x repo-grep-set-backend
```

You will be prompted to select between `grep` and `rg`. The setting takes effect immediately.
Both backends produce clickable results in the same `*grep*` buffer — the UX is identical.

### ripgrep and .gitignore (default: bypass)

When using the rg backend, repo-grep bypasses `.gitignore` by default to ensure
complete search coverage — matching the behaviour of the grep backend.

If you want rg to respect `.gitignore` and similar ignore files:

#### Option 1: Set it in your configuration
```elisp
(setq repo-grep-rg-use-gitignore t)
```

To restore the default (bypass .gitignore):
```elisp
(setq repo-grep-rg-use-gitignore nil)
```

#### Option 2: Toggle it interactively
```elisp
M-x repo-grep-set-rg-use-gitignore
```

You will be prompted to select between ON and OFF. This setting only applies
when using the rg backend.

### Multiple grep buffers (default: off)

By default, each search reuses the same `*grep*` buffer, replacing previous
results. If you want to keep earlier results intact — for example, to compare
two searches side by side — you can open each search in a fresh buffer instead.

#### Option 1: Set it in your configuration
```elisp
(setq repo-grep-new-buffer t)
```

To restore the default (reuse the existing buffer):
```elisp
(setq repo-grep-new-buffer nil)
```

#### Option 2: Toggle it interactively
```elisp
M-x repo-grep-set-new-buffer
```

You will be prompted to select between ON and OFF. When enabled, each search
opens a new `*grep*` buffer named `*grep*`, `*grep*<2>`, `*grep*<3>`, and so
on. Switch between them with `C-x b` as with any other buffer.

### Filter results in an existing grep buffer

Once you have search results in a `*grep*` buffer, you can narrow them further without re-running the search using `repo-grep-filter`.
```elisp
M-x repo-grep-filter
```

You will be prompted for a regexp. A filtered clone of the current buffer is opened, leaving the original intact. Links in the filtered buffer navigate
directly to source files — just like in the original `*grep*` buffer.

This is useful when an initial search returns many results and you want to focus on a specific subset — for example, filtering for a particular filename or a secondary keyword.

To bind the filter command to `f` in grep buffers, add this to your init.el:
```elisp
(repo-grep-setup-keybindings)
```

[Back to top ↑](#table-of-contents)
