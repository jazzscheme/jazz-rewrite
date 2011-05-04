;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Classes
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
;;;  Portions created by the Initial Developer are Copyright (C) 1996-2012
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


(unit protected core.class.syntax.classes


;;;
;;;; Object
;;;


(jazz:define-class-syntax jazz:Object () (metaclass: #f)
  ())


(jazz:define-virtual-syntax (jazz:initialize (jazz:Object object)))
(jazz:define-virtual-syntax (jazz:destroy (jazz:Object object)))
(jazz:define-virtual-syntax (jazz:call-print (jazz:Object object) output detail))
(jazz:define-virtual-syntax (jazz:print-object (jazz:Object object) output detail))
(jazz:define-virtual-syntax (jazz:tree-fold (jazz:Object object) down up here seed environment))


;;;
;;;; Type
;;;


(jazz:define-class-syntax jazz:Type jazz:Object (metaclass: #f)
  ())


(jazz:define-virtual-syntax (jazz:of-type? (jazz:Type type) object) #t)
(jazz:define-virtual-syntax (jazz:of-subtype? (jazz:Type type) subtype) #t)
(jazz:define-virtual-syntax (jazz:specifiable? (jazz:Type type)) #t)
(jazz:define-virtual-syntax (jazz:category-type? (jazz:Type type)) #t)
(jazz:define-virtual-syntax (jazz:emit-specifier (jazz:Type type)) #t)
(jazz:define-virtual-syntax (jazz:emit-type (jazz:Type type) source-declaration environment backend) #t)
(jazz:define-virtual-syntax (jazz:emit-test (jazz:Type type) value source-declaration environment backend) #t)
(jazz:define-virtual-syntax (jazz:emit-check (jazz:Type type) value source-declaration environment backend) #t)


(jazz:define-macro (%%subtype? target type)
  `(jazz:of-subtype? ,type ,target))


(jazz:define-macro (%%subcategory? target category)
  `(jazz:vector-memq? ,category (%%get-category-ancestors ,target)))


(jazz:define-macro (%%subclass? target class)
  `(jazz:vector-memq? ,class (%%get-category-ancestors ,target)))


(jazz:define-macro (%%is? object type)
  `(jazz:of-type? ,type ,object))


(jazz:define-macro (%%is-not? object type)
  `(%%not (%%is? ,object ,type)))


;;;
;;;; Category
;;;


(jazz:define-class-syntax jazz:Category jazz:Type (metaclass: #f)
  ((identifier   accessors: #t)
   (fields       accessors: #t)
   (virtual-size accessors: #t)
   (ancestors    accessors: #t)
   (descendants  accessors: #t)))


(jazz:define-virtual-syntax (jazz:update-category (jazz:Category category)))


;;;
;;;; Class
;;;


(jazz:define-class-syntax jazz:Class jazz:Category (metaclass: #f constructor: jazz:allocate-class)
  ((ascendant       accessors: #t)
   (interfaces      accessors: #t)
   (slots           accessors: #t)
   (instance-slots  accessors: #t)
   (instance-size   accessors: #t)
   (level           accessors: #t)
   (virtual-names   accessors: #t)
   (class-table     accessors: #t)
   (interface-table accessors: #t)))


(jazz:define-virtual (jazz:write-object (jazz:Class class) we obj))


(jazz:define-macro (%%class-subtype? target class)
  (jazz:with-uniqueness target
    (lambda (trg)
      (jazz:with-uniqueness class
        (lambda (cls)
          `(let ((class-level (%%get-class-level ,cls)))
             (and (%%fx>= (%%get-class-level ,trg) class-level)
                  (%%eq? (%%vector-ref (%%get-category-ancestors ,trg) class-level) ,cls))))))))


(jazz:define-macro (%%class-is? object class)
  `(%%class-subtype? (jazz:class-of ,object) ,class))


(jazz:define-macro (%%category-is? object category)
  `(%%is? ,object ,category))


(jazz:define-macro (%%class? object)
  `(%%class-is? ,object jazz:Class))


(jazz:define-macro (%%object-class? object)
  `(%%eq? ,object jazz:Object))


;;;
;;;; Field
;;;


(jazz:define-class-syntax jazz:Field jazz:Object (accessors-type: macro)
  ((name getter: #t)))


(jazz:define-macro (%%get-category-field category field-name)
  `(%%table-ref (%%get-category-fields ,category) ,field-name #f))


(jazz:define-macro (%%set-category-field category field-name field)
  `(%%table-set! (%%get-category-fields ,category) ,field-name ,field))


;;;
;;;; Slot
;;;


(jazz:define-class-syntax jazz:Slot jazz:Field (constructor: jazz:allocate-slot accessors-type: macro)
  ((offset     getter: #t)
   (initialize getter: #t setter: #t)))


;;;
;;;; Object-Class
;;;


(jazz:define-class-syntax jazz:Object-Class jazz:Class (metaclass: #f)
  ())


;;;
;;;; Primitive Classes
;;;


(jazz:define-class-syntax jazz:Boolean-Class      jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Char-Class         jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Numeric-Class      jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Number-Class       jazz:Numeric-Class  (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Complex-Class      jazz:Number-Class   (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Real-Class         jazz:Complex-Class  (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Rational-Class     jazz:Real-Class     (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Integer-Class      jazz:Rational-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Fixnum-Class       jazz:Integer-Class  (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Flonum-Class       jazz:Real-Class     (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Sequence-Class     jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:List-Class         jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Null-Class         jazz:List-Class     (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Pair-Class         jazz:List-Class     (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:String-Class       jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Vector-Class       jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:S8Vector-Class     jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:U8Vector-Class     jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:S16Vector-Class    jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:U16Vector-Class    jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:S32Vector-Class    jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:U32Vector-Class    jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:S64Vector-Class    jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:U64Vector-Class    jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:F32Vector-Class    jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:F64Vector-Class    jazz:Sequence-Class (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Structure-Class    jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Port-Class         jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Continuation-Class jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Procedure-Class    jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Symbol-Class       jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Keyword-Class      jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Table-Class        jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Thread-Class       jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Promise-Class      jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Foreign-Class      jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Values-Class       jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:EOF-Class          jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Unspecified-Class  jazz:Class          (metaclass: jazz:Class) ())
(jazz:define-class-syntax jazz:Marker-Class       jazz:Class          (metaclass: jazz:Class) ())


(jazz:define-class-syntax jazz:Boolean      jazz:Object   (metaclass: jazz:Boolean-Class)      ())
(jazz:define-class-syntax jazz:Char         jazz:Object   (metaclass: jazz:Char-Class)         ())
(jazz:define-class-syntax jazz:Numeric      jazz:Object   (metaclass: jazz:Numeric-Class)      ())
(jazz:define-class-syntax jazz:Number       jazz:Numeric  (metaclass: jazz:Number-Class)       ())
(jazz:define-class-syntax jazz:Complex      jazz:Number   (metaclass: jazz:Complex-Class)      ())
(jazz:define-class-syntax jazz:Real         jazz:Complex  (metaclass: jazz:Real-Class)         ())
(jazz:define-class-syntax jazz:Rational     jazz:Real     (metaclass: jazz:Rational-Class)     ())
(jazz:define-class-syntax jazz:Integer      jazz:Rational (metaclass: jazz:Integer-Class)      ())
(jazz:define-class-syntax jazz:Fixnum       jazz:Integer  (metaclass: jazz:Fixnum-Class)       ())
(jazz:define-class-syntax jazz:Flonum       jazz:Real     (metaclass: jazz:Flonum-Class)       ())
(jazz:define-class-syntax jazz:Sequence     jazz:Object   (metaclass: jazz:Sequence-Class)     ())
(jazz:define-class-syntax jazz:List         jazz:Sequence (metaclass: jazz:List-Class)         ())
(jazz:define-class-syntax jazz:Null         jazz:List     (metaclass: jazz:Null-Class)         ())
(jazz:define-class-syntax jazz:Pair         jazz:List     (metaclass: jazz:Pair-Class)         ())
(jazz:define-class-syntax jazz:String       jazz:Sequence (metaclass: jazz:String-Class)       ())
(jazz:define-class-syntax jazz:Vector       jazz:Sequence (metaclass: jazz:Vector-Class)       ())
(jazz:define-class-syntax jazz:S8Vector     jazz:Sequence (metaclass: jazz:S8Vector-Class)     ())
(jazz:define-class-syntax jazz:U8Vector     jazz:Sequence (metaclass: jazz:U8Vector-Class)     ())
(jazz:define-class-syntax jazz:S16Vector    jazz:Sequence (metaclass: jazz:S16Vector-Class)    ())
(jazz:define-class-syntax jazz:U16Vector    jazz:Sequence (metaclass: jazz:U16Vector-Class)    ())
(jazz:define-class-syntax jazz:S32Vector    jazz:Sequence (metaclass: jazz:S32Vector-Class)    ())
(jazz:define-class-syntax jazz:U32Vector    jazz:Sequence (metaclass: jazz:U32Vector-Class)    ())
(jazz:define-class-syntax jazz:S64Vector    jazz:Sequence (metaclass: jazz:S64Vector-Class)    ())
(jazz:define-class-syntax jazz:U64Vector    jazz:Sequence (metaclass: jazz:U64Vector-Class)    ())
(jazz:define-class-syntax jazz:F32Vector    jazz:Sequence (metaclass: jazz:F32Vector-Class)    ())
(jazz:define-class-syntax jazz:F64Vector    jazz:Sequence (metaclass: jazz:F64Vector-Class)    ())
(jazz:define-class-syntax jazz:Structure    jazz:Object   (metaclass: jazz:Structure-Class)    ())
(jazz:define-class-syntax jazz:Port         jazz:Object   (metaclass: jazz:Port-Class)         ())
(jazz:define-class-syntax jazz:Continuation jazz:Object   (metaclass: jazz:Continuation-Class) ())
(jazz:define-class-syntax jazz:Procedure    jazz:Object   (metaclass: jazz:Procedure-Class)    ())
(jazz:define-class-syntax jazz:Symbol       jazz:Object   (metaclass: jazz:Symbol-Class)       ())
(jazz:define-class-syntax jazz:Keyword      jazz:Object   (metaclass: jazz:Keyword-Class)      ())
(jazz:define-class-syntax jazz:Table        jazz:Object   (metaclass: jazz:Table-Class)        ())
(jazz:define-class-syntax jazz:Thread       jazz:Object   (metaclass: jazz:Thread-Class)       ())
(jazz:define-class-syntax jazz:Promise      jazz:Object   (metaclass: jazz:Promise-Class)      ())
(jazz:define-class-syntax jazz:Foreign      jazz:Object   (metaclass: jazz:Foreign-Class)      ())
(jazz:define-class-syntax jazz:Values       jazz:Object   (metaclass: jazz:Values-Class)       ())
(jazz:define-class-syntax jazz:EOF          jazz:Object   (metaclass: jazz:EOF-Class)          ())
(jazz:define-class-syntax jazz:Unspecified  jazz:Object   (metaclass: jazz:Unspecified-Class)  ())
(jazz:define-class-syntax jazz:Marker       jazz:Object   (metaclass: jazz:Marker-Class)       ())


;;;
;;;; Property
;;;


(jazz:define-class-syntax jazz:Property jazz:Slot (constructor: jazz:allocate-property accessors-type: macro)
  ((getter getter: generate setter: generate)
   (setter getter: generate setter: generate)))


;;;
;;;; Method
;;;


(jazz:define-class-syntax jazz:Method jazz:Field (constructor: jazz:allocate-method accessors-type: macro)
  ((dispatch-type        getter: generate setter: generate)
   (implementation       getter: generate setter: generate)
   (implementation-tree  getter: generate setter: generate)
   (category-rank        getter: generate setter: generate)
   (implementation-rank  getter: generate setter: generate)))


;;;
;;;; Method-Node
;;;


(jazz:define-class-syntax jazz:Method-Node jazz:Object (constructor: jazz:allocate-method-node accessors-type: macro)
  ((category            getter: generate setter: generate)
   (implementation      getter: generate setter: generate)
   (next-node           getter: generate setter: generate)
   (next-implementation getter: generate setter: generate)
   (children            getter: generate setter: generate)))


;;;
;;;; Interface
;;;


(jazz:define-class-syntax jazz:Interface jazz:Category (constructor: jazz:allocate-interface accessors-type: macro)
  ((ascendants getter: generate)
   (rank       getter: generate)))


;;;
;;;; Queue
;;;


(jazz:define-class-syntax jazz:Queue jazz:Object (constructor: jazz:allocate-queue accessors-type: macro)
  ((head    getter: generate setter: generate)
   (tail    getter: generate setter: generate)
   (shared? getter: generate setter: generate))))
