;; --- Bootstrap straight.el ---
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; --- Tell use-package to use straight.el ---
(straight-use-package 'use-package)
(setq use-package-always-ensure t) ;; Still auto-installs, but via straight now
(setq straight-use-package-by-default t)

;; --- UI & Basic Settings ---
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(electric-pair-mode 1)

(setq dired-kill-when-opening-new-dired-buffer t)
(put 'dired-find-alternate-file 'disabled nil)

(set-frame-parameter (selected-frame) 'alpha '(80 . 60))
(add-to-list 'default-frame-alist '(alpha . (80 . 60)))

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode)

(setq scroll-step 1
      scroll-margin 8
      scroll-conservatively 101)

(setq vc-follow-symlinks t)

(setq tab-width 4
      indent-tabs-mode nil
      make-backup-files nil
      inhibit-startup-screen t
      gc-cons-threshold (* 50 1000 1000))

(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font-18"))

;; --- Key Bindings ---
(global-set-key (kbd "C-c C-n") 'next-buffer)
(global-set-key (kbd "C-c C-p") 'previous-buffer)
(global-set-key (kbd "C-c C-o") 'ffap)

;; --- Smart Compile Command ---
(defun my-set-compile-command ()
  "Set compile command dynamically based on the current file."
  (let ((file (buffer-file-name)))
    (when file
      (let ((name (file-name-nondirectory (file-name-sans-extension file))))
        (setq-local compile-command
                    (cond
                     ((derived-mode-p 'python-mode) 
                      (format "python3 %s" file))
                     ((derived-mode-p 'c-mode) 
                      (format "gcc -Wall -o %s %s && ./%s" name file name))
                     ((derived-mode-p 'c++-mode) 
                      (format "g++ -Wall -o %s %s && ./%s" name file name))
                     (t "make -k")))))))

;; Run this function every time a programming mode starts
(add-hook 'prog-mode-hook #'my-set-compile-command)

;; Bind C-c r to compile
(global-set-key (kbd "C-c r") 'compile)

;; --- Theme ---
(use-package gruber-darker-theme
  :config
  (load-theme 'gruber-darker t))

;; --- Magit---
(use-package magit
  :ensure t ;; Straight will try to clone and build it
  :bind (("C-x g" . magit-status)))

;; --- Completion Stack ---
(use-package vertico
  :init (vertico-mode))

(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil))

(use-package marginalia
  :init (marginalia-mode))

(use-package corfu
  :init (global-corfu-mode)
  :config
  (setq corfu-auto t
        corfu-cycle t
        corfu-preview-current t))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))

;; --- Universal Prettierd Formatter ---
(defun my/prettierd-format-buffer ()
  "Format current buffer using prettierd."
  (interactive)
  (let ((file-name (buffer-file-name)))
    (if file-name
        ;; Call prettierd with the file path so it knows which parser to use
        (call-process-region (point-min) (point-max) "prettierd" t t nil "--stdin-filepath" file-name)
      (message "Buffer has no file name"))))

;; --- Native LSP (Eglot) ---
(with-eval-after-load 'eglot
  (define-key eglot-mode-map (kbd "C-c f") 'eglot-format-buffer)
  (add-to-list 'eglot-server-programs '(python-mode . ("ruff" "server"))))
(add-hook 'c-mode-hook #'eglot-ensure)
(add-hook 'c++-mode-hook #'eglot-ensure)
(add-hook 'python-mode-hook #'eglot-ensure)

;; 2. Web/Config Files: Use Prettierd for formatting
(dolist (mode '(json-mode css-mode js-mode typescript-mode markdown-mode yaml-mode))
  (add-hook mode
            (lambda ()
              (local-set-key (kbd "C-c f") #'my/prettierd-format-buffer))))

;; --- Formatting for Emacs Lisp ---
(defun my/format-elisp-buffer ()
  "Format the current Emacs Lisp buffer using standard indentation."
  (interactive)
  (indent-region (point-min) (point-max)))

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c f") #'my/format-elisp-buffer)))

;; --- Ligatures ---
(use-package ligature
  :config
  (ligature-set-ligatures
   'prog-mode
   '("==" "!=" "===" "!=="
     "->" "<-" "=>" "<="
     ">>" "<<" ">>=" "<<="
     "&&" "||" "++" "--"
     "**" "//" "/*" "*/"))
  (global-ligature-mode t))
