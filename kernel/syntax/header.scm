;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Header
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
;;;  Portions created by the Initial Developer are Copyright (C) 1996-2018
;;;  the Initial Developer. All Rights Reserved.
;;;
;;;  Contributor(s):
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


(include "~~lib/_gambit#.scm")


(declare
  (block)
  (standard-bindings)
  (extended-bindings)
  (not safe))


;;;
;;;; Macro
;;;


;; DANGER : temporary hack until proper primitive exists
(define-runtime-macro (jazz:define-macro pattern . rest)
  (define (form-size parms)
    (let loop ((lst parms) (n 1))
      (cond ((pair? lst)
             (let ((parm (car lst)))
               (if (memq parm '(#!optional #!key #!rest))
                 (- n)
                 (loop (cdr lst)
                       (+ n 1)))))
            ((null? lst)
             n)
            (else
             (- n)))))

  (let ((src `(lambda ,(cdr pattern) ,@rest)))
    `(begin
       (##define-macro ,pattern
         ,@rest)
       (##top-cte-add-macro!
        ##interaction-cte
        ',(car pattern)
        (##make-macro-descr
          #f
          ',(form-size (cdr pattern))
          ,src
          #f))
       (jazz:register-macro ',(car pattern)
         ,src))))


;;;
;;;; Syntax
;;;


;; DANGER : temporary hack until proper primitive exists
(define-runtime-macro (jazz:define-syntax name expander)
  `(begin
     (##define-syntax ,name
       ,expander)
     (##top-cte-add-macro!
      ##interaction-cte
      ',name
      (##make-macro-descr
        #t
        -1
        ,expander
        #f))
     (jazz:register-macro ',name
       ,expander)))


;;;
;;;; Synto
;;;


;; DANGER : temporary hack until proper primitive exists
(define-runtime-macro (jazz:define-synto pattern . rest)
  (let ((name (##car pattern))
        (variables (##cdr pattern)))
    (let ((expander
            `(lambda (src)
               (##sourcify-deep
                 (let ((src (##source-code src)))
                   ,(let iter ((scan variables))
                         (cond ((##null? scan)
                                (if (##null? (cdr rest))
                                    (##car rest)
                                  (##cons 'begin rest)))
                               ((##symbol? scan)
                                `(let ((,scan (##cdr src)))
                                   ,(iter '())))
                               (else
                                `(let ((src (##cdr src)))
                                   (let ((,(##car scan) (##car src)))
                                     ,(iter (##cdr scan))))))))
                 src))))
      `(begin
         (##define-syntax ,name
                          ,expander)
         (##top-cte-add-macro!
           ##interaction-cte
           ',name
           (##make-macro-descr
             #t
             -1
             ,expander
             #f))
         (jazz:register-macro ',name
                              ,expander)))))


;;;
;;;; Subtypes
;;;


(define jazz:subtype-vector       (macro-subtype-vector))
(define jazz:subtype-pair         (macro-subtype-pair))
(define jazz:subtype-ratnum       (macro-subtype-ratnum))
(define jazz:subtype-cpxnum       (macro-subtype-cpxnum))
(define jazz:subtype-structure    (macro-subtype-structure))
(define jazz:subtype-boxvalues    (macro-subtype-boxvalues))
(define jazz:subtype-jazz         (macro-subtype-jazz))
(define jazz:subtype-symbol       (macro-subtype-symbol))
(define jazz:subtype-keyword      (macro-subtype-keyword))
(define jazz:subtype-continuation (macro-subtype-continuation))
(define jazz:subtype-procedure    (macro-subtype-procedure))
(define jazz:subtype-string       (macro-subtype-string))
(define jazz:subtype-flonum       (macro-subtype-flonum))
(define jazz:subtype-bignum       (macro-subtype-bignum))
(define jazz:subtype-foreign      (macro-subtype-foreign))
(define jazz:subtype-s8vector     (macro-subtype-s8vector))
(define jazz:subtype-u8vector     (macro-subtype-u8vector))
(define jazz:subtype-s16vector    (macro-subtype-s16vector))
(define jazz:subtype-u16vector    (macro-subtype-u16vector))
(define jazz:subtype-s32vector    (macro-subtype-s32vector))
(define jazz:subtype-u32vector    (macro-subtype-u32vector))
(define jazz:subtype-s64vector    (macro-subtype-s64vector))
(define jazz:subtype-u64vector    (macro-subtype-u64vector))
(define jazz:subtype-f32vector    (macro-subtype-f32vector))
(define jazz:subtype-f64vector    (macro-subtype-f64vector))


;;;
;;;; Tags
;;;


(define jazz:tag-still 5)
(define jazz:tag-permanent 6)


;;;
;;;; Code
;;;


(define (jazz:code-cte c)
  (macro-code-cte c))


;;;
;;;; Environment
;;;


(define (jazz:rte-up r)
  (macro-rte-up r))


;;;
;;;; Binding
;;;


(define (jazz:repl-context-bind val thunk)
  (macro-dynamic-bind repl-context val thunk))


;;;
;;;; Continuation
;;;


(define (jazz:continuation-denv cont)
  (macro-continuation-denv cont))


(define (jazz:continuation-needs-winding? cont)
  (let ((src (macro-denv-dynwind (macro-thread-denv (macro-current-thread))))
        (dst (macro-denv-dynwind (macro-continuation-denv cont))))
    (##not (or (##eq? src dst)
               (and (##fx= (macro-dynwind-level src) 0)
                    (##fx= (macro-dynwind-level dst) 0))))))


;;;
;;;; Fifo
;;;


(define (jazz:fifo->list fifo)
  (macro-fifo->list fifo))


;;;
;;;; Repl
;;;


(define (jazz:current-repl-context)
  (macro-current-repl-context))

(define (jazz:repl-context-level context)
  (macro-repl-context-level context))

(define (jazz:repl-context-depth context)
  (macro-repl-context-depth context))

(define (jazz:repl-context-cont context)
  (macro-repl-context-cont context))

(define (jazz:repl-context-initial-cont context)
  (macro-repl-context-initial-cont context))

(define (jazz:repl-context-prev-level context)
  (macro-repl-context-prev-level context))

(define (jazz:repl-context-prev-depth context)
  (macro-repl-context-prev-depth context))

(define (jazz:make-repl-context level depth cont initial-cont reason prev-level prev-depth)
  (macro-make-repl-context level depth cont initial-cont reason prev-level prev-depth))


;;;
;;;; Readtable
;;;


(define (jazz:readtable-named-char-table rt)
  (macro-readtable-named-char-table rt))

(define (jazz:readtable-named-char-table-set! rt nc)
  (macro-readtable-named-char-table-set! rt nc))

(define (jazz:readtable-paren-keyword-set! rt key)
  (macro-readtable-paren-keyword-set! rt key))

(define (jazz:readtable-bracket-keyword-set! rt key)
  (macro-readtable-bracket-keyword-set! rt key))

(define (jazz:readtable-brace-keyword-set! rt key)
  (macro-readtable-brace-keyword-set! rt key))

(define (jazz:readtable-start-syntax rt)
  (macro-readtable-start-syntax rt))


;;;
;;;; Readenv
;;;


(define (jazz:readenv? obj)
  (macro-readenv? obj))

(define (jazz:readenv-port re)
  (macro-readenv-port re))

(define (jazz:readenv-wrap re x)
  (macro-readenv-wrap re x))

(define (jazz:readenv-container re)
  (macro-readenv-container re))

(define (jazz:readenv-container-set! re c)
  (macro-readenv-container-set! re c))

(define (jazz:readenv-filepos re)
  (macro-readenv-filepos re))


;;;
;;;; Writeenv
;;;


(define (jazz:writeenv? obj)
  (macro-writeenv? obj))

(define (jazz:writeenv-port we)
  (macro-writeenv-port we))

(define (jazz:writeenv-style we)
  (macro-writeenv-style we))


;;;
;;;; Port
;;;


(define (jazz:output-port-width-set! port width)
  (macro-character-port-output-width-set! port (lambda (port) width)))


(define (jazz:debug-port-setup-width port)
  (jazz:output-port-width-set! port 512))


#;
;; wait as it makes repl commands display really bad
(jazz:debug-port-setup-width (repl-output-port))


;;;
;;;; Thread
;;;


(define (jazz:thread-active? thread)
  (and (macro-initialized-thread? thread)
       (##not (macro-terminated-thread-given-initialized? thread))
       (macro-started-thread-given-initialized? thread)))


(define (jazz:thread-cont thread)
  (macro-thread-cont thread))


(define (jazz:btq-owner mutex)
  (macro-btq-owner mutex))


;;;
;;;; Thread With Stack
;;;


;; dazoo
(define debug-stack?
  #t)


(define (jazz:header-get obj)
  (##u64vector-ref obj -1))

(define (jazz:header-set! obj h)
  (##u64vector-set! obj -1 h))

(define (jazz:header bytes subtype tag)
  (+ (* bytes 256) (* subtype 8) tag))


(define (jazz:thread-add-stack thread stack-len)
  (declare (not interrupts-enabled))
  (cond ((not debug-stack?)
         ;; ensure vector is a still
         (let ((total-len (max 256 stack-len)))
           (let ((stack (make-vector total-len #f)))
             ;; 0 bytes header so the gc doesn't collect the stack
             (jazz:header-set! stack (jazz:header 0 jazz:subtype-vector jazz:tag-still))
             (macro-thread-stack-set! thread stack)
             ;; skip 2 32 bit quads for header
             (macro-thread-frame-pointer-set! thread 2)
             (macro-thread-stack-limit-set! thread (##fx+ 2 (##fx* total-len 2)))
             (let ((name (thread-name thread)))
               (let ((str (if (##symbol? name) (##symbol->string name) (##object->string name))))
                 (if (##not (jazz:string-starts-with? str "(execute "))
                     (jazz:debug-stack str stack)))))))
        ;; dazoo
        (else
         (pp (list (thread-name thread)))
         ;; ensure vector is a still
         (let ((total-len (max 256 stack-len)))
           (let ((stack (make-vector total-len #f)))
             (macro-thread-stack-set! thread stack)
             (macro-thread-frame-pointer-set! thread 0)
             (macro-thread-stack-limit-set! thread total-len))))))


(define (jazz:make-thread-with-stack stack-len thunk name)
  (let ((thread (make-root-thread thunk name)))
    (jazz:thread-add-stack thread stack-len)
    thread))


(define (jazz:push-stack-frame thread stack fp new-fp container line col)
  (declare (not interrupts-enabled))
  (jazz:clear-stack-frame thread stack fp new-fp)
  ;(pp (list fp '----> new-fp container line col))
  #f
  #;
  (if (##eq? (thread-name thread) 'player)
      (pp (list (##fx* fp 4) '>>> (##fx* new-fp 4)))))


(define (jazz:pop-stack-frame thread stack fp new-fp container line col)
  (declare (not interrupts-enabled))
  ;(pp (list fp '<---- new-fp container line col))
  #;
  (let ((name (thread-name thread)))
    (if (##eq? name 'player)
        (pp (list (##fx* fp 4) '<<< (##fx* new-fp 4)))))
  (jazz:invalidate-stack-frame thread stack fp new-fp)
  (let ((name (thread-name thread)))
    (if (and (##equal? name "cow")
             #;(##fx>= fp 394)
             #;(##fx< 394 new-fp))
        (begin
          (##write-string "." (##repl-output-port))
          (##gc)))))


#;
(define (jazz:invalidate-stack-frame thread stack fp new-fp)
  (declare (not interrupts-enabled))
  (let ((ptr (##fx+ stack fp))
        (frame-quads (##fx- new-fp fp)))
    (let loop ((n (##fx- frame-quads 1)))
         (if (##fx>= n 0)
             (let ((rank (##fx- n 2)))
               (let ((quad (##u32vector-ref ptr rank)))
                 (##u32vector-set! ptr rank (##replace-bit-field 3 0 2 quad))
                 (loop (##fx- n 1))))))))

;; dazoo
(define (jazz:clear-stack-frame thread stack fp new-fp)
  (declare (not interrupts-enabled))
  (let loop ((n fp))
       (if (##fx< n new-fp)
           (begin
             (##vector-set! stack n #f)
             (loop (##fx+ n 1))))))

;; dazoo
(define (jazz:invalidate-stack-frame thread stack fp new-fp)
  (declare (not interrupts-enabled))
  (let loop ((n fp))
       (if (##fx< n new-fp)
           (let ((obj (##vector-ref stack n)))
             (if obj
                 (let ((header (##u64vector-ref obj -1)))
                   (##u64vector-set! obj -1 (##replace-bit-field 3 0 2 header))
                   (##vector-set! stack n #f)))
             (loop (##fx+ n 1))))))


(define jazz:pushed-values
  (make-table test: equal?))

#;
(define (jazz:push-value thread stack fp offset obj container line col)
  (declare (not interrupts-enabled))
  ;; proof-of-concept with new stack tag bits
  (let ((header (%%u64vector-ref obj -1)))
    (%%u64vector-set! obj -1 (##replace-bit-field 3 0 1 header)))
  #;
  (let ((stack-offset (##fx+ fp offset)))
    (if (##fx= stack-offset 246)
        (let ((name (thread-name thread)))
          (if (##eq? name 'player)
              (let ((key (##list name container line col)))
                (if (##not (##table-ref jazz:pushed-values key #f))
                    (begin
                      (##table-set! jazz:pushed-values key #t)
                      (pp (list 'push stack-offset name container (##fx+ line 1) (##fx+ col 1) obj))))))))))

;; dazoo
(define (jazz:push-value thread stack fp offset obj container line col)
  (declare (not interrupts-enabled))
  (%%vector-set! stack (##fx+ fp offset) obj)
  #;
  (pp (list 'push offset obj container line col)))


;;;
;;;; Various
;;;


(define (jazz:absent-object? obj)
  (##eq? obj (macro-absent-obj)))


(define (jazz:unbound-object? obj)
  (##eq? obj #!unbound))
