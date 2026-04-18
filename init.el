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

;; ==============================================================================
;; 2. CORE UI & BEHAVIOR
;; ==============================================================================

;; --- Appearance & Theme ---
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(electric-pair-mode 1)
(global-font-lock-mode 1)
(global-display-line-numbers-mode)
(setq display-line-numbers-type 'relative)

;; --- Frame & Font ---
(set-frame-parameter (selected-frame) 'alpha '(80 . 60))
(add-to-list 'default-frame-alist '(alpha . (80 . 60)))
(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font-16"))

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
(global-set-key (kbd "C-c r") 'compile)

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

;; --- Load Custom Theme from File ---
(let ((theme-file "~/.emacs.d/lisp/gruber-darker-theme.el"))
  (when (file-exists-p theme-file)
    (load-file theme-file)
    (load-theme 'gruber-darker t)))

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
(dolist (mode '(json-mode css-mode js-mode))
  (add-hook mode #'eglot-ensure))

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

(dolist (mode '(json-mode css-mode js-mode typescript-mode markdown-mode yaml-mode))
  (add-hook mode
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
  (add-to-list 'eglot-server-programs '(simpc-mode . ("clangd")))
  (add-to-list 'eglot-server-programs '(python-mode . ("ruff" "server"))))

;; --- Ligatures (Prettify Symbols) ---
(global-prettify-symbols-mode 1)
(add-hook 'prog-mode-hook
          (lambda ()
            (push '("->" . ?→) prettify-symbols-alist)
            (push '("=>" . ?⇒) prettify-symbols-alist)
            (push '("<-" . ?←) prettify-symbols-alist)
            (push '("!=" . ?≠) prettify-symbols-alist)
            (push '("==" . ?≡) prettify-symbols-alist)
            (prettify-symbols-mode 1)))
