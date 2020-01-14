(module
  (func $f1 (export "nullref") (param $x nullref) (result i32)
    (ref.is_null (local.get $x))
  )
  (func $f2 (export "anyref") (param $x anyref) (result i32)
    (ref.is_null (local.get $x))
  )
  (func $f3 (export "funcref") (param $x funcref) (result i32)
    (ref.is_null (local.get $x))
  )
)

(assert_return (invoke "nullref" (ref.null)) (i32.const 1))
(assert_return (invoke "anyref" (ref.null)) (i32.const 1))
(assert_return (invoke "funcref" (ref.null)) (i32.const 1))