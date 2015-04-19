;;; ctioga2-mode.el --- major mode for ctioga2 command file

;; Copyright (C) 2012 Vincent Fourmond

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; debian-mr-copyright-mode.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with your Debian installation, in /usr/share/common-licenses/GPL
;; If not, write to the Free Software Foundation, 675 Mass Ave,
;; Cambridge, MA 02139, USA.

(require 'compile)


(defvar ctioga2-syntax-table nil
  "Syntax table used in ctioga2-mode buffers.")

(if ctioga2-syntax-table
    ()
  (setq ctioga2-syntax-table (make-syntax-table))
  ;; Support # style comments
  (modify-syntax-entry ?#  "<"  ctioga2-syntax-table)
  (modify-syntax-entry ?\n "> " ctioga2-syntax-table)
  (modify-syntax-entry ?\( "()" ctioga2-syntax-table)
  (modify-syntax-entry ?\) ")(" ctioga2-syntax-table)
  (modify-syntax-entry ?\' "\"'" ctioga2-syntax-table)
  )

(defvar ctioga2-available-commands nil
  "List of available commands")

(defun ctioga2-command-list ()
  "Returns the list of commands known to ctioga2. Results are cached"
  (if ctioga2-available-commands
      ()
    (setq ctioga2-available-commands 
          (process-lines "ctioga2" "--list-commands" "/raw=true"))
    )
  ctioga2-available-commands
  )

(defun ctioga2-make-font-lock ()
  "This returns a neat font-lock table"
  (list
   ;; Command names
   (list
    (concat
     "\\<\\("
     (regexp-opt (ctioga2-command-list))
     "\\)\\([[:blank:]]+\\|$\\|[[:blank:]]*(\\)")
    1 font-lock-function-name-face
    )
   '("\\$(\\([[:alnum:]_]+\\))"
     1
     font-lock-variable-name-face t)
   '("^[[:blank:]]*\\([[:alnum:]_]+\\)[[:blank:]]*:?="
     1
     font-lock-variable-name-face)
   )
  )

(defun ctioga2-compile-buffer ()
  "Compiles current buffer to PDF using ctioga2."
  (interactive)
  (compilation-start (format "ctioga2 -f '%s'" (file-truename (buffer-file-name))))
  )

(defvar ctioga2-regexp-alist
  '(("file '\\([^']+\\)' +line +\\([0-9]+\\)" 1 2))
  "Regexp used to match ctioga2 errors.  See `compilation-error-regexp-alist'.")



;;;###autoload
(define-derived-mode ctioga2-mode fundamental-mode "ctioga2"
  "A major mode for editing ctioga2 command files"
  (set-syntax-table ctioga2-syntax-table)
  ;; Comments
  (make-local-variable 'comment-start-skip)  ;Need this for font-lock...
  (setq comment-start-skip "\\(^\\|\\s-\\);?#+ *") ;;From perl-mode
  (make-local-variable 'comment-start)
  (make-local-variable 'comment-end)
  (setq comment-start "# " comment-end "")

  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults 
        (list (ctioga2-make-font-lock)
              nil           ;;; Keywords only? No, let it do syntax via table.
              nil           ;;; case-fold?
              nil           ;;; Local syntax table.
              nil           ;;; Use `backward-paragraph' ? No
              )
        )
  (local-set-key [(control ?c) (control ?c)] 'ctioga2-compile-buffer)

  )

