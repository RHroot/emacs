;; ==============================================================================
;; 1. FOUNDATION: Package Manager & Custom Settings
;; ==============================================================================

;; --- Redirect Custom Settings (Keep init.el clean) ---
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(unless (file-exists-p custom-file)
  (write-region "" nil custom-file))
(load custom-file 'noerror 'nomessage)

;; --- Package Manager Setup ---
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; --- Use-Package Setup ---
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; 1. Define & auto-create directories (idempotent)
(defvar my/backup-dir (expand-file-name "~/.emacs-backups/"))
(defvar my/undo-dir (expand-file-name "~/.emacs-undo/"))
(dolist (dir (list my/backup-dir my/undo-dir))
  (make-directory dir t))

;; 2. Timestamped backups
(setq backup-by-copying t)
(setq make-backup-file-name-function
      (lambda (file)
        (expand-file-name
         (format "%s.%s~"
                 (file-name-nondirectory file)
                 (format-time-string "%Y%m%d_%H%M%S"))
         my/backup-dir)))

;; 3. Persistent undo (survives restarts/months)
(use-package undo-tree
  :ensure t
  :init
  (global-undo-tree-mode 1)
  (setq undo-tree-auto-save-history t
        undo-tree-history-directory-alist `(("." . ,my/undo-dir)))
  :config
  (setq undo-tree-history-compressor 'gzip))

;; ==============================================================================
;; 2. CORE UI & BEHAVIOR
;; ==============================================================================

;; --- Appearance ---
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(electric-pair-mode 1)
(global-font-lock-mode 1)
(global-display-line-numbers-mode)
(which-key-mode 1)
(setq display-line-numbers-type 'relative)

;; --- Theme ---
(add-to-list 'custom-theme-load-path "~/.emacs.d/lisp/")
(load-theme 'vesper t)

;; --- Theme Switcher ---
(defun my/theme-picker ()
  "Interactive theme switcher with live preview.
  Navigate: n/j/↓ or p/k/↑
  Confirm: RET or SPC
  Cancel: ESC or q"
  (interactive)
  (let* ((themes '(rose-pine nord gruber-darker tokyo-night dracula catppuccin-mocha
			     one-dark ayu-dark poimandres night-owl vesper))
         (len (length themes))
         (idx 0)
         (orig-theme (car custom-enabled-themes))
         (current (nth idx themes))
         (done nil))
    (load-theme current t)
    (sit-for 0)
    (while (not done)
      (let ((key (read-key (format "🎨 Theme: %-20s | n/j↓ p/k↑ | RET/SPC confirm | ESC/q cancel "
                                   (symbol-name current)))))
        (cond
         ((memq key '(?n ?j down [down])) (setq idx (mod (1+ idx) len)))
         ((memq key '(?p ?k up [up]))     (setq idx (mod (1- idx) len)))
         ((memq key '(13 32 return space)) (setq done t))
         ((memq key '(27 ?q escape [escape])) (setq done 'cancel))
         (t nil))
        (unless done
          (setq current (nth idx themes))
          (load-theme current t)
          (sit-for 0))))
    (if (eq done t)
        (message "✅ Theme set to: %s" current)
      (disable-theme current)
      (when orig-theme (load-theme orig-theme t))
      (message "↩️ Canceled. Reverted to: %s" orig-theme))))
(global-set-key (kbd "C-c t") #'my/theme-picker)

;; --- Frame & Font ---
(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font-18"))

;; --- Basic Behavior ---
(setq dired-kill-when-opening-new-dired-buffer t)
(put 'dired-find-alternate-file 'disabled nil)
(setq scroll-step 1
      scroll-margin 8
      scroll-conservatively 101)
(setq vc-follow-symlinks t)
(setq tab-width 4
      indent-tabs-mode nil
      make-backup-files nil
      inhibit-startup-screen t
      gc-cons-threshold (* 50 1000 1000))

;; ==============================================================================
;; 3. COMPLETION SYSTEM (IDO + ICOMPLETE)
;; ==============================================================================

;; --- IDO for Files/Buffers ---
(ido-mode 1)
(setq ido-enable-flex-matching t)
(setq ido-everywhere t)

;; --- Icomplete Vertical for M-x/Help ---
(icomplete-vertical-mode 1)
(setq icomplete-separator "\n")
(setq icomplete-max-delayed-matches 50)

;; ==============================================================================
;; 4. GLOBAL KEY BINDINGS & UTILITIES
;; ==============================================================================

;; --- Navigation ---
(global-set-key (kbd "C-c C-n") 'next-buffer) ;; Open the Next Buffer
(global-set-key (kbd "C-c C-p") 'previous-buffer) ;; open the Previous Buffer
(global-set-key (kbd "C-c C-o") 'ffap) ;; Open the file path under the cursor
(global-set-key (kbd "C-c k") 'my/kill-all-buffers) ;; Kill all the buffers except the one you are on
(global-set-key (kbd "C-c C-r") 'recentf-open-files) ;; Open Recent Files
(global-set-key (kbd "M-;") 'comment-line) ;; To comment files default mapped to 'comment-dwim'
(global-set-key (kbd "C-c e") 'eval-buffer) ;; To eval the current buffer

(defun my/kill-all-buffers ()
  "Kill all buffers except the current one."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list))))

;; --- Editing Utilities ---
(global-set-key (kbd "C-,") 'my/duplicate-line)

(defun my/duplicate-line ()
  "Duplicate current line"
  (interactive)
  (let ((column (- (point) (line-beginning-position)))
        (line (string-trim-right (thing-at-point 'line t))))
    (move-end-of-line 1)
    (newline)
    (insert line)
    (move-beginning-of-line 1)
    (forward-char column)))

;; --- For Nix indenting ---
(defun my/nix-indent-buffer ()
  "Indent the current Nix buffer."
  (interactive)
  (indent-region (point-min) (point-max)))

;; --- Project Management ---
(global-set-key (kbd "C-c p f") 'project-find-file)
(global-set-key (kbd "C-c p g") 'project-search)
(global-set-key (kbd "C-c p d") 'project-dired)
(global-set-key (kbd "C-c p !") 'project-compile)

;; --- Compilation ---
(global-set-key (kbd "C-c c c") 'compile)

(defun my-set-compile-command ()
  "Set compile command dynamically based on the current file."
  (let ((file (buffer-file-name)))
    (when file
      (let ((name (file-name-nondirectory (file-name-sans-extension file))))
        (setq-local compile-command
                    (cond
                     ((derived-mode-p 'python-mode)
                      (format "python3 %s" file))
                     ((derived-mode-p 'simpc-mode)
                      (if (string-match-p "\\.cpp\\|\\.cc\\|\\.hpp\\|\\.hh" file)
                          (format "g++ -Wall -o %s %s && ./%s" name file name)
                        (format "gcc -Wall -o %s %s && ./%s" name file name)))
                     (t "make -k")))))))
(add-hook 'prog-mode-hook #'my-set-compile-command)

;; --- Built-in Quality of Life ---
(save-place-mode 1)       ;; Remember cursor position in files
(recentf-mode 1)          ;; Track recently opened files
(setq recentf-max-menu-items 20)

;; ==============================================================================
;; 5. LANGUAGE MODES & LSP (EGLOT)
;; ==============================================================================

;; --- Simpc Mode (Lightweight C/C++) ---
(add-to-list 'load-path "~/.emacs.d/lisp/")
(require 'simpc-mode)

(dolist (ext '("\\.c\\'" "\\.h\\'" "\\.cpp\\'" "\\.hpp\\'" "\\.cc\\'" "\\.hh\\'"))
  (add-to-list 'auto-mode-alist (cons ext 'simpc-mode)))

(add-hook 'simpc-mode-hook #'eglot-ensure)
(add-hook 'simpc-mode-hook
          (lambda ()
            (setq-local compile-command
                        (let ((file (buffer-file-name))
                              (name (file-name-nondirectory (file-name-sans-extension (buffer-file-name)))))
                          (if file
                              (if (string-match-p "\\.cpp\\|\\.cc\\|\\.hpp\\|\\.hh" file)
                                  (format "g++ -Wall -o %s %s && ./%s" name file name)
                                (format "gcc -Wall -o %s %s && ./%s" name file name))
                            "make -k")))))

;; --- Python ---
(add-hook 'python-mode-hook #'eglot-ensure)

;; --- Nix ---
(use-package nix-mode
  :mode "\\.nix\\'"
  :config
  (define-key nix-mode-map (kbd "C-c f") #'my/nix-indent-buffer))

;; --- Web/Config (JSON, CSS, JS, TS, MD, YAML) ---

;; 1. Completion (Eglot)
(dolist (hook '(json-mode-hook css-mode-hook js-mode-hook typescript-mode-hook))
  (add-hook hook #'eglot-ensure))

;; 2. Formatting (Prettierd)
(defun my/prettierd-format-buffer ()
  "Format current buffer using prettierd."
  (interactive)
  (let ((file-name (buffer-file-name)))
    (if file-name
        (condition-case nil
            (call-process-region (point-min) (point-max) "prettierd" t t nil "--stdin-filepath" file-name)
          (error (message "Prettierd failed or not found")))
      (message "Buffer has no file name"))))

(dolist (hook '(json-mode-hook css-mode-hook js-mode-hook typescript-mode-hook markdown-mode-hook yaml-mode-hook))
  (add-hook hook
            (lambda ()
              (local-set-key (kbd "C-c f") #'my/prettierd-format-buffer))))

;; --- Emacs Lisp ---
(defun my/format-elisp-buffer ()
  "Format the current Emacs Lisp buffer using standard indentation."
  (interactive)
  (indent-region (point-min) (point-max)))

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c f") #'my/format-elisp-buffer)))

;; ==============================================================================
;; 6. TOOLS & FINAL TOUCHES
;; ==============================================================================

;; --- Magit (Git) ---
(use-package magit
  :bind (("C-x g" . magit-status)))

;; --- Eglot Global Configuration ---
(with-eval-after-load 'eglot
  (define-key eglot-mode-map (kbd "C-c f") 'eglot-format-buffer)
  (define-key eglot-mode-map (kbd "C-c r n") 'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c c a") 'eglot-code-actions)
  (add-to-list 'eglot-server-programs '(simpc-mode . ("clangd")))
  (add-to-list 'eglot-server-programs '(python-mode . ("ruff" "server"))))

;; --- Completion ---
(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.0)
  (corfu-quit-at-boundary 'separator)
  (corfu-echo-documentation 0.25)
  (corfu-preview-current 'insert)
  (corfu-preselect-first nil)
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  :config
  ;; Keybindings: use vectors for special keys, strings for others
  (define-key corfu-map (kbd "M-SPC") #'corfu-insert-separator)
  (define-key corfu-map (kbd "RET") nil)
  (define-key corfu-map (kbd "TAB") #'corfu-next)
  (define-key corfu-map (kbd "S-TAB") #'corfu-previous)
  (define-key corfu-map (kbd "S-<return>") #'corfu-insert)

  ;; Eshell: disable auto-corfu, stricter quit behavior
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-quit-at-boundary t
                          corfu-quit-no-match t
                          corfu-auto nil)
              (corfu-mode))))
