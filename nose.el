;; nose.el --- Easy Python test running in Emacs

;; Copyright (C) 2009 Jason Pellerin, Augie Fackler

;; Licensed under the same terms as Emacs.

;; Version: 0.1.0
;; Keywords: nose python testing
;; Created: 04 Apr 2009

;; This file is NOT part of GNU Emacs.

;; Licensed under the same terms as Emacs.

;;; Commentary:
;; This gives a bunch of functions that handle running nosetests on a
;; particular buffer or part of a buffer.

;;; Installation

;; In your emacs config:
;;
;; (require 'nose)
;; ; next line only for people with non-eco non-global test runners
;; ; (add-to-list 'nose-project-names "my/crazy/runner")

;; Note that if your global nose isn't called "nosetests", then you'll want to
;; redefine nose-global-name to be the command that should be used.

;; Probably also want some keybindings:
;; (add-hook 'python-mode-hook
;;           (lambda ()
;;             (local-set-key "\C-ca" 'nosetests-all)
;;             (local-set-key "\C-cm" 'nosetests-module)
;;             (local-set-key "\C-c." 'nosetests-one)
;;             (local-set-key "\C-cpa" 'nosetests-pdb-all)
;;             (local-set-key "\C-cpm" 'nosetests-pdb-module)
;;             (local-set-key "\C-cp." 'nosetests-pdb-one)))

(defvar nose-project-names '("eco/bin/test"))
(defvar nose-global-name "nosetests")

(defun run-nose (&optional tests debug)
  "run nosetests"
  (interactive)

  (let* ((nose (nose-find-test-runner))
         (where (expand-file-name "../.." (file-name-directory nose)))
         (args (if debug "--pdb" ""))
         (tnames (if tests tests "")))
    (print nose)
    (print args)
    (print tnames)
    (funcall (if debug 'pdb 'compile)
             (format "%s -v %s -w %s -c %s/setup.cfg %s"
                     (nose-find-test-runner) args where where tnames)))
  )

(defun nosetests-all (&optional debug)
  "run all tests"
  (interactive)
  (run-nose nil debug))

(defun nosetests-pdb-all ()
  (interactive)
  (nosetests-all t))

(defun nosetests-module (&optional debug)
  "run nosetests (via eggs/bin/test) on current buffer"
  (interactive)
  (run-nose buffer-file-name debug))

(defun nosetests-pdb-module ()
  (interactive)
  (nosetests-module t))

(defun nosetests-one (&optional debug)
  "run nosetests (via eggs/bin/test) on testable thing
 at point in current buffer"
  (interactive)
  (run-nose (format "%s:%s" buffer-file-name (nose-py-testable)) debug))

(defun nosetests-pdb-one ()
  (interactive)
  (nosetests-one t))

(defun nose-find-test-runner ()
  (interactive)
  (message
   (let ((result (reduce '(lambda (x y) (or x y))
                         (mapcar 'nose-find-test-runner-names nose-project-names))))
     (if result
         result
       nose-global-name))))

(defun nose-find-test-runner-names (runner)
  "find eggs/bin/test in a parent dir of current buffer's file"
  (nose-find-test-runner-in-dir-named (file-name-directory buffer-file-name) runner))

(defun nose-find-test-runner-in-dir-named (dn runner)
  (let ((fn (expand-file-name runner dn)))
    (cond ((file-regular-p fn) fn)
      ((equal dn "/") nil)
      (t (nose-find-test-runner-in-dir-named
          (file-name-directory (directory-file-name dn))
          runner)))))

(defun nose-py-testable ()
  (interactive)
  (let ((remember-point (point)))
    (re-search-backward
     "^ \\{0,4\\}\\(class\\|def\\)[ \t]+\\([a-zA-Z0-9_]+\\)" nil t)
    (setq t1 (buffer-substring-no-properties (match-beginning 2) (match-end 2)))
    (goto-char remember-point)
    (re-search-backward
     "^\\(class\\|def\\)[ \t]+\\([a-zA-Z0-9_]+\\)" nil t)
    (setq outer
          (buffer-substring-no-properties (match-beginning 1) (match-end 1)))
    (setq t2 (buffer-substring-no-properties (match-beginning 2) (match-end 2)))
    (let
        ((result (cond ((string= outer "def") t2)
                       ((string= t1 t2) t2)
                       (t (format "%s.%s" t2 t1)))))
      (goto-char remember-point)
      result)))

(provide 'nose)
