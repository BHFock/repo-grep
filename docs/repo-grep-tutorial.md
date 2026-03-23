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

Set it interactively with `M-x repo-grep-set-subfolder`, which prompts
you to pick a folder from your project root. To clear the restriction,
set it back to `nil`.

If you're browsing in Dired, `M-x repo-grep-set-subfolder-from-dired`
sets the subfolder to whichever directory is under the cursor.

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


