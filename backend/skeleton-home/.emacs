(setq-default indent-tabs-mode nil)

(if (not (display-graphic-p))
    (progn (set-terminal-parameter nil 'background-mode 'light)
	   (load-theme 'tsdh-light)
	   (run-with-idle-timer 600 t 'kill-emacs)))

(custom-set-variables
 '(xterm-mouse-mode t)
 '(inhibit-startup-screen t))

(defun open-minlog-tutorial () (interactive) (find-file "~/doc/tutor.pdf"))
(defun open-minlog-tutorial-examples () (interactive) (find-file "~/examples/tutor.scm"))
(defun open-minlog-examples () (interactive) (find-file "~/examples"))
(defun open-minlog-ref () (interactive) (find-file "~/doc/ref.pdf"))
(define-key menu-bar-help-menu [sep9] '("--"))
(define-key menu-bar-help-menu [f] '(menu-item "Minlog Tutorial" open-minlog-tutorial))
(define-key menu-bar-help-menu [g] '(menu-item "Minlog Tutorial Examples" open-minlog-tutorial-examples))
(define-key menu-bar-help-menu [h] '(menu-item "Minlog Examples" open-minlog-examples))
(define-key menu-bar-help-menu [i] '(menu-item "Minlog Reference" open-minlog-ref))

(run-with-idle-timer 60 t (lambda () (save-some-buffers t nil)))

(setq evil-toggle-key "M-o")
(require 'evil)
(setq evil-default-state 'emacs)
(setq evil-want-fine-undo 't)
(evil-mode 1)

(require 'which-key)
(which-key-mode)

(require 'pdf-tools)
(pdf-tools-install-noverify)
(add-hook 'pdf-view-mode-hook
          (lambda ()
            (blink-cursor-mode -1)))

(require 'undo-fu)
(global-unset-key (kbd "C-z"))
(global-set-key (kbd "C-z")   'undo-fu-only-undo)
(global-set-key (kbd "C-S-z") 'undo-fu-only-redo)

;; adapted from minlog source
(defun run-minlog (&optional filename)
  ;; Enable utf-8
  (setq default-enable-multibyte-characters t)
  (condition-case nil
      (set-language-environment "Greek")
    (error nil))
  (condition-case nil
      (set-language-environment "utf-8")
    (error nil))
  (set-input-method "TeX")

  ;; MINLOG directory
  (setq minlogpath (getenv "MINLOGPATH"))

  (setq scheme "scheme")

  (setq heapload (concat minlogpath "/init.scm"))

  (split-window nil nil t)
  (with-selected-window (next-window)
    (run-scheme (concat scheme " " heapload))))

(require 'minlog-unicode)

(run-minlog)
