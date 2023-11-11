;; Welcome to Minlog! :-)

;; If you are new to Minlog, you can take a look at the official Minlog tutorial.
;; You can work on the minlog tutorial using the "Help" menu. There you can also
;; find the minlog reference.

;; This editor runs on minlogpad.valentin-herrmann.de. Your Minlog code is stored on
;; this server and should be available when you revisit the same Minlogpad session.
;; However, absolutely no guarantees are made. You should make backups by
;; downloading (see the clipboard icon in the lower right corner).

;; The server is not very well-equipped, hence please be mindful of your resource
;; usage. You do not need to quit Emacs when leaving this page, but please do
;; terminate Minlog or quit Emacs in case Minlog is taking an extraordinate amount of
;; time.

;; C-c r            restart minlog repl
;; C-c C-c          evaluate last definition
;; C-M-x            evaluate last definition
;; C-c C-r          evaluate region
;; C-c C-b          evaluate buffer
;; C-c C-f          evaluate buffer from pointer
;; C-c C-u          undo last minlog action
;; C-c C-l          load scheme file
;; C-c C-z          switch to repl

;; <TAB>            autocomplete
;; C-g              stop current operation

;; C-x b            select named Buffer
;; C-x C-b          list all buffers

;; C-x C-f          find file
;; C-s              search file

;; C-z              undo
;; C-Z              redo
;; M-o              toggle Vi keybindings
;; C-x C-+          increase font size
;; M-x              execute command

;; "C-c" means "<Ctrl key> + c". For pasting code into the Minlogpad,
;; see the clipboard icon in the lower right corner.

;; In text mode, use <F10> to access the menu bar, not the mouse.

(add-pvar-name "A" "B" "C" (make-arity))
(add-global-assumption "stabB" "((B -> bot) -> bot) -> B")
(pp "stabB")

(set-goal "((A -> bot) -> (B -> bot) -> bot)
           -> (A -> B)
           -> (C -> B)
           -> B")
(assume "a or b" "a -> b" "c -> b")
(use "stabB")
(assume "not b")
(use "a or b")

(assume "a")
(use "not b")
(use "a -> b")
(use "a")

(use "not b")
