;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Exception Handling
;;;
;;;  The contents of this file are subject to the Mozilla Public License Version
;;;  1.1 (the "License"); you may not use this file except in compliance with
;;;  the License. You may obtain a copy of the License at
;;;  http://www.mozilla.org/MPL/
;;;
;;;  Software distributed under the License is distributed on an "AS IS" basis,
;;;  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
;;;  for the specific language governing rights and limitations under the
;;;  License.
;;;
;;;  The Original Code is JazzScheme.
;;;
;;;  The Initial Developer of the Original Code is Guillaume Cartier.
;;;  Portions created by the Initial Developer are Copyright (C) 1996-2008
;;;  the Initial Developer. All Rights Reserved.
;;;
;;;  Contributor(s):
;;;    Marc Feeley
;;;    Stephane Le Cornec
;;;
;;;  Alternatively, the contents of this file may be used under the terms of
;;;  the GNU General Public License Version 2 or later (the "GPL"), in which
;;;  case the provisions of the GPL are applicable instead of those above. If
;;;  you wish to allow use of your version of this file only under the terms of
;;;  the GPL, and not to allow others to use your version of this file under the
;;;  terms of the MPL, indicate your decision by deleting the provisions above
;;;  and replace them with the notice and other provisions required by the GPL.
;;;  If you do not delete the provisions above, a recipient may use your version
;;;  of this file under the terms of any one of the MPL or the GPL.
;;;
;;;  See www.jazzscheme.org for details.


(module jazz.dialect.core.exception


;;;
;;;; Hook
;;;


(define (jazz.get-exception-hook)
  ##primordial-exception-handler-hook)

(define (jazz.set-exception-hook hook)
  (set! ##primordial-exception-handler-hook hook))


(define (jazz.invoke-exception-hook hook exc)
  (hook exc ##thread-end-with-uncaught-exception!))


;;;
;;;; System
;;;


(define (jazz.system-exception-hook exc other)
  (jazz.setup-terminal)
  (##repl-exception-handler-hook exc other))


;;;
;;;; Terminal
;;;


(define (jazz.setup-terminal)
  (if (tty? (repl-output-port))
      (begin
        (jazz.set-terminal-title)
        (jazz.bring-terminal-to-front))))


(define (jazz.set-terminal-title)
  (display "\033]0;Terminal\007" (repl-output-port)))

(define (jazz.bring-terminal-to-front)
  (display "\033[5t" (repl-output-port)))

(define (jazz.clear-terminal)
  (display "\033[H\033[J" (repl-output-port)))


;;;
;;;; Filter
;;;


(define (jazz.with-exception-filter filter catcher thunk)
  (let ((previous-handler (current-exception-handler)))
    (%%continuation-capture
      (lambda (catcher-cont)
        (with-exception-handler
          (lambda (exc)
            (if (with-exception-handler
                  (lambda (filter-exc)
                    (%%continuation-graft catcher-cont
                      (lambda ()
                        (previous-handler filter-exc))))
                  (lambda ()
                    (filter exc)))
                (%%continuation-graft catcher-cont
                  (lambda ()
                    (catcher exc)))
              (previous-handler exc)))
          thunk)))))


;;;
;;;; Propagater
;;;


(define (jazz.with-exception-propagater handler thunk)
  ;; Calls thunk and returns whatever thunk returns, unless
  ;; it raises an exception. In that case handler is called
  ;; with 2 arguments:
  ;; 1 - the exception that was raised
  ;; 2 - the propagation procedure
  ;; Note that the implementation will execute the handler
  ;; in the initial continuation in case the handler itself
  ;; generates an exception. If the propagation is not called
  ;; it will 'rewind to the future' before invoking the current
  ;; exception handler. This means that this mecanism can only
  ;; be used with purely functional code or with code that
  ;; properly obeys the dynamic wind / unwind semantics.
  (%%continuation-capture
    (lambda (catcher-cont)
      (with-exception-handler
        (lambda (exc)
          (%%continuation-capture
            (lambda (raise-cont)
              (%%continuation-graft
                catcher-cont
                (lambda ()
                  (handler exc
                           (lambda ()
                             (let ((handler (current-exception-handler)))
                               (%%continuation-graft
                                 raise-cont
                                 (lambda () (handler exc)))))))))))
        thunk)))))
