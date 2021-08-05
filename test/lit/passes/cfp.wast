;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: foreach %s %t wasm-opt --nominal --remove-unused-names --cfp -all -S -o - | filecheck %s
;; (remove-unused-names is added to test fallthrough values without a block
;; name getting in the way)

(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $struct (struct (field i32)))
  (type $struct (struct i32))
  ;; CHECK:      (func $impossible-get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.null $struct)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $impossible-get
    (drop
      ;; This type is never created, so a get is impossible, and we will trap
      ;; anyhow. So we can turn this into an unreachable (plus a drop of the
      ;; reference).
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

(module
  ;; CHECK:      (type $struct (struct (field i64)))
  (type $struct (struct i64))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $test
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_default_with_rtt $struct
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i64)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i64.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $test
    ;; The only place this type is created is with a default value, and so we
    ;; can optimize the later get into a constant (plus a drop of the ref).
    ;;
    ;; (Note that the allocated reference is dropped here, so it is not actually
    ;; used anywhere, but this pass does not attempt to trace the paths of
    ;; references escaping and being stored etc. - it just thinks at the type
    ;; level.)
    (drop
      (struct.new_default_with_rtt $struct
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

(module
  ;; CHECK:      (type $struct (struct (field f32)))
  (type $struct (struct f32))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $test
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (f32.const 42)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f32.const 42)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $test
    ;; The only place this type is created is with a constant value, and so we
    ;; can optimize the later get into a constant (plus a drop of the ref).
    (drop
      (struct.new_with_rtt $struct
        (f32.const 42)
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

(module
  ;; CHECK:      (type $struct (struct (field f32)))
  (type $struct (struct f32))
  ;; CHECK:      (type $f32_=>_none (func (param f32)))

  ;; CHECK:      (func $test (param $f f32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (local.get $f)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct 0
  ;; CHECK-NEXT:    (ref.null $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $test (param $f f32)
    ;; The value given is not a constant, and so we cannot optimize.
    (drop
      (struct.new_with_rtt $struct
        (local.get $f)
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; Create in one function, get in another. The 10 should be forwarded to the
;; get.
(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $struct (struct (field i32)))
  (type $struct (struct i32))
  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (i32.const 10)
        (rtt.canon $struct)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; As before, but with the order of functions reversed to check for any ordering
;; issues.
(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $struct (struct (field i32)))
  (type $struct (struct i32))

  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (i32.const 10)
        (rtt.canon $struct)
      )
    )
  )
)

;; Different values assigned in the same function, in different struct.news,
;; so we cannot optimize the struct.get away.
(module
  ;; CHECK:      (type $struct (struct (field f32)))
  (type $struct (struct f32))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $test
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (f32.const 42)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (f32.const 1337)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct 0
  ;; CHECK-NEXT:    (ref.null $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $test
    (drop
      (struct.new_with_rtt $struct
        (f32.const 42)
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.new_with_rtt $struct
        (f32.const 1337)
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; Different values assigned in different functions, and one is a struct.set.
(module
  ;; CHECK:      (type $struct (struct (field (mut f32))))
  (type $struct (struct (mut f32)))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (f32.const 42)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (f32.const 42)
        (rtt.canon $struct)
      )
    )
  )
  ;; CHECK:      (func $set
  ;; CHECK-NEXT:  (struct.set $struct 0
  ;; CHECK-NEXT:   (ref.null $struct)
  ;; CHECK-NEXT:   (f32.const 1337)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $set
    (struct.set $struct 0
      (ref.null $struct)
      (f32.const 1337)
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct 0
  ;; CHECK-NEXT:    (ref.null $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; As the last testcase, but the values happen to coincide, so we can optimize
;; the get into a constant.
(module
  ;; CHECK:      (type $struct (struct (field (mut f32))))
  (type $struct (struct (mut f32)))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (f32.const 42)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (f32.const 42)
        (rtt.canon $struct)
      )
    )
  )
  ;; CHECK:      (func $set
  ;; CHECK-NEXT:  (struct.set $struct 0
  ;; CHECK-NEXT:   (ref.null $struct)
  ;; CHECK-NEXT:   (f32.const 42)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $set
    (struct.set $struct 0
      (ref.null $struct)
      (f32.const 42) ;; The last testcase had 1337 here.
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f32.const 42)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; Check that we look into the fallthrough value that is assigned.
(module
  ;; CHECK:      (type $struct (struct (field (mut f32))))
  (type $struct (struct (mut f32)))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $i32_=>_none (func (param i32)))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (block (result f32)
  ;; CHECK-NEXT:     (nop)
  ;; CHECK-NEXT:     (f32.const 42)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        ;; Fall though a 42 via a block.
        (block (result f32)
          (nop)
          (f32.const 42)
        )
        (rtt.canon $struct)
      )
    )
  )
  ;; CHECK:      (func $set (param $x i32)
  ;; CHECK-NEXT:  (struct.set $struct 0
  ;; CHECK-NEXT:   (ref.null $struct)
  ;; CHECK-NEXT:   (if (result f32)
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:    (f32.const 42)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $set (param $x i32)
    (struct.set $struct 0
      (ref.null $struct)
      ;; Fall though a 42 via an if.
      (if (result f32)
        (local.get $x)
        (unreachable)
        (f32.const 42)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f32.const 42)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; Test a function reference instead of a number.
(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $struct (struct (field funcref)))
  (type $struct (struct funcref))
  ;; CHECK:      (elem declare func $test)

  ;; CHECK:      (func $test
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (ref.func $test)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result (ref $none_=>_none))
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (ref.func $test)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $test
    (drop
      (struct.new_with_rtt $struct
        (ref.func $test)
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; Test for unreachable creations, sets, and gets.
(module
  (type $struct (struct (mut i32)))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $test
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block ;; (replaces something unreachable we can't emit)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block ;; (replaces something unreachable we can't emit)
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $test
    (drop
      (struct.new_with_rtt $struct
        (i32.const 10)
        (unreachable)
      )
    )
    (drop
      (struct.get $struct 0
        (unreachable)
      )
    )
    (struct.set $struct 0
      (unreachable)
      (i32.const 20)
    )
  )
)

;; Subtyping: Create a supertype and get a subtype. As we never create a
;;            subtype, the get must trap anyhow (the reference it receives can
;;            only by null in this closed world). Since the only possible writes
;;            to the field are of the value 10, we will optimize to that. (But
;;            as it will trap anyhow, that doesn't really matter.)
(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $struct (struct (field i32)))
  (type $struct (struct i32))
  ;; CHECK:      (type $substruct (struct (field i32)) (extends $struct))
  (type $substruct (struct i32) (extends $struct))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (i32.const 10)
        (rtt.canon $struct)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $substruct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $substruct 0
        (ref.null $substruct)
      )
    )
  )
)

;; Subtyping: Create a subtype and get a supertype. The get must receive a
;;            reference to the subtype (we never create a supertype) and so we
;;            can optimize.
(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $substruct (struct (field i32) (field f64)) (extends $struct))
  (type $substruct (struct i32 f64) (extends $struct))

  ;; CHECK:      (type $struct (struct (field i32)))
  (type $struct (struct i32))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $substruct
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (rtt.canon $substruct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $substruct
        (i32.const 10)
        (f64.const 3.14159)
        (rtt.canon $substruct)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; Subtyping: Create both a subtype and a supertype, with identical constants
;;            for the shared field, and get the supertype.
(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $struct (struct (field i32)))
  (type $struct (struct i32))
  ;; CHECK:      (type $substruct (struct (field i32) (field f64)) (extends $struct))
  (type $substruct (struct i32 f64) (extends $struct))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $substruct
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (rtt.canon $substruct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (i32.const 10)
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.new_with_rtt $substruct
        (i32.const 10)
        (f64.const 3.14159)
        (rtt.canon $substruct)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; Subtyping: Create both a subtype and a supertype, with different constants
;;            for the shared field, preventing optimization, as a get of the
;;            supertype may receive an instance of the subtype.
(module
  ;; CHECK:      (type $struct (struct (field i32)))
  (type $struct (struct i32))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $substruct (struct (field i32) (field f64)) (extends $struct))
  (type $substruct (struct i32 f64) (extends $struct))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $substruct
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (rtt.canon $substruct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (i32.const 10)
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.new_with_rtt $substruct
        (i32.const 20)
        (f64.const 3.14159)
        (rtt.canon $substruct)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct 0
  ;; CHECK-NEXT:    (ref.null $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
  )
)

;; Subtyping: Create both a subtype and a supertype, with different constants
;;            for the shared field, but get from the subtype. As the field is
;;            shared between the types, we cannot optimize here: we model the
;;            struct.new as a set, and if there is a set of the supertype, then
;;            it might be to a reference of the subtype.
;;            TODO: model new and set separately
(module
  ;; CHECK:      (type $substruct (struct (field i32) (field f64)) (extends $struct))
  (type $substruct (struct i32 f64) (extends $struct))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $struct (struct (field i32)))
  (type $struct (struct i32))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $substruct
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (rtt.canon $substruct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (i32.const 10)
        (rtt.canon $struct)
      )
    )
    (drop
      (struct.new_with_rtt $substruct
        (i32.const 20)
        (f64.const 3.14159)
        (rtt.canon $substruct)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $substruct 0
  ;; CHECK-NEXT:    (ref.null $substruct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $substruct 0
        (ref.null $substruct)
      )
    )
  )
)

;; Multi-level subtyping, check that we propagate not just to the immediate
;; supertype but all the way as needed.
(module
  ;; CHECK:      (type $struct3 (struct (field i32) (field f64) (field anyref)) (extends $struct2))
  (type $struct3 (struct i32 f64 anyref) (extends $struct2))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $struct2 (struct (field i32) (field f64)) (extends $struct1))
  (type $struct2 (struct i32 f64) (extends $struct1))

  ;; CHECK:      (type $struct1 (struct (field i32)))
  (type $struct1 (struct i32))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct3
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (ref.null any)
  ;; CHECK-NEXT:    (rtt.canon $struct3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct3
        (i32.const 20)
        (f64.const 3.14159)
        (ref.null any)
        (rtt.canon $struct3)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f64)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f64)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result anyref)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (ref.null any)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    ;; Get field 0 from the $struct1. This can be optimized to a constant
    ;; since we only ever created an instance of struct3 with a constant there.
    (drop
      (struct.get $struct1 0
        (ref.null $struct1)
      )
    )
    ;; Get both fields of $struct2.
    (drop
      (struct.get $struct2 0
        (ref.null $struct2)
      )
    )
    (drop
      (struct.get $struct2 1
        (ref.null $struct2)
      )
    )
    ;; Get all 3 fields of $struct3
    (drop
      (struct.get $struct3 0
        (ref.null $struct3)
      )
    )
    (drop
      (struct.get $struct3 1
        (ref.null $struct3)
      )
    )
    (drop
      (struct.get $struct3 2
        (ref.null $struct3)
      )
    )
  )
)

;; Multi-level subtyping with conflicts. The even-numbered fields will get
;; different values in the sub-most type. Create the top and bottom types, but
;; not the middle one. Any field which receives more than one value, no matter
;; where, cannot be optimized, which leaves the odd fields as optimizable, as
;; well as fields only present in the sub-most class anyhow (if they have a
;; constant value in the single construction there).
;; (See notes earlier on the limitations of our modeling new and set in the same
;; way.)
(module
  ;; CHECK:      (type $struct3 (struct (field i32) (field i32) (field f64) (field f64) (field anyref) (field anyref)) (extends $struct2))
  (type $struct3 (struct i32 i32 f64 f64 anyref anyref) (extends $struct2))

  ;; CHECK:      (type $struct2 (struct (field i32) (field i32) (field f64) (field f64)) (extends $struct1))
  (type $struct2 (struct i32 i32 f64 f64) (extends $struct1))

  ;; CHECK:      (type $struct1 (struct (field i32) (field i32)))
  (type $struct1 (struct i32 i32))

  ;; CHECK:      (type $anyref_=>_none (func (param anyref)))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $create (param $any anyref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct1
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:    (rtt.canon $struct1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct3
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (i32.const 999)
  ;; CHECK-NEXT:    (f64.const 2.71828)
  ;; CHECK-NEXT:    (f64.const 9.9999999)
  ;; CHECK-NEXT:    (ref.null any)
  ;; CHECK-NEXT:    (local.get $any)
  ;; CHECK-NEXT:    (rtt.canon $struct3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create (param $any anyref)
    (drop
      (struct.new_with_rtt $struct1
        (i32.const 10)
        (i32.const 20)
        (rtt.canon $struct1)
      )
    )
    (drop
      (struct.new_with_rtt $struct3
        (i32.const 10)
        (i32.const 999) ;; use a different value here
        (f64.const 2.71828)
        (f64.const 9.9999999)
        (ref.null any)
        (local.get $any) ;; use a non-constant value here, which can never be
                         ;; optimized.
        (rtt.canon $struct3)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct1 1
  ;; CHECK-NEXT:    (ref.null $struct1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct2 1
  ;; CHECK-NEXT:    (ref.null $struct2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f64)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f64.const 2.71828)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f64)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f64.const 9.9999999)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct3 1
  ;; CHECK-NEXT:    (ref.null $struct3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f64)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f64.const 2.71828)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f64)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f64.const 9.9999999)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result anyref)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (ref.null any)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct3 5
  ;; CHECK-NEXT:    (ref.null $struct3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    ;; Get all the fields of all the structs.
    (drop
      (struct.get $struct1 0
        (ref.null $struct1)
      )
    )
    (drop
      (struct.get $struct1 1
        (ref.null $struct1)
      )
    )
    (drop
      (struct.get $struct2 0
        (ref.null $struct2)
      )
    )
    (drop
      (struct.get $struct2 1
        (ref.null $struct2)
      )
    )
    (drop
      (struct.get $struct2 2
        (ref.null $struct2)
      )
    )
    (drop
      (struct.get $struct2 3
        (ref.null $struct2)
      )
    )
    (drop
      (struct.get $struct3 0
        (ref.null $struct3)
      )
    )
    (drop
      (struct.get $struct3 1
        (ref.null $struct3)
      )
    )
    (drop
      (struct.get $struct3 2
        (ref.null $struct3)
      )
    )
    (drop
      (struct.get $struct3 3
        (ref.null $struct3)
      )
    )
    (drop
      (struct.get $struct3 4
        (ref.null $struct3)
      )
    )
    (drop
      (struct.get $struct3 5
        (ref.null $struct3)
      )
    )
  )
)

;; Multi-level subtyping with a different value in the middle of the chain. We
;; cannot optimize any of these (for the very last field in the subtype, if we
;; modeled new separately from set then we could, as mentioned earlier).
(module
  ;; CHECK:      (type $struct1 (struct (field i32)))
  (type $struct1 (struct i32))
  ;; CHECK:      (type $struct2 (struct (field i32) (field f64)) (extends $struct1))
  (type $struct2 (struct i32 f64) (extends $struct1))
  ;; CHECK:      (type $struct3 (struct (field i32) (field f64) (field anyref)) (extends $struct2))
  (type $struct3 (struct i32 f64 anyref) (extends $struct2))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct1
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (rtt.canon $struct1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct2
  ;; CHECK-NEXT:    (i32.const 9999)
  ;; CHECK-NEXT:    (f64.const 0)
  ;; CHECK-NEXT:    (rtt.canon $struct2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct3
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (f64.const 0)
  ;; CHECK-NEXT:    (ref.null any)
  ;; CHECK-NEXT:    (rtt.canon $struct3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct1
        (i32.const 10)
        (rtt.canon $struct1)
      )
    )
    (drop
      (struct.new_with_rtt $struct2
        (i32.const 9999) ;; use a different value here
        (f64.const 0)
        (rtt.canon $struct2)
      )
    )
    (drop
      (struct.new_with_rtt $struct3
        (i32.const 10)
        (f64.const 0)
        (ref.null any)
        (rtt.canon $struct3)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct1 0
  ;; CHECK-NEXT:    (ref.null $struct1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct2 0
  ;; CHECK-NEXT:    (ref.null $struct2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct3 0
  ;; CHECK-NEXT:    (ref.null $struct3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    ;; Get field 0 in all the types.
    (drop
      (struct.get $struct1 0
        (ref.null $struct1)
      )
    )
    (drop
      (struct.get $struct2 0
        (ref.null $struct2)
      )
    )
    (drop
      (struct.get $struct3 0
        (ref.null $struct3)
      )
    )
  )
)

;; Test for a struct with multiple fields, some of which are constant and hence
;; optimizable, and some not. Also test that some have the same type.
(module
  ;; CHECK:      (type $struct (struct (field i32) (field f64) (field i32) (field f64) (field i32)))
  (type $struct (struct i32 f64 i32 f64 i32))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $struct
  ;; CHECK-NEXT:    (i32.eqz
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:    (f64.abs
  ;; CHECK-NEXT:     (f64.const 2.71828)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 30)
  ;; CHECK-NEXT:    (rtt.canon $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $struct
        (i32.eqz (i32.const 10)) ;; not a constant (as far as this pass knows)
        (f64.const 3.14159)
        (i32.const 20)
        (f64.abs (f64.const 2.71828)) ;; not a constant
        (i32.const 30)
        (rtt.canon $struct)
      )
    )
  )
  ;; CHECK:      (func $get
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct 0
  ;; CHECK-NEXT:    (ref.null $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result f64)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (f64.const 3.14159)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $struct 3
  ;; CHECK-NEXT:    (ref.null $struct)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 30)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (ref.null $struct)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 30)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get
    (drop
      (struct.get $struct 0
        (ref.null $struct)
      )
    )
    (drop
      (struct.get $struct 1
        (ref.null $struct)
      )
    )
    (drop
      (struct.get $struct 2
        (ref.null $struct)
      )
    )
    (drop
      (struct.get $struct 3
        (ref.null $struct)
      )
    )
    (drop
      (struct.get $struct 4
        (ref.null $struct)
      )
    )
    ;; Also test for multiple gets of the same field.
    (drop
      (struct.get $struct 4
        (ref.null $struct)
      )
    )
  )
)

;; Never create A, but have a set to its field. A subtype B has no creates nor
;; sets, and the final subtype C has a create and a get. The set to A should
;; apply to it, preventing optimization.
(module
  ;; CHECK:      (type $C (struct (field (mut i32))) (extends $B))
  (type $C (struct (mut i32)) (extends $B))

  ;; CHECK:      (type $A (struct (field (mut i32))))
  (type $A (struct (mut i32)))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $ref|$A|_=>_none (func (param (ref $A))))

  ;; CHECK:      (type $ref|$C|_=>_none (func (param (ref $C))))

  ;; CHECK:      (type $B (struct (field (mut i32))) (extends $A))
  (type $B (struct (mut i32)) (extends $A))

  ;; CHECK:      (func $create
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.new_with_rtt $C
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (rtt.canon $C)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $create
    (drop
      (struct.new_with_rtt $C
        (i32.const 10)
        (rtt.canon $C)
      )
    )
  )
  ;; CHECK:      (func $set (param $a (ref $A))
  ;; CHECK-NEXT:  (struct.set $A 0
  ;; CHECK-NEXT:   (local.get $a)
  ;; CHECK-NEXT:   (i32.const 20)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $set (param $a (ref $A))
    (struct.set $A 0
      (local.get $a)
      (i32.const 20)
    )
  )
  ;; CHECK:      (func $get (param $c (ref $C))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (struct.get $C 0
  ;; CHECK-NEXT:    (local.get $c)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get (param $c (ref $C))
    (drop
      (struct.get $C 0
        (local.get $c)
      )
    )
  )
)