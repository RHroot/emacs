(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

(ido-mode 1)
(ido-everywhere 1)

(global-display-line-numbers-mode)

(setq tab-width 4
      scroll-step 1
      scroll-margin 8
      indent-tabs-mode nil
      make-backup-files nil
      inhibit-startup-screen t
      scroll-conservatively 101
      gc-cons-threshold (* 50 1000 1000)
      display-line-numbers-type 'relative)

(add-to-list 'default-frame-alist `(font . "JetBrainsMono Nerd Font-20"))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(use-package gruber-darker-theme)
(load-theme 'gruber-darker t)

(add-to-list 'load-path "~/.emacs.local/")
(require 'simpc-mode)
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode))

(use-package ligature
  :config
  (ligature-set-ligatures 'prog-mode
   '("==" "!=" "===" "!=="
     "->" "<-" "=>" "<="
     ">>" "<<" ">>=" "<<="
     "&&" "||" "++" "--"
     "**" "//" "/*" "*/"))
  (global-ligature-mode t))
