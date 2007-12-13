;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Kernel Main
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
;;;  Portions created by the Initial Developer are Copyright (C) 1996-2006
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


(cond-expand
  (gambit
    (declare (block)
             (standard-bindings)
             (extended-bindings)))
  (else))


;;;
;;;; Compile
;;;


(define (cmodule module-name #!key (cc-options #f) (ld-options #f))
  (jazz.load-module 'core.module.build)
  (jazz.compile-module module-name cc-options: cc-options ld-options: ld-options))


(define (cjazz module-name)
  ;; seems the new gambit functionality has a bug
  (if #t ;; (memq 'debug jazz.compile-options)
      (cjazzmodule module-name)
    (cmodule module-name)))


(define (cjazzmodule module-name)
  (jazz.load-module 'core.module.build)
  (jazz.load-module 'jazz.build)
  (jazz.compile-jazz-module module-name))


;;;
;;;; Kernel
;;;


(cond-expand
  (gambit
    (define (jazz.build-kernel)
      (define (create-dir dir)
        (if (not (file-exists? dir))
            (create-directory dir)))
      
      (define (generate-architecture)
        (call-with-output-file "_build/kernel/syntax/architecture.scm"
          (lambda (output)
            (display "(define jazz.architecture" output)
            (newline output)
            (display "'" output)
            (write jazz.architecture output)
            (display ")" output)
            (newline output))))
      
      (create-dir "_build/")
      (create-dir "_build/kernel/")
      (create-dir "_build/kernel/syntax/")
      (create-dir "_build/kernel/runtime/")
      (generate-architecture)
      (compile-file-to-c "_build/kernel/syntax/architecture" output: "_build/kernel/syntax/")
      (compile-file-to-c "../../kernel/syntax/macros" output: "_build/kernel/syntax/")
      (compile-file-to-c "../../kernel/syntax/features" output: "_build/kernel/syntax/")
      (compile-file-to-c "../../kernel/syntax/primitives" output: "_build/kernel/syntax/")
      (compile-file-to-c "../../kernel/syntax/syntax" output: "_build/kernel/syntax/")
      (compile-file-to-c "../../kernel/syntax/runtime" output: "_build/kernel/syntax/")
      (compile-file-to-c "../../kernel/runtime/config" output: "_build/kernel/runtime/")
      (compile-file-to-c "../../kernel/runtime/digest" output: "_build/kernel/runtime/")
      (compile-file-to-c "../../kernel/runtime/kernel" output: "_build/kernel/runtime/")
      (compile-file-to-c "../../kernel/runtime/main" output: "_build/kernel/runtime/")
      (link-incremental (list "_build/kernel/syntax/architecture"
                              "_build/kernel/syntax/macros"
                              "_build/kernel/syntax/features"
                              "_build/kernel/syntax/primitives"
                              "_build/kernel/syntax/syntax"
                              "_build/kernel/syntax/runtime"
                              "_build/kernel/runtime/config"
                              "_build/kernel/runtime/digest"
                              "_build/kernel/runtime/kernel"
                              "_build/kernel/runtime/main")
                        output: "_build/kernel/runtime/jazz.c")
      (jazz.link-kernel)))
  
  (else))


(cond-expand
  (windows
    (define (jazz.link-kernel)
      (shell-command "gcc _build/kernel/syntax/architecture.c _build/kernel/syntax/macros.c _build/kernel/syntax/features.c _build/kernel/syntax/primitives.c _build/kernel/syntax/syntax.c _build/kernel/syntax/runtime.c _build/kernel/runtime/config.c _build/kernel/runtime/digest.c _build/kernel/runtime/kernel.c _build/kernel/runtime/main.c _build/kernel/runtime/jazz.c -lgambc -lws2_32 -mconsole -o jazz")))
  (else
    (define (jazz.link-kernel)
      (shell-command "gcc _build/kernel/syntax/architecture.c _build/kernel/syntax/macros.c _build/kernel/syntax/features.c _build/kernel/syntax/primitives.c _build/kernel/syntax/syntax.c _build/kernel/syntax/runtime.c _build/kernel/runtime/config.c _build/kernel/runtime/digest.c _build/kernel/runtime/kernel.c _build/kernel/runtime/main.c _build/kernel/runtime/jazz.c -lgambc -o jazz"))))


;;;
;;;; Build
;;;


(define (bkernel)
  (jazz.build-kernel))


(define (bmodule module-name)
  (jazz.load-module 'core.module.build)
  (jazz.build-module module-name))


(define (bcore)
  (jazz.load-module 'core.library)
  (bmodule 'core.base)
  (bmodule 'core.class)
  (bmodule 'core.generic)
  (bmodule 'core.library)
  (bmodule 'core.module))


(define (bjazz)
  (bcore)
  (bmodule 'scheme.dialect)
  (bmodule 'jazz.dialect)
  (cjazz 'jazz.dialect.language))


;;;
;;;; Platform
;;;


(cond-expand
  (windows
    (define (bcairo)
      (cmodule 'jazz.platform.cairo cc-options: "-IC:/jazz/dev/jazz/foreign/include/cairo" ld-options: "-LC:/jazz/dev/jazz/foreign/lib/cairo -lcairo")))
  (x11
    (define (bcairo)
      (cmodule 'jazz.platform.cairo cc-options: "-I/opt/local/include/cairo -I/opt/local/include" ld-options: "-L/opt/local/lib -lcairo"))))


(define (bfreetype)
  (cmodule 'jazz.platform.freetype cc-options: "-I/opt/local/include -I/opt/local/include/freetype2" ld-options: "-L/opt/local/lib -lfreetype")
  (cmodule 'jazz.platform.cairo.cairo-freetype cc-options: "-I/opt/local/include -I/opt/local/include/freetype2 -I/opt/local/include/cairo" ld-options: "-L/opt/local/lib -lcairo"))


(define (blogfont)
  (cmodule 'jazz.platform.cairo.cairo-logfont cc-options: "-IC:/jazz/dev/jazz/foreign/include/cairo" ld-options: "-LC:/jazz/dev/jazz/foreign/lib/cairo -lcairo"))


(cond-expand
  (freetype
    (define (bfont)
      (bfreetype)))
  (logfont
    (define (bfont)
      (blogfont))))


(define (bwindows)
  (jazz.load-module 'core.module.build)
  (cmodule 'jazz.platform.windows.WinDef      cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinTypes    cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinBase     cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinNT       cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinKernel   cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinGDI      cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinUser     cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinShell    cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinCtrl     cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.windows.WinDlg      cc-options: "-DUNICODE" ld-options: "-mwindows")
  (cmodule 'jazz.platform.cairo.cairo-windows cc-options: "-IC:/jazz/dev/jazz/foreign/include/cairo" ld-options: "-LC:/jazz/dev/jazz/foreign/lib/cairo -lcairo")
  (cjazz 'jazz.system.platform.windows))
  

(define (bx11)
  (jazz.load-module 'core.module.build) 
  (cmodule 'jazz.platform.x11                  cc-options: "-I/usr/X11R6/include" ld-options: "-L/usr/X11R6/lib -lX11")
  (cmodule 'jazz.platform.freetype             cc-options: "-I/opt/local/include -I/opt/local/include/freetype2" ld-options: "-L/opt/local/lib -lfreetype")
  (cmodule 'jazz.platform.cairo.cairo-x11      cc-options: "-I/opt/local/include/cairo" ld-options: "-L/opt/local/lib -lcairo")
  (cmodule 'jazz.platform.cairo.cairo-freetype cc-options: "-I/opt/local/include/cairo -I/opt/local/include -I/opt/local/include/freetype2" ld-options: "-L/opt/local/lib -lcairo")
  (cmodule 'jazz.platform.cairo                cc-options: "-I/opt/local/include/cairo" ld-options: "-L/opt/local/lib -lcairo"))


(cond-expand
  (windows
    (define (bplatform)
      (bjazz)
      (bcairo)
      (bfont)
      (bwindows)))
  (x11
    (define (bplatform)
      (bjazz)
      (bcairo)
      (bfont)
      (bx11))))


(define (lplatform)
  (jazz.load-module 'core.library)
  (jazz.load-module 'jazz)
  (jazz.load-module 'jazz.literals)
  (jazz.load-module 'jazz.platform)
  (jazz.load-module 'jazz.platform.literals)
  (jazz.platform.initialize-aliases))


;;;
;;;; Jedi
;;;


(define Jedi-Critical-Modules
  '(;; utilities
    jazz.io
    jazz.literals
    jazz.utilities
    time.implementation
    
    ;; component
    jazz.library.component.Component
    jazz.library.component.Branch
    jazz.library.component.Form
    
    ;; view
    jazz.ui.dialog
    jazz.ui.view
    jazz.ui.layout.Figure
    jazz.ui.view.Drawing
    jazz.ui.view.View
    jazz.ui.view.Scrollbar
    jazz.ui.view.Layout-View
    jazz.ui.view.Container
    jazz.ui.view.Root-View
    jazz.ui.view.Caption-Root
    jazz.ui.view.Frame-Root
    jazz.ui.view.Docked-Root
    jazz.ui.view.Toplevel-Root
    jazz.ui.view.Image-Tool
    jazz.ui.view.Tool-Button
    jazz.ui.window
    jazz.ui.window.platform.windows
    jazz.ui.window.Window
    jazz.ui.window.View-Player
    jazz.ui.window.Frame
    jazz.ui.window.Stage
    jazz.ui.window.Pad-Window
    jazz.ui.offscreen
    jazz.ui.graphic.Color
    jazz.ui.graphic.Pen
    jazz.ui.graphic.Surface
    jazz.ui.image.Image
    jazz.ui.image.Portfolio
    jazz.platform
    
    ;; explorer
    jazz.ui.text.Text-Explorer
    jazz.ui.text.Code-Explorer
    jazz.language.jazz.text.Jazz-Explorer
    jazz.language.lisp.text.Lisp-Explorer
    jazz.language.scheme.text.Scheme-Explorer
    
    ;; text
    jazz.ui.graphic.font.Font
    jazz.ui.graphic.Font-Metrics
    jazz.library.node
    jazz.library.exemplar
    jazz.ui.text.Format
    jazz.ui.text.Paragraph
    jazz.ui.text.Line
    jazz.ui.text.Run
    jazz.ui.text.Style
    jazz.ui.text.Text-Style
    jazz.ui.outline.Outline-Row
    jazz.ui.outline.Outline-View
    jazz.ui.text.Text-View
    jazz.ui.text.Code-Text-View
    jazz.ui.text.Text-Colorizer
    jazz.language.jazz.text.Jazz-Text-View
    jazz.language.lisp.text.Lisp-Text-View
    
    ;; catalog
    jazz.catalog.catalog.Catalog
    jazz.catalog.catalog.Filing-Catalog
    jazz.catalog.catalog.Indexed-Catalog
    jazz.catalog.entry.Catalog-Entry
    jazz.catalog.entry.Indexed-Entry
    jazz.catalog.entry.File-Entry
    jazz.catalog.parser.File-Parser
    jazz.language.lisp.catalog.Lisp-Entry
    jazz.language.lisp.catalog.Lisp-File-Entry
    jazz.language.lisp.parser.Lisp-Parser
    jazz.language.scheme.parser.Scheme-Parser
    jazz.language.jazz.parser.Jazz-Parser
    
    ;; tree
    jazz.ui.tree.Tree-View
    jazz.ui.tree.Tree-Column
    jazz.ui.tree.Tree-Row
    
    ;; application
    jazz.system.process.Process
    jazz.system.application.Application
    jazz.ui.workspace
    jazz.ui.workspace.Workspace-Preferences
    jazz.ide.IDE
    jedi.application.Jedi
    
    ;; jml
    jazz.jml
    jazz.jml.parser.JML-Parser
    jazz.jml.model.JML-Node
    jazz.jml.model.JML-Element
    jazz.jml.model.JML-Text
    
    ;; compare
    jazz.groupware.compare.Compare-Directories
    jazz.groupware.compare.Compare-Text-View
    jazz.groupware.compare.Compare-Texts
    jazz.groupware.compare.Compare-Trees
    jazz.groupware.compare.Directory-Comparer
    jazz.groupware.compare.Text-Comparer
    jazz.groupware.compare.Tree-Comparer))


(define (bjedi)
  (bjazz)
  (bplatform)
  (lplatform)
  (for-each cjazz Jedi-Critical-Modules))


(define (jedi)
  (jazz.load-module 'core.library)
  (jazz.load-module 'jazz)
  (jazz.load-module 'jazz.platform.literals)
  (jazz.load-module 'jazz.system.boot))


;;;
;;;; Debug
;;;


;; inspect a Jazz object
(define (inspect obj)
  (jazz.inspect-object (if (integer? obj) (jazz.serial-number->object obj) obj)))


;; resume the IDE message loop
(define (resume)
  (jazz.system.process.Process.Process.run-loop (jazz.dialect.language.get-process)))


;;;
;;;; Main
;;;


(define (jazz.main)
  (current-input-port (repl-input-port))
  (current-output-port (repl-output-port))
  (current-error-port (repl-output-port))
  (##repl-debug
    (lambda (first output-port)
      (display "Jazz 1.0a1" output-port)
      (newline output-port)
      (newline output-port)
      (force-output output-port)
      #f)))


(##main-set! jazz.main)
