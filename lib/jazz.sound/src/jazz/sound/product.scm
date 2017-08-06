;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Sound Product
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
;;;  Portions created by the Initial Developer are Copyright (C) 1996-2015
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


(unit jazz.sound.product


;;;
;;;; Build
;;;


(cond-expand
  (cocoa
    (define jazz:sound-flags
      (let ((sound-include-path (jazz:quote-jazz-pathname "lib/jazz.sound/foreign/mac/soundio/include"))
            (sound-lib-path     (jazz:quote-jazz-pathname "lib/jazz.sound/foreign/mac/soundio/lib")))
        (let ((cc-flags (string-append "-I" sound-include-path " -fpermissive"))
              (ld-flags (string-append "-L" sound-lib-path " -lsoundio.1.1.0")))
          (list cc-flags ld-flags)))))
  (windows
    (define jazz:sound-flags
      (let ((sound-include-path (jazz:quote-jazz-pathname "lib/jazz.sound/foreign/windows/soundio/include"))
            (sound-lib-path     (jazz:quote-jazz-pathname "lib/jazz.sound/foreign/windows/soundio/lib")))
        (let ((cc-flags (string-append "-I" sound-include-path " -fpermissive"))
              (ld-flags (string-append "-L" sound-lib-path " -lsound")))
          (list cc-flags ld-flags)))))
  (else
    (define jazz:sound-flags
      (let ((cc-flags (string-append (jazz:pkg-config-cflags "sound") " -fpermissive"))
            (ld-flags (jazz:pkg-config-libs "sound")))
        (list cc-flags ld-flags)))))


(define jazz:sound-units
  (jazz:bind (cc-flags ld-flags) jazz:sound-flags
    `((jazz.sound.foreign cc-options: ,cc-flags ld-options: ,ld-flags))))


(cond-expand
  (cocoa
   (define jazz:platform-files
     (list (cons "lib/jazz.sound/foreign/mac/soundio/lib/libsoundio.1.1.0.dylib" "libsoundio.1.1.0.dylib"))))
  (windows
   (define jazz:platform-files
     (list (cons "lib/jazz.sound/foreign/windows/soundio/lib/libsound-1.dll" "libsound-1.dll"))))
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


(define (jazz:build-sound descriptor #!key (unit #f) (force? #f))
  (let ((unit-specs jazz:sound-units))
    (jazz:custom-compile/build unit-specs unit: unit pre-build: jazz:copy-platform-files force?: force?)
    (if (or (not unit) (not (assq unit unit-specs)))
        (jazz:build-product-descriptor descriptor))))


(define (jazz:sound-library-options descriptor add-language)
  (cond-expand
    (cocoa
      (let ((sound-lib-path (jazz:jazz-pathname "lib/jazz.sound/foreign/mac/soundio/lib")))
        (string-append "-L" sound-lib-path " -lsoundio.1.1.0")))
    (windows
      (let ((sound-lib-path (jazz:jazz-pathname "lib/jazz.sound/foreign/windows/soundio/lib")))
        (string-append "-L" sound-lib-path " -lsound")))
    (else
     (jazz:pkg-config-libs "sound"))))


;;;
;;;; Register
;;;


(jazz:register-product 'jazz.sound
  build: jazz:build-sound
  library-options: jazz:sound-library-options))
