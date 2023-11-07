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
(define-key menu-bar-help-menu [minlog-tut] '(menu-item "Minlog Tutorial" open-minlog-tutorial))
(define-key menu-bar-help-menu [minlog-tut-ex] '(menu-item "Minlog Tutorial Examples" open-minlog-tutorial-examples))
(define-key menu-bar-help-menu [minlog-ex] '(menu-item "Minlog Examples" open-minlog-examples))
(define-key menu-bar-help-menu [minlog-ref] '(menu-item "Minlog Reference" open-minlog-ref))

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

;;; minlog

(require 'scheme)
(require 'cmuscheme)

;; adapted from minlog source
(defun minlog-run-repl ()
  (interactive)
  ;; MINLOG directory
  (setq minlogpath (getenv "MINLOGPATH"))

  (setq scheme "scheme")

  (setq heapload (concat minlogpath "/init.scm"))

  (with-selected-window (or (and scheme-buffer
                                 (get-buffer-window scheme-buffer))
                            (selected-window))
    (run-scheme (concat scheme " " heapload))))

(defun minlog-restart-repl ()
  (interactive)

  (when (and scheme-buffer
             (get-buffer scheme-buffer)
             (comint-check-proc scheme-buffer))
    (comint-send-string (scheme-proc) "(exit)\n"))
  (sit-for 0.2) ;; ugly hack
  (minlog-run-repl))

(defun minlog-setup (&optional filename)
  ;; Enable utf-8
  (setq default-enable-multibyte-characters t)
  (condition-case nil
      (set-language-environment "Greek")
    (error nil))
  (condition-case nil
      (set-language-environment "utf-8")
    (error nil))

  (set-input-method "TeX")

  (split-window nil nil t)
  (with-selected-window (next-window)
    (minlog-run-repl)))

(require 'minlog-unicode)

;; minlog kbds

(defun minlog-send-undo ()
  (interactive)
  (comint-send-string (scheme-proc) "(undo)\n"))

(define-key scheme-mode-menu [minlog-restart-repl] '(menu-item "Minlog Restart Repl" minlog-restart-repl))
(define-key scheme-mode-map (kbd "C-c r") #'minlog-restart-repl)
(define-key scheme-mode-menu [minlog-send-undo] '(menu-item "Minlog Send Undo" minlog-send-undo))
(define-key scheme-mode-map (kbd "C-c C-u") #'minlog-send-undo)


(minlog-setup)
