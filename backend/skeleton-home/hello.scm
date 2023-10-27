;; Welcome to Minlog! :-)

;; If you are new to Minlog, you can take a look at the official Minlog tutorial.
;; You can work on the tutorial using the "Help" menu and then navigating to
;; tutorial/tutor.pdf. You can find the examples for the tutor in examples/tutor.scm.

;; This editor runs on minlogpad.valentin-herrmann.de. Your Minlog code is stored on
;; this server and should be available when you revisit the same Minlogpad session.
;; However, absolutely no guarantees are made. You should make backups by
;; downloading (see the clipboard icon in the lower right corner).

;; C-z              enable Vi keybindings
;; C-x C-+          increase font size

;; "C-c" means "<Ctrl key> + c". In case your browser is intercepting C-c,
;; you can also use C-o. In case your browser in intercepting C-SPC, you can
;; also use C-p. For pasting code into the Minlogpad, see the clipboard
;; icon in the lower right corner.

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
