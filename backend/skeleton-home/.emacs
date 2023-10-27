(setq-default indent-tabs-mode nil)

(if (not (display-graphic-p))
    (progn (set-terminal-parameter nil 'background-mode 'light)
	   (load-theme 'tsdh-light)
	   (run-with-idle-timer 600 t 'kill-emacs)))

(custom-set-variables
 '(xterm-mouse-mode t)
 '(inhibit-startup-screen t))

(run-with-idle-timer 60 t (lambda () (save-some-buffers t nil)))

(require 'evil)
(setq evil-default-state 'emacs)
(setq evil-want-fine-undo 't)
(evil-mode 1)

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
