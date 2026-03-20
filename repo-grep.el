;;; repo-grep.el --- Project-wide grep search -*- lexical-binding: t; -*-

;; Author:  Bjoern Hendrik Fock
;; Version: 1.8.0
;; License: BSD-3-Clause
;; Keywords: tools search grep convenience project
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/BHFock/repo-grep
;; SPDX-License-Identifier: BSD-3-Clause

;; This file is free software; you can redistribute it and/or modify it under
;; the terms of the BSD-3-Clause License.

;;; Commentary:
;; `repo-grep' runs a recursive search through the folder structure of your Git
;; repository, SVN working copy, or plain folder. It uses the symbol under the
;; cursor as the default search term, which you can edit interactively. The
;; search term can include a regular expression, and you can configure regex
;; patterns as a prefix or suffix to further refine the search.
;;
;; The companion command `repo-grep-multi' extends this to a recursive search
;; across multiple repositories or folders located in the same parent directory.
;;
;; Features include:
;; - VCS-aware project root detection (Git or SVN)
;; - Optional restriction to a subdirectory within the project
;; - Case sensitivity and binary file handling options
;; - Customisable include/exclude file patterns
;; - Clickable results in a standard *grep* buffer
;; - Optional ripgrep (rg) backend for faster searches
;; - Optional .gitignore bypass when using the rg backend
;; - Optional multiple grep buffers to keep previous results intact
;; - Optional in-buffer filtering via `repo-grep-filter'
;;
;; To bind `repo-grep-filter' to f in grep buffers, call
;; `repo-grep-setup-keybindings' in your init.el.
;;
;; For installation, configuration, and usage examples, see the README and
;; the tutorial at https://github.com/BHFock/repo-grep.

;;; Code:

(require 'dired)

(defgroup repo-grep nil
  "Project-wide grep search from Emacs."
  :group 'tools
  :prefix "repo-grep-")

(defcustom repo-grep-from-folder-above nil
  "If non-nil, search from the parent directory of the detected project root."
  :type 'boolean
  :group 'repo-grep)

(defcustom repo-grep-subfolder nil
  "Optional subfolder under the project root to start the search from.
Ignored when using `repo-grep-multi'."
  :type '(choice (const :tag "None" nil)
                 (string :tag "Subfolder name"))
  :group 'repo-grep)

;;;###autoload
(defun repo-grep-set-subfolder ()
  "Interactively set `repo-grep-subfolder'."
  (interactive)
  (let* ((root (or (vc-root-dir) default-directory))
         (selected-dir (read-directory-name "Select subfolder: " root nil t)))
    (setq repo-grep-subfolder (file-relative-name selected-dir root))
    (message "Search restricted to: %s" repo-grep-subfolder)))

;;;###autoload
(defun repo-grep-set-subfolder-from-dired ()
  "Set `repo-grep-subfolder` based on the current directory in a Dired buffer."
  (interactive)
  (unless (derived-mode-p 'dired-mode)
    (error "This command must be run from a Dired buffer"))
  (let* ((root (or (vc-root-dir) default-directory))
         (dir (dired-get-file-for-visit)))
    (unless (file-directory-p dir)
      (error "Selected item is not a directory"))
    (setq repo-grep-subfolder (file-relative-name dir root))
    (message "Search restricted to: %s" repo-grep-subfolder)))

(defcustom repo-grep-case-sensitive nil
  "If non-nil, perform case-sensitive searches."
  :type 'boolean
  :group 'repo-grep)

;;;###autoload
(defun repo-grep-set-case-sensitivity ()
  "Interactively toggle `repo-grep-case-sensitive' between ON and OFF."
  (interactive)
  (let* ((options '(("ON" . t) ("OFF" . nil)))
         (current (if repo-grep-case-sensitive "ON" "OFF"))
         (choice (completing-read
                  (format "Case-sensitive search is currently %s. Choose new value: " current)
                  (mapcar #'car options)
                  nil t)))
    (setq repo-grep-case-sensitive (cdr (assoc choice options)))
    (message "Case-sensitive search is now %s"
             (if repo-grep-case-sensitive "ENABLED" "DISABLED"))))

(defcustom repo-grep-ignore-binary t
  "If non-nil, grep will ignore binary files using '--binary-files=without-match'."
  :type 'boolean
  :group 'repo-grep)

;;;###autoload
(defun repo-grep-set-ignore-binary ()
  "Interactively toggle `repo-grep-ignore-binary' between ON and OFF."
  (interactive)
  (let* ((options '(("ON" . t) ("OFF" . nil)))
         (current (if repo-grep-ignore-binary "ON" "OFF"))
         (choice (completing-read
                  (format "Ignore binary files is currently %s. Choose new value: " current)
                  (mapcar #'car options)
                  nil t)))
    (setq repo-grep-ignore-binary (cdr (assoc choice options)))
    (message "Ignore binary files is now %s"
             (if repo-grep-ignore-binary "ENABLED" "DISABLED"))))

(defcustom repo-grep-rg-use-gitignore nil
  "If non-nil, rg respects .gitignore and similar ignore files.
When nil, passes --no-ignore to rg for complete search coverage."
  :type 'boolean
  :group 'repo-grep)

;;;###autoload
(defun repo-grep-set-rg-use-gitignore ()
  "Interactively toggle `repo-grep-rg-use-gitignore' between ON and OFF."
  (interactive)
  (let* ((options '(("ON" . t) ("OFF" . nil)))
         (current (if repo-grep-rg-use-gitignore "ON" "OFF"))
         (choice (completing-read
                  (format "Use .gitignore is currently %s. Choose new value: " current)
                  (mapcar #'car options)
                  nil t)))
    (setq repo-grep-rg-use-gitignore (cdr (assoc choice options)))
    (message "Use .gitignore is now %s"
             (if repo-grep-rg-use-gitignore "ENABLED" "DISABLED"))))

(defcustom repo-grep-backend 'grep
  "Search backend to use: either `grep' (default) or `rg' (ripgrep).
ripgrep must be installed and available on PATH when using `rg'."
  :type '(choice (const :tag "grep" grep)
                 (const :tag "rg (ripgrep)" rg))
  :group 'repo-grep)

;;;###autoload
(defun repo-grep-set-backend ()
  "Interactively select the search backend for `repo-grep'.
Choose between `grep' (default) and `rg' (ripgrep).
ripgrep must be installed and available on PATH when selecting `rg'."
  (interactive)
  (let* ((options '(("grep" . grep) ("rg" . rg)))
         (current (symbol-name repo-grep-backend))
         (choice (completing-read
                  (format "Search backend is currently %s. Choose new value: " current)
                  (mapcar #'car options)
                  nil t)))
    (setq repo-grep-backend (cdr (assoc choice options)))
    (message "Search backend is now %s"
             (symbol-name repo-grep-backend))))

(defcustom repo-grep-new-buffer nil
  "If non-nil, each search opens a fresh buffer instead of reusing *grep*."
  :type 'boolean
  :group 'repo-grep)

;;;###autoload
(defun repo-grep-set-new-buffer ()
  "Interactively toggle `repo-grep-new-buffer' between ON and OFF.
When ON, each search opens a fresh *grep* buffer, leaving previous
results intact."
  (interactive)
  (let* ((options '(("ON" . t) ("OFF" . nil)))
         (current (if repo-grep-new-buffer "ON" "OFF"))
         (choice (completing-read
                  (format "New buffer per search is currently %s. Choose new value: " current)
                  (mapcar #'car options)
                  nil t)))
    (setq repo-grep-new-buffer (cdr (assoc choice options)))
    (message "New buffer per search is now %s"
             (if repo-grep-new-buffer "ENABLED" "DISABLED"))))

;;;###autoload
(defun repo-grep (&rest args)
  "Run a project-wide grep search from the detected repository root.

This command performs a recursive grep search starting from the
project root (Git, SVN, or current directory).
The default search term is the symbol under the cursor, which can be edited
interactively.

Optional keyword arguments in ARGS:
  :exclude-ext  List of file extensions to exclude (e.g., `(\".log\" \".tmp\")).
  :include-ext  List of file extensions to include (e.g., `(\".el\" \".py\")).
  :left-regex   Regex pattern to prepend to the search term.
  :right-regex  Regex pattern to append to the search term.

Search respects `repo-grep-case-sensitive' and can be scoped to
a subfolder via `repo-grep-subfolder'.

Results are displayed in a dedicated grep buffer with clickable links."
  (interactive)
  (apply #'repo-grep--internal args))

;;;###autoload
(defun repo-grep-multi (&rest args)
  "Recursively grep across sibling repos/folders under a common parent folder.

This command performs a recursive grep search across all sibling
directories under the parent of the current project root.  It is
useful for searching across multiple related repositories or
projects at once.

Optional keyword arguments in ARGS:
  :exclude-ext  List of file extensions to exclude (e.g., `(\".log\" \".tmp\")).
  :include-ext  List of file extensions to include (e.g., `(\".el\" \".py\")).
  :left-regex   Regex pattern to prepend to the search term.
  :right-regex  Regex pattern to append to the search term.

Search respects `repo-grep-case-sensitive' and ignores
`repo-grep-subfolder' since the search spans multiple roots.

Results are displayed in a dedicated grep buffer with clickable links."
  (interactive)
  (let ((repo-grep-from-folder-above t))
    (apply #'repo-grep--internal args)))

(defun repo-grep--internal (&rest args)
  "Perform a recursive grep search with optional keyword arguments.
Handles custom exclusions, regex-based matching, and project root detection.

Optional keyword arguments in ARGS:
  :exclude-ext   List of file extensions to exclude.
  :include-ext   List of file extensions to include.
  :left-regex    Regex pattern to prepend to the search term.
  :right-regex   Regex pattern to append to the search term.

Respects `repo-grep-new-buffer': when non-nil, results are opened in a
fresh buffer rather than reusing the existing *grep* buffer."
  (let* ((exclude-ext (plist-get args :exclude-ext))
         (include-ext (plist-get args :include-ext))
         (left-regex  (repo-grep--sanitise-regex (plist-get args :left-regex)))
         (right-regex (repo-grep--sanitise-regex (plist-get args :right-regex))))

    ;; Validate arguments
    (when (and exclude-ext (not (listp exclude-ext)))
      (error "EXCLUDE-EXT must be a list of strings"))
    (when (and include-ext (not (listp include-ext)))
      (error "INCLUDE-EXT must be a list of strings"))

    ;; Extract symbol under cursor or use fallback
    (let* ((symbol-at-point (thing-at-point 'symbol t))
           (symbol-at-point (or symbol-at-point ""))
           (default-term symbol-at-point)
           (prompt (concat "grep for ("
                           (or left-regex "")
                           symbol-at-point
                           (or right-regex "")
                           "): "))
           (input (read-string prompt nil nil symbol-at-point))
           (sanitised-input (repo-grep--sanitise-input input))
           (search-term (if (string-empty-p sanitised-input) default-term sanitised-input))
           (search-pattern (concat (or left-regex "") search-term (or right-regex "")))
           (folder (repo-grep--find-folder)))

      ;; Ensure a valid folder before executing grep
      (unless (and folder (not (string-empty-p folder)))
        (error "Could not determine project root"))

      (let ((default-directory folder))
        (compilation-start
         (if (eq repo-grep-backend 'rg)
             (repo-grep--build-rg-command search-pattern include-ext exclude-ext)
           (repo-grep--build-grep-command search-pattern include-ext exclude-ext))
         'grep-mode
         (when repo-grep-new-buffer
           (lambda (_) (generate-new-buffer-name "*grep*"))))))))

(defun repo-grep--build-file-flags (include-ext exclude-ext)
  "Build a list of quoted --include and --exclude flag strings for grep.
INCLUDE-EXT and EXCLUDE-EXT are lists of file extension strings.
Returns a list of shell-quoted flag strings, or nil if both are empty.
The * wildcard is handled separately in `repo-grep--internal'."
  (let ((parts '()))
    ;; Add include patterns
    (when include-ext
      (dolist (ext include-ext)
        (push (shell-quote-argument
               (format "--include=*%s" (repo-grep--sanitise-ext ext)))
              parts)))
    ;; Add exclude patterns
    (when exclude-ext
      (dolist (ext exclude-ext)
        (push (shell-quote-argument
               (format "--exclude=*%s" (repo-grep--sanitise-ext ext)))
              parts)))
    (nreverse parts)))

(defun repo-grep--build-rg-globs (include-ext exclude-ext)
  "Build a list of --glob flag strings for rg from INCLUDE-EXT and EXCLUDE-EXT.
INCLUDE-EXT and EXCLUDE-EXT are lists of file extension strings.
Include patterns become --glob=*.ext, exclude patterns become --glob=!*.ext.
Extensions are expected to include the leading dot (e.g. \".el\")."
  (let ((parts '()))
    (when include-ext
      (dolist (ext include-ext)
        (push (format "--glob=%s"
                      (shell-quote-argument
                       (format "*%s" (repo-grep--sanitise-ext ext))))
              parts)))
    (when exclude-ext
      (dolist (ext exclude-ext)
        (push (format "--glob=%s"
                      (shell-quote-argument
                       (format "!*%s" (repo-grep--sanitise-ext ext))))
              parts)))
    (nreverse parts)))

(defun repo-grep--build-grep-command (search-pattern include-ext exclude-ext)
  "Build the grep shell command string for SEARCH-PATTERN.
INCLUDE-EXT and EXCLUDE-EXT are lists of file extension strings."
  (let ((file-flags (repo-grep--build-file-flags include-ext exclude-ext))
        (file-glob  (unless include-ext '("*")))
        (case-flag  (if repo-grep-case-sensitive "" "-i"))
        (binary-flag (if repo-grep-ignore-binary "--binary-files=without-match" "")))
    (mapconcat #'identity
               (append (list "grep" "--color" "-nr"
                             case-flag
                             binary-flag)
                       file-flags
                       (list "--"
                             (shell-quote-argument search-pattern))
                       file-glob)
               " ")))

(defun repo-grep--build-rg-command (search-pattern include-ext exclude-ext)
  "Build the rg shell command string for SEARCH-PATTERN.
INCLUDE-EXT and EXCLUDE-EXT are lists of file extension strings.
Colour is applied to matched text only, leaving filename and line number
as plain text so that `grep-mode' can parse them as clickable links.
Requires ripgrep (rg) to be installed and available on PATH."
  (unless (executable-find "rg")
    (error "ripgrep (rg) not found on PATH; install it or set `repo-grep-backend' to 'grep"))
  (let ((globs         (repo-grep--build-rg-globs include-ext exclude-ext))
        (case-flag     (when (not repo-grep-case-sensitive) "-i"))
        (binary-flag   (when (not repo-grep-ignore-binary) "--binary"))
        (no-ignore-flag (when (not repo-grep-rg-use-gitignore) "--no-ignore")))
    (mapconcat #'identity
               (delq nil
                     (append (list "rg" "--color=always"
                                   "--colors" "path:none"
                                   "--colors" "line:none"
                                   "--no-heading" "--with-filename" "-n")
                             (when case-flag      (list case-flag))
                             (when binary-flag    (list binary-flag))
                             (when no-ignore-flag (list no-ignore-flag))
                             globs
                             (list "--"
                                   (shell-quote-argument search-pattern)
                                   ".")))
               " " )))

(defun repo-grep--find-folder ()
  "Determine the appropriate folder to run grep in.
Uses Emacs' built-in VCS detection and falls back to `default-directory'.
If `repo-grep-subfolder' is set and valid, append it to the root."
  (let ((folder (or (vc-root-dir)
                    default-directory)))
    (when repo-grep-from-folder-above
      (setq folder (expand-file-name ".." folder)))
    (when (and repo-grep-subfolder (not repo-grep-from-folder-above))
      (let ((sub (expand-file-name repo-grep-subfolder folder)))
        (if (file-directory-p sub)
            (setq folder sub)
          (error "Subfolder '%s' does not exist under project root" repo-grep-subfolder))))
    (unless (and folder (file-directory-p folder))
      (error "Could not determine a valid project root folder"))
    folder))

(defun repo-grep--sanitise-input (input)
  "Validate INPUT for shell safety while allowing some programming characters."
  (when (string-match-p "[`&;|<>\"'\\]" input)
    (error "Search input contains potentially dangerous characters: %s" input))
  input)

(defun repo-grep--sanitise-regex (regex)
  "Validate REGEX contain only safe characters for shell execution."
  (when (and regex (not (stringp regex)))
    (error "REGEX must be a string or nil"))
  (when (and regex (string-match-p "[`$&;|<>\"'\\\\]" regex))
    (error "Regex contains potentially dangerous characters: %s" regex))
  regex)

(defun repo-grep--sanitise-ext (ext)
  "Ensure EXT only contain safe characters for shell globbing."
  (if (string-match-p "[^A-Za-z0-9._~-]" ext)
      (error "Unsafe character in file extension: %s" ext)
    ext))

(defun repo-grep-filter (regexp)
  "Clone the current grep buffer and filter it to lines matching REGEXP.
The original buffer is left intact and links in the filtered
buffer navigate directly to source files."
  (interactive "sFilter grep results: ")
  (let* ((clone (clone-buffer nil t)))
    (with-current-buffer clone
      (let ((inhibit-read-only t))
        (keep-lines regexp (point-min) (point-max))))))

(defun repo-grep-setup-keybindings ()
  "Set up optional repo-grep keybindings in grep-mode-map."
  (with-eval-after-load 'grep
    (define-key grep-mode-map (kbd "f") #'repo-grep-filter)))

(provide 'repo-grep)

;;; repo-grep.el ends here
