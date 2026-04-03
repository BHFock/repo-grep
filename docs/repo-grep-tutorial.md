# repo-grep Tutorial

## Table of Contents
1. [Getting started](#1-getting-started)
2. [Your first search](#2-your-first-search)
3. [Narrowing your search](#3-narrowing-your-search)
4. [Working with results](#4-working-with-results)
5. [Matching patterns in context](#5-matching-patterns-in-context)
6. [Reference](#6-reference)

## 1. Getting started

This tutorial walks you through repo-grep from a first search to more
advanced workflows. For installation instructions, see the
[README](../README.md).

Once installed, you have two commands available:

- `repo-grep` — searches recursively from the root of the current
  repository or directory
- `repo-grep-multi` — broadens the search to all sibling folders under
  the parent directory, useful when working across multiple related
  repositories

Bind them to convenient keys in your init.el:
```elisp
(global-set-key [f12]   'repo-grep)
(global-set-key [C-f12] 'repo-grep-multi)
```

## 2. Your first search

Open any source file and place your cursor on a symbol — a variable name,
function, or keyword. Press `F12`. repo-grep detects the symbol under the
cursor and pre-fills it as the search term in the minibuffer.

Press `Enter` to accept it, or edit the term before confirming.
Results appear immediately in the `*grep*` buffer — use `n` and `p` to
move between matches, `RET` to jump to the source, and `q` to quit.



## 3. Narrowing your search

### Restrict to a subfolder

Large scientific projects often have a clear directory structure —
source code, tests, data, and documentation in separate trees. If you
only want to search within `src/` and ignore everything else:
```elisp
(setq repo-grep-subfolder "src")
```

Set it interactively with `M-x repo-grep-set-subfolder`, which prompts you to pick a folder from your project root. To clear the restriction, use `M-x repo-grep-clear-subfolder`, or set it back to `nil` directly.

If you're browsing in Dired, `M-x repo-grep-set-subfolder-from-dired`
sets the subfolder to whichever directory is under the cursor.

### Searching across multiple repositories

`repo-grep-multi` searches all sibling directories under the parent of your current project root — useful when related code is spread across several repositories checked out side by side.

A typical climate modelling workspace might look like this:

```
~/climate/
├── cesm/             ← model source (current repo)
├── postproc/         ← diagnostic and output processing
└── verification/     ← observational comparisons and validation scripts
```

Opening any file inside `cesm/` and pressing `C-F12` searches all three directories in one pass. This is particularly convenient when a shared name — say, `ocean_heat_content` — appears in model output routines, post-processing scripts, and verification code, and you want to trace every reference across the full stack in a single search.

Note that any active `repo-grep-subfolder` restriction is ignored by `repo-grep-multi` — the search always spans all sibling directories regardless.


### Searching across a project with Git submodules

When you open a file inside a Git submodule, `vc-root-dir` returns the submodule root rather than the parent repository root. Suppose your repository looks like this:

```
~/climate-model/
├── .git/
├── src/
├── docs/
└── vendor/
└── netcdf-fortran/   ← Git submodule, has its own .git
```

Opening a file inside `vendor/netcdf-fortran/` and pressing `F12` searches only the submodule. Use `M-x repo-grep-set-root` to point repo-grep at the parent repository instead:

```elisp
M-x repo-grep-set-root  →  select ~/climate-model/
```

All subsequent searches use that root until you clear it with `M-x repo-grep-clear-root` or restart Emacs.

### Case sensitivity

By default searches are case-insensitive. In Python codebases this
matters: class names follow `CamelCase` while variables and functions
use `snake_case`, so searching for `DataProcessor` case-sensitively
avoids false matches from `data_processor` or `dataprocessor`.

Toggle with `M-x repo-grep-set-case-sensitivity`, or set permanently:
```elisp
(setq repo-grep-case-sensitive t)
```

### Search backend

For large repositories, switching to ripgrep gives noticeably faster
results with identical output:
```elisp
(setq repo-grep-backend 'rg)
```

Toggle with `M-x repo-grep-set-backend`. ripgrep must be installed and
available on your PATH.

## 4. Working with results

### Filtering results

When a search returns many matches, `M-x repo-grep-filter` lets you
narrow them without re-running the search. You are prompted for a
regexp — repo-grep clones the current buffer and keeps only matching
lines, leaving the original intact. Links in the filtered buffer
navigate directly to source files just as in the original.

This is useful when you want to focus on a specific file or secondary
keyword within a large result set — for example, searching for all uses
of `temperature` across a project, then filtering for matches in
`forcing.nml` only.

To bind the filter command to `f` in grep buffers, add this to your
init.el:
```elisp
(repo-grep-setup-keybindings)
```

### Multiple search buffers

When tracing something complex across a codebase — say, understanding
how a numerical solver is initialised, called, and its results consumed
— it helps to have several searches open side by side. Toggle this on
the fly with `M-x repo-grep-set-new-buffer`, or set it permanently:
```elisp
(setq repo-grep-new-buffer t)
```

Each search opens a new `*grep*` buffer named `*grep*`, `*grep*<2>`,
`*grep*<3>`, and so on. Switch between them with `C-x b`.

## 5. Matching patterns in context

The `:left-regex` and `:right-regex` keyword arguments let you match a
symbol only when it appears in a specific code context, by prepending or
appending a regex fragment to the search term. These options require a
keybinding to use fluidly — a natural next step once you find yourself
reaching for them regularly.

### Tracing subroutine calls and variable assignments

Two patterns that are particularly useful in large Fortran codebases:
```elisp
(global-set-key [f10]
  (lambda () (interactive)
    (repo-grep :left-regex "CALL.*")))

(global-set-key [f11]
  (lambda () (interactive)
    (repo-grep :right-regex ".*=")))
```

Place your cursor on a subroutine name and press `F10` to find every
call site — building a lightweight interactive call tree without any
static analysis tools. Press `F11` on a global variable to find every
line where it is assigned, distinguishing writes from reads. Together
they make it straightforward to trace both control flow and data flow
across a large codebase.

### Restricting to specific file types

To search only Fortran source files and ignore everything else:
```elisp
(global-set-key [f9]
  (lambda () (interactive)
    (repo-grep :include-ext '(".f90" ".F90"))))
```

Use `:exclude-ext` to ignore specific types instead — for example
`'(".log" "~")` to skip logs and Emacs backup files.

## 6. Reference

### All settings

| Setting | Variable | Default | Toggle |
|---|---|---|---|
| Case sensitivity | `repo-grep-case-sensitive` | off | `M-x repo-grep-set-case-sensitivity` |
| Ignore binary files | `repo-grep-ignore-binary` | on | `M-x repo-grep-set-ignore-binary` |
| Search backend | `repo-grep-backend` | `grep` (alternative: `rg`) | `M-x repo-grep-set-backend` |
| Respect .gitignore (rg only) | `repo-grep-rg-use-gitignore` | off | `M-x repo-grep-set-rg-use-gitignore` |
| Multiple grep buffers | `repo-grep-new-buffer` | off | `M-x repo-grep-set-new-buffer` |
| Restrict to subfolder | `repo-grep-subfolder` | nil | `M-x repo-grep-set-subfolder` |

All settings can also be set directly in your configuration, e.g. `(setq repo-grep-case-sensitive t)`.

### Binary file search

By default repo-grep skips binary files. To include them:
```elisp
(setq repo-grep-ignore-binary nil)
```

### ripgrep and .gitignore

When using the `rg` backend, repo-grep bypasses `.gitignore` by default
to match the behaviour of the `grep` backend. To restore rg's default
behaviour of respecting `.gitignore`:
```elisp
(setq repo-grep-rg-use-gitignore t)
```

### Subfolder from Dired

If you are browsing in Dired, `M-x repo-grep-set-subfolder-from-dired`
sets the subfolder to whichever directory is under the cursor — a
convenient alternative to `M-x repo-grep-set-subfolder`.

[Back to top ↑](#table-of-contents)

