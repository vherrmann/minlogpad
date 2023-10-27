(require 'minlog)
(require 'minlog-unicode)

(run-minlog)

(setq-default indent-tabs-mode nil)

(if (not (display-graphic-p))
    (progn (set-terminal-parameter nil 'background-mode 'light)
	   (load-theme 'tsdh-light)
	   (run-with-idle-timer 600 t 'kill-emacs)))

(custom-set-variables
 '(xterm-mouse-mode t)
 '(inhibit-startup-screen t))

(run-with-idle-timer 60 t '(lambda () (save-some-buffers t nil)))

(require 'evil)
(setq evil-default-state 'emacs)
(setq evil-want-fine-undo 't)
(evil-mode 1)
