(defpackage ps-utils
  (:use :common-lisp
        :parenscript)
  (:import-from :alexandria
                :hash-table-keys
                :hash-table-values
                :with-gensyms)
  (:export :defscript
           :compile-scripts))

(in-package :ps-utils)
;; The script table needs to be set at compile time for the compile-scripts
;; macro to work.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *script-symbol-table* (make-hash-table)))

(defmacro defscript (&body scripts)
  "Store supplied parenscript definitions in *SCRIPT-SYMBOL-TABLE*, ready
for compilation by MAKE-INCLUDE-SCRIPT"
  (with-gensyms (script script-name prev-script)
    `(progn
       (mapcar
        (lambda (,script)
          (let* ((,script-name (second ,script))
                 (,prev-script (gethash ,script-name *script-symbol-table*)))
            ;; Check for previous scripts with same name, update if necessary,
            ;; in case ps function definition changes during development
            (unless (eq ,script ,prev-script)
              (setf (gethash ,script-name *script-symbol-table*)
                    ,script))
            ,script))
        ',scripts))))

(defun compile-scripts (&key (script-table *script-symbol-table*) (minify t))
  "Compile all parenscript definitions made with DEFSCRIPT.
Wraps function definitions in a lambda which runs on the DOMContentLoaded
event, and assigns them to global variables with the function name. Also
compiles and attaches the parenscript runtime library to the generated
script."
  (let* ((*ps-print-pretty* (not minify))
         (names    (cons 'progn
                         (mapcar (lambda (name) (list 'defvar name))
                                 (hash-table-keys script-table))))
         (defns    (cons 'progn
                         (mapcar (lambda (form) (list 'setf
                                                 (second form)
                                                 (cons 'lambda (cddr form))))
                                 (hash-table-values script-table))))
         (wrap-fn `(chain document (add-event-listener "DOMContentLoaded"
                                                       (lambda () ,defns)))))
    (ps* (list 'progn *ps-lisp-library* names wrap-fn))))
