;;; -*- lexical-binding: t; -*-

(setq-default indent-tabs-mode nil)

(if (not (display-graphic-p))
    (progn (set-terminal-parameter nil 'background-mode 'light)
	   (load-theme 'tsdh-light)
	   (run-with-idle-timer 600 t 'kill-emacs)))

;;; general settings

(setq x-stretch-cursor t
      xterm-mouse-mode t
      scroll-margin 2
      inhibit-startup-screen t)

;; automatically save files periodically
(run-with-idle-timer 60 t (lambda () (save-some-buffers t nil)))

;;; minlog menu

(defun open-minlog-tutorial () (interactive) (find-file "~/doc/tutor.pdf"))
(defun open-minlog-tutorial-examples () (interactive) (find-file "~/examples/tutor.scm"))
(defun open-minlog-examples () (interactive) (find-file "~/examples"))
(defun open-minlog-ref () (interactive) (find-file "~/doc/ref.pdf"))
(define-key menu-bar-help-menu [sep9] '("--"))
(define-key menu-bar-help-menu [minlog-tut] '(menu-item "Minlog Tutorial" open-minlog-tutorial))
(define-key menu-bar-help-menu [minlog-tut-ex] '(menu-item "Minlog Tutorial Examples" open-minlog-tutorial-examples))
(define-key menu-bar-help-menu [minlog-ex] '(menu-item "Minlog Examples" open-minlog-examples))
(define-key menu-bar-help-menu [minlog-ref] '(menu-item "Minlog Reference" open-minlog-ref))

;;; evil
(setq evil-toggle-key "M-o"
      evil-default-state 'emacs
      evil-want-fine-undo t)
(require 'evil)

(evil-mode 1)

;;; which-key
(require 'which-key)
(which-key-mode)

;;; pdf
(require 'pdf-tools)
(pdf-tools-install-noverify)
(add-hook 'pdf-view-mode-hook
          (lambda ()
            (blink-cursor-mode -1)))

;;; undo
(require 'undo-fu)
(global-unset-key (kbd "C-z"))
(global-set-key (kbd "C-z")   'undo-fu-only-undo)
(global-set-key (kbd "C-S-z") 'undo-fu-only-redo)

;;; line numbers
(add-hook 'scheme-mode-hook #'display-line-numbers-mode)

;;; paredit
(require 'paredit)
(add-hook 'scheme-mode-hook #'enable-paredit-mode)

;;; corfu
(require 'corfu)
(global-corfu-mode)
(setq tab-always-indent 'complete)
(setq completion-cycle-threshold 3)

;;; geiser & scheme
(require 'geiser)
(require 'geiser-mode)
(require 'geiser-chez)
(require 'geiser-repl)
(require 'rainbow-delimiters)

(add-hook 'geiser-mode-hook #'rainbow-delimiters-mode)
(add-hook 'geiser-mode-hook #'macrostep-geiser-setup)
(add-hook 'geiser-repl-mode-hook #'macrostep-geiser-setup)
(add-hook 'scheme-mode-hook #'geiser-mode)

;; minlogpad functions to send string directly to repl instead
;; of evaluating them in the background
(defmacro minlogpad/with-repl (&rest body)
  (declare (indent 1) (debug t))
  `(let* ((buf (or geiser-repl--repl
                   (car geiser-repl--repls)))
          (win (and buf (get-buffer-window buf))))
     (if win
         (with-selected-window win
           ,@body)
       (if buf
           (with-current-buffer (or geiser-repl--repl
                                    (car geiser-repl--repls))
             ,@body)
         (error "Geiser Repl is missing")))))

(defun minlogpad/send-string (code &optional and-go wait-timeout)
  (minlogpad/with-repl
   ;; goto prompt
   (goto-char (point-max))
   (insert (string-trim code))
   (geiser-repl-maybe-send)

   (when and-go
     (geiser-repl-switch))))

(defvar minlogpad/send-buffer-substring--indirect-buffer nil)
(defun minlogpad/send-buffer-substring--cleanup-indirect-buffer ()
  (kill-buffer minlogpad/send-buffer-substring--indirect-buffer))

(defvar minlogpad/send-buffer-substring--cont nil) ; continuation
(defun minlogpad/check-for-prompt-and-run-cont (txt)
  ;; stop in case there is an error
  (if (string-match "Type (debug) to enter the debugger.\n> " txt)
      (progn
        (remove-hook 'comint-output-filter-functions
                     #'minlogpad/check-for-prompt-and-run-cont
                     t)
        (let* ((indirect-buff minlogpad/send-buffer-substring--indirect-buffer)
               (direct-buff (buffer-base-buffer indirect-buff))
               (p (with-current-buffer indirect-buff
                    (paredit-move-backward)
                    (point))))
          (with-current-buffer direct-buff
            (goto-char p)))
        (minlogpad/send-buffer-substring--cleanup-indirect-buffer))
    ;; run continuation if the prompt shows up in the output of the repl
    (when (string-match comint-prompt-regexp txt)
      (remove-hook 'comint-output-filter-functions
                   #'minlogpad/check-for-prompt-and-run-cont
                   t)
      (funcall minlogpad/send-buffer-substring--cont))))

(defun minlogpad/send-buffer-substring--wait-for-prompt-async (cont)
  (setq minlogpad/send-buffer-substring--cont cont)
  (minlogpad/with-repl
   (add-hook 'comint-output-filter-functions
             #'minlogpad/check-for-prompt-and-run-cont
             nil t)))

(require 'geiser-eval)
(defvar minlogpad/send-buffer-substring--stop? nil) ; boolean
(advice-add #'geiser-eval-interrupt :before
            (defun minlogpad/send-buffer-substring--interrupt ()
              (setq minlogpad/send-buffer-substring--stop? t)))

(defun minlogpad/send-buffer-substring (start end &optional and-go)
  (let ((buff (clone-indirect-buffer (concat "minlogpad-clone: "
                                             (buffer-name (current-buffer)))
                                     nil t)))
    (setq minlogpad/send-buffer-substring--indirect-buffer buff)
    (with-current-buffer buff
      (goto-char start))
    ;; beginning-sexp should be on the opening parenthesis
    ;; end-sexp should be on the position after the closing parenthesis
    (let ((beginning-sexp start)
          (end-sexp start))
      (cl-labels
          ((send-loop
            ()
            ;; get next sexp
            (condition-case err
                (progn
                  (with-current-buffer buff
                    (setq beginning-sexp end-sexp)
                    (paredit-move-forward)
                    (setq end-sexp (1+ (point))))

                  (if (and (not (equal beginning-sexp (1- end-sexp)))
                           (not minlogpad/send-buffer-substring--stop?)
                           (<= (1- end-sexp) end))
                      (progn
                        ;; send sexp
                        (with-current-buffer buff
                          (minlogpad/send-string (buffer-substring-no-properties beginning-sexp (1- end-sexp))
                                                 and-go))

                        ;; loop
                        (minlogpad/send-buffer-substring--wait-for-prompt-async #'send-loop))

                    ;; clean-up
                    (setq minlogpad/send-buffer-substring--stop? nil)
                    (minlogpad/send-buffer-substring--cleanup-indirect-buffer)))
              (error (and buff
                          (minlogpad/send-buffer-substring--cleanup-indirect-buffer))
                     (error err)))))
        (send-loop)))))

(defun minlogpad/send-region (start end &optional and-go)
  (interactive "rP")
  (save-restriction
    (narrow-to-region start end)
    (check-parens))
  (minlogpad/send-buffer-substring start
                                   end
                                   and-go))

(defun minlogpad/send-region-and-go (start end)
  (interactive "r")
  (minlogpad/send-region start end t))

(defun minlogpad/send-buffer (&optional and-go)
  (interactive "P")
  (save-restriction
    (check-parens))
  (minlogpad/send-buffer-substring (point-min) (point-max) and-go))

(defun minlogpad/send-buffer-and-go ()
  (interactive)
  (minlogpad/send-buffer t))

(defun minlogpad/send-buffer-from-point (&optional and-go)
  (interactive "P")
  (save-restriction
    (check-parens))
  (minlogpad/send-buffer-substring (point) (point-max) and-go))

(defun minlogpad/send-buffer-from-point-and-go ()
  (interactive)
  (minlogpad/send-buffer-from-point t))

(defun minlogpad/send-definition (&optional and-go)
  (interactive "P")
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (beginning-of-defun)
      (minlogpad/send-buffer-substring (point) end and-go))))

(defun minlogpad/send-definition-and-go ()
  (interactive)
  (minlogpad/send-buffer-substring t))

(defun minlogpad/send-last-sexp (&optional and-go)
  (interactive "P")
  (let (bosexp eosexp)
    (save-excursion
      (backward-sexp)
      (setq bosexp (point))
      (forward-sexp)
      (setq eosexp (point)))
    (minlogpad/send-buffer-substring bosexp eosexp and-go)))

(defun minlogpad/send-last-sexp-and-go ()
  (interactive)
  (minlogpad/send-last-sexp t))

(let ((map geiser-mode-map)
      (menu geiser-menu--custom-run))
  (define-key map [remap geiser-eval-definition] #'minlogpad/send-definition)
  (define-key map [remap geiser-eval-definition-and-go] #'minlogpad/send-definition-and-go)
  (define-key map [remap geiser-eval-buffer] #'minlogpad/send-buffer)
  (define-key map [remap geiser-eval-buffer-and-go] #'minlogpad/send-buffer-and-go)
  (define-key map (kbd "C-c C-f") #'minlogpad/send-buffer-from-point)
  (define-key map (kbd "C-c M-f") #'minlogpad/send-buffer-from-point-and-go)
  (define-key menu [minlogpad/send-buffer-from-point]
    '(menu-item "Eval buffer from pointer" minlogpad/send-buffer-from-point))
  (define-key menu [minlogpad/send-buffer-from-point-and-go]
    '(menu-item "Eval buffer from pointer and go" minlogpad/send-buffer-from-point-and-go))
  (define-key map [remap geiser-eval-last-sexp] #'minlogpad/send-last-sexp)
  (define-key map [remap geiser-eval-region] #'minlogpad/send-region)
  (define-key map [remap geiser-eval-region-and-go] #'minlogpad/send-region-and-go))

;; geiser shouldn't hang on errors
(setq geiser-mode-autodoc-p nil
      ;; we already have the output in the repl
      geiser-debug-jump-to-debug nil
      geiser-debug-show-debug nil)

;;; minlog
;; geiser should immediately load minlog
(let* ((minlogpath (getenv "MINLOGPATH"))
       (heapload (concat minlogpath "/init.scm")))
  (setq geiser-chez-extra-command-line-parameters `(,heapload)))

(require 'minlog-unicode)

(defun minlog-setup ()
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
  (let ((b (current-buffer)))
    (geiser 'chez)
    (goto-char (point-max))
    (pop-to-buffer b)))

(defun minlog-send-undo ()
  (interactive)
  (minlogpad/send-string "(undo)"))

(define-key geiser-menu--custom-switch [geiser-repl-restart-repl] '(menu-item "Geiser Restart Repl" geiser-repl-restart-repl))
(define-key geiser-mode-map (kbd "C-c r") #'geiser-repl-restart-repl)
(define-key geiser-menu--custom-run [minlog-send-undo] '(menu-item "Minlog Send Undo" minlog-send-undo))
(define-key geiser-mode-map (kbd "C-c C-u") #'minlog-send-undo)

;; fix weird bug with geiser repl
(advice-add #'geiser-repl-restart-repl :around
            (defun minlogpad/fix-geiser-repl-restart-repl (oldfun &rest r)
              (minlogpad/with-repl
               (apply oldfun r))))

;; setup minlog for opened scheme file
(add-hook 'geiser-mode-hook
          (defun minlogpad/minlog-setup-hook-one-shot ()
            (minlog-setup)
            (remove-hook 'geiser-mode-hook #'minlogpad/minlog-setup-hook-one-shot)))
