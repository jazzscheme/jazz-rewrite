;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Platform Product
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


(unit jazz.platform.product


;;;
;;;; Build
;;;


(cond-expand
  (mac
    (define jazz:custom-cc
      'llvm))
  (else))


(cond-expand
  (mac
    (define jazz:types-units
      `((jazz.platform.types-syntax)
        (jazz.platform.types custom-cc: ,jazz:custom-cc))))
  (else
   (define jazz:types-units
     '((jazz.platform.types-syntax)
       (jazz.platform.types)))))


(define jazz:windows-units
  (let ((pdh-include-path   (jazz:quote-jazz-pathname "lib/jazz.platform/foreign/windows/pdh/include"))
        (pdh-lib-path       (jazz:quote-jazz-pathname "lib/jazz.platform/foreign/windows/pdh/lib"))
        (base-windows-cc-options "-DUNICODE"))
    `((jazz.platform.windows)
      (jazz.platform.windows.Def      cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.Types    cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.Base     cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.NT       cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.Kernel   cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.GDI      cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.IDL      cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.MM       cc-options: ,base-windows-cc-options ld-options: "-mwindows -lwinmm")
      (jazz.platform.windows.User     cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.User1    cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.Shell    cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.Ctrl     cc-options: ,base-windows-cc-options ld-options: "-mwindows")
      (jazz.platform.windows.Dlg      cc-options: ,base-windows-cc-options ld-options: "-mwindows -lole32")
      (jazz.platform.windows.Perf     cc-options: ,(string-append "-I" pdh-include-path " " base-windows-cc-options) ld-options: ,(string-append "-L" pdh-lib-path " -mwindows -lpdh"))
      (jazz.platform.windows.PSAPI    cc-options: ,(string-append "-I" pdh-include-path " " base-windows-cc-options) ld-options: ,(string-append "-L" pdh-lib-path " -mwindows -lpsapi")))))


(cond-expand
  (x11
   (define jazz:x11-units
     (let ((cc-flags (jazz:pkg-config-cflags "x11"))
           (ld-flags (jazz:pkg-config-libs "x11")))
       `((jazz.platform.x11 cc-options: ,cc-flags ld-options: ,ld-flags)
         (jazz.platform.x11.x11-types)))))
   (else))


(cond-expand
  (ios
   (define jazz:ios-units
     `((jazz.platform.ios.camera ld-options: "-framework CoreFoundation -framework AVFoundation -framework CoreMedia -framework CoreGraphics -framework QuartzCore -framework ImageIO" custom-cc: ,jazz:custom-cc output-language: objc)
       (jazz.platform.ios.foreign ld-options: "-framework CoreFoundation -framework AudioToolbox -framework CoreLocation -framework CoreGraphics -framework StoreKit -framework MediaPlayer -framework AVFoundation -framework CoreMedia -framework MobileCoreServices" custom-cc: ,jazz:custom-cc output-language: objc)
       (angry.database ld-options: "-ObjC -F/Users/magnan/Downloads/couchbase-lite-ios-enterprise_1-3 -framework CoreFoundation -framework CoreGraphics -lz -lsqlite3 -framework SystemConfiguration -framework Security -framework CouchbaseLite -framework CFNetwork -framework MobileCoreServices" custom-cc: ,jazz:custom-cc output-language: objc))))
  (else))


(cond-expand
  (cocoa
   (define jazz:cocoa-units
     `((jazz.platform.cocoa.foreign cc-options: ,(jazz:patch-mac-ld-warnings "") ld-options: "-framework Cocoa -framework OpenGL -framework IOKit" custom-cc: ,jazz:custom-cc output-language: objc))))
  (else))


(cond-expand
  (cocoa
   (define jazz:platform-files
     '()))
  (windows
   (define jazz:platform-files
     (list (cons "lib/jazz.platform/foreign/windows/gcc/lib/libgcc_s_seh-1.dll" "libgcc_s_seh-1.dll")
           (cons "lib/jazz.platform/foreign/windows/gcc/lib/libstdc++-6.dll" "libstdc++-6.dll"))))
  (else
   (define jazz:platform-files
     '())))


(define (jazz:copy-platform-files)
  (let ((source jazz:kernel-source)
        (build (%%get-repository-directory jazz:Build-Repository)))
    (define (source-file path)
      (string-append source path))
    
    (define (build-file path)
      (string-append build path))
    
    (for-each (lambda (info)
                (let ((source (car info))
                      (build (cdr info)))
                  (jazz:copy-file (source-file source) (build-file build) feedback: jazz:feedback)))
              jazz:platform-files)))


(cond-expand
  (ios
    (define (jazz:build-platform descriptor #!key (unit #f) (skip-references? #f) (force? #f))
      (let ((unit-specs `((jazz.platform)
                          ,@jazz:types-units
                          ,@jazz:ios-units)))
        (jazz:custom-compile/build unit-specs unit: unit pre-build: jazz:copy-platform-files force?: force?)
        (if (or (not unit) (not (assq unit unit-specs)))
            (jazz:build-product-descriptor descriptor)))))
  (cocoa
    (define (jazz:build-platform descriptor #!key (unit #f) (skip-references? #f) (force? #f))
      (let ((unit-specs `((jazz.platform)
                          ,@jazz:types-units
                          ,@jazz:cocoa-units)))
        (jazz:custom-compile/build unit-specs unit: unit pre-build: jazz:copy-platform-files force?: force?)
        (if (or (not unit) (not (assq unit unit-specs)))
            (jazz:build-product-descriptor descriptor)))))
  (windows
    (define (jazz:build-platform descriptor #!key (unit #f) (skip-references? #f) (force? #f))
      (let ((unit-specs `((jazz.platform)
                          ,@jazz:types-units
                          ,@jazz:windows-units)))
        (jazz:custom-compile/build unit-specs unit: unit pre-build: jazz:copy-platform-files force?: force?)
        (if (or (not unit) (not (assq unit unit-specs)))
            (jazz:build-product-descriptor descriptor)))))
  (x11
    (define (jazz:build-platform descriptor #!key (unit #f) (skip-references? #f) (force? #f))
      (let ((unit-specs `((jazz.platform)
                          ,@jazz:types-units
                          ,@jazz:x11-units)))
        (jazz:custom-compile/build unit-specs unit: unit pre-build: jazz:copy-platform-files force?: force?)
        (if (or (not unit) (not (assq unit unit-specs)))
            (jazz:build-product-descriptor descriptor unit: unit force?: force?))))))


(define (jazz:platform-library-options descriptor add-language)
  (cond-expand
    ((or cocoa ios)
     (add-language 'jazz.platform.cocoa.foreign 'objc))
    (else))
  (cond-expand
    (windows
      (let ((pdh-lib-path (jazz:jazz-pathname "lib/jazz.platform/foreign/windows/pdh/lib")))
        (list (string-append "-L" pdh-lib-path) "-mwindows" "-lwinmm" "-lpdh" "-lpsapi")))
    (x11
      (let ((ld-flags (jazz:pkg-config-libs "x11")))
        (jazz:split-string ld-flags #\space)))
    (ios
      (list "-framework" "CoreFoundation" "-framework" "CoreGraphics"))
    (cocoa
      (list "-framework" "Cocoa" "-framework" "OpenGL" "-framework" "IOKit"))))


;;;
;;;; Register
;;;


(jazz:register-product 'jazz.platform
  build: jazz:build-platform
  library-options: jazz:platform-library-options))
