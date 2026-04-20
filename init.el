;; Custom Files and Directories

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(unless (file-exists-p custom-file)
  (write-region "" nil custom-file))
(load custom-file 'noerror 'nomessage)

;; Basic UI Tweaks

(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(electric-pair-mode 1)
(global-font-lock-mode 1)
(global-display-line-numbers-mode)
(which-key-mode 1)
(setq display-line-numbers-type 'relative)
(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font-18"))

;; Basic Behavour Tweaks

(setq tab-width 4
        scroll-step 1
        scroll-margin 8
        indent-tabs-mode nil
        vc-follow-symlinks t
        make-backup-files nil
        inhibit-startup-screen t
        scroll-conservatively 101
        gc-cons-threshold (* 50 1000 1000)
        dired-kill-when-opening-new-dired-buffer t)
  (put 'dired-find-alternate-file 'disabled nil)

(save-place-mode 1)
(recentf-mode 1)
(setq recentf-max-menu-items 20)

;; Global Keybinds

(global-set-key (kbd "C-c C-o") 'ffap)
(global-set-key (kbd "C-c C-r") 'recentf-open-files)
(global-set-key (kbd "M-;") 'comment-line)
(global-set-key (kbd "C-c C-e") 'eval-buffer)
(global-set-key (kbd "C-c p f") 'project-find-file)
(global-set-key (kbd "C-c p g") 'project-search)
(global-set-key (kbd "C-c p d") 'project-dired)
(global-set-key (kbd "C-c p !") 'project-compile)
(global-set-key (kbd "C-c c c") 'compile)

;; Setting up Backup with Timestamp

(defvar my/backup-dir (expand-file-name "~/.emacs-backups/"))
(dolist (dir (list my/backup-dir))
  (make-directory dir t))

(setq backup-by-copying t)
(setq make-backup-file-name-function
      (lambda (file)
        (expand-file-name
         (format "%s.%s~"
                 (file-name-nondirectory file)
                 (format-time-string "%Y%m%d_%H%M%S"))
         my/backup-dir)))

;; Custom Functions

(defun my/kill-all-buffers ()
  "Kill all buffers except the current one."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list))))
(global-set-key (kbd "C-c k") 'my/kill-all-buffers)

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
(global-set-key (kbd "C-,") 'my/duplicate-line)

(defun my/format-elisp-buffer ()
  "Format the current Emacs Lisp buffer using standard indentation."
  (interactive)
  (indent-region (point-min) (point-max)))
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c f") #'my/format-elisp-buffer)))

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

(defun my/suppress-no-match (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, but skip if message starts with \"No match\"."
  (let ((msg (car args)))
    (unless (and (stringp msg) (string-match-p "\\`No match" msg))
      (apply orig-fun args))))
(advice-add 'minibuffer-message :around #'my/suppress-no-match)

;; Org Mode

(require 'org)
(require 'ob-tangle)
(setq org-confirm-babel-evaluate nil)

(add-hook 'org-mode-hook
          (lambda ()
            (org-indent-mode 1)
            (setq org-hide-leading-stars t)
            (setq org-pretty-entities t)
            (setq org-startup-folded 'content)
            (setq org-src-fontify-natively t)
            (setq org-src-tab-acts-natively t)
            (setq org-src-preserve-indentation nil)

	    (custom-set-faces
	     '(org-level-1 ((t (:inherit outline-1 :height 1.7))))
	     '(org-level-2 ((t (:inherit outline-2 :height 1.6))))
	     '(org-level-3 ((t (:inherit outline-3 :height 1.5))))
	     '(org-level-4 ((t (:inherit outline-4 :height 1.4))))
	     '(org-level-5 ((t (:inherit outline-5 :height 1.3))))
	     '(org-level-6 ((t (:inherit outline-5 :height 1.2))))
	     '(org-level-7 ((t (:inherit outline-5 :height 1.1)))))))

;; Package Manager Setup

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Setting up good Undo

(defvar my/undo-dir (expand-file-name "~/.emacs-undo/"))
(dolist (dir (list my/undo-dir))
  (make-directory dir t))

(use-package undo-tree
  :ensure t
  :init
  (global-undo-tree-mode 1)
  (setq undo-tree-auto-save-history t
	undo-tree-history-directory-alist `(("." . ,my/undo-dir)))
  :config
  (setq undo-tree-history-compressor 'gzip))

;; maGIT

(use-package magit
  :bind (("C-x g" . magit-status)))
(use-package diff-hl
  :ensure t
  :config
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode))

;; Lsp's

(with-eval-after-load 'eglot
  (define-key eglot-mode-map (kbd "C-c f") 'eglot-format-buffer)
  (define-key eglot-mode-map (kbd "C-c r n") 'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c c a") 'eglot-code-actions)
  (add-to-list 'eglot-server-programs '(simpc-mode . ("clangd")))
  (add-to-list 'eglot-server-programs '(python-mode . ("ruff" "server"))))

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

(add-hook 'python-mode-hook #'eglot-ensure)

(defun my/nix-indent-buffer ()
  "Indent the current Nix buffer."
  (interactive)
  (indent-region (point-min) (point-max)))
(use-package nix-mode
  :mode "\\.nix\\'"
  :config
  (define-key nix-mode-map (kbd "C-c f") #'my/nix-indent-buffer))

(dolist (hook '(json-mode-hook css-mode-hook js-mode-hook typescript-mode-hook))
  (add-hook hook #'eglot-ensure))

;; Completion

(ido-mode 1)
  (setq ido-enable-flex-matching t)
  (setq ido-everywhere t)

  (icomplete-vertical-mode 1)
  (setq icomplete-separator "\n")
  (setq icomplete-max-delayed-matches 50)

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

    (define-key corfu-map (kbd "M-SPC") #'corfu-insert-separator)
    (define-key corfu-map (kbd "RET") nil)
    (define-key corfu-map (kbd "TAB") #'nil)
    (define-key corfu-map (kbd "S-TAB") #'nil)
    (define-key corfu-map (kbd "S-<return>") #'corfu-insert)

    (add-hook 'eshell-mode-hook
              (lambda ()
                (setq-local corfu-quit-at-boundary t
                            corfu-quit-no-match t
                            corfu-auto nil)
                (corfu-mode))))
  (add-hook 'git-commit-mode-hook
            (lambda ()
              (corfu-m
ode -1)
              (setq-local completion-at-point-functions nil)))

;; Load Theme

(add-to-list 'custom-theme-load-path "~/.emacs.d/lisp/")
(load-theme 'vesper t)

;; Custom Theme Switcher

(defun my/theme-picker ()
  "Interactive theme switcher with live preview.
  Navigate: n/j/↓ or p/k/↑
  Confirm: RET or SPC
  Cancel: ESC or q"
  (interactive)
  (let* ((themes '(vesper gruber-darker rose-pine catppuccin-mocha tokyo-night
			    one-dark night-owl ayu-dark nord dracula poimandres))
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
