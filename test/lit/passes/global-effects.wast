;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; Run without global effects, and run with, and also run with but discard them
;; first (to check that discard works; that should be the same as without).

;; RUN: foreach %s %t wasm-opt -all                                                    --vacuum -S -o - | filecheck %s --check-prefix WITHOUT
;; RUN: foreach %s %t wasm-opt -all --generate-global-effects                          --vacuum -S -o - | filecheck %s --check-prefix INCLUDE
;; RUN: foreach %s %t wasm-opt -all --generate-global-effects --discard-global-effects --vacuum -S -o - | filecheck %s --check-prefix WITHOUT

(module

  ;; WITHOUT:      (type $void (func))
  ;; INCLUDE:      (type $void (func))
  (type $void (func))

  ;; WITHOUT:      (type $1 (func (result i32)))

  ;; WITHOUT:      (type $2 (func (param i32)))

  ;; WITHOUT:      (import "a" "b" (func $import (type $void)))
  ;; INCLUDE:      (type $1 (func (result i32)))

  ;; INCLUDE:      (type $2 (func (param i32)))

  ;; INCLUDE:      (import "a" "b" (func $import (type $void)))
  (import "a" "b" (func $import))

  ;; WITHOUT:      (table $t 0 funcref)
  ;; INCLUDE:      (table $t 0 funcref)
  (table $t 0 funcref)

  ;; WITHOUT:      (elem declare func $throw)

  ;; WITHOUT:      (tag $tag)
  ;; INCLUDE:      (elem declare func $throw)

  ;; INCLUDE:      (tag $tag)
  (tag $tag)

  ;; WITHOUT:      (func $main (type $void)
  ;; WITHOUT-NEXT:  (call $nop)
  ;; WITHOUT-NEXT:  (call $unreachable)
  ;; WITHOUT-NEXT:  (call $call-nop)
  ;; WITHOUT-NEXT:  (call $call-unreachable)
  ;; WITHOUT-NEXT:  (drop
  ;; WITHOUT-NEXT:   (call $unimportant-effects)
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT:  (call $throw)
  ;; WITHOUT-NEXT:  (call $throw-and-import)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $main (type $void)
  ;; INCLUDE-NEXT:  (call $unreachable)
  ;; INCLUDE-NEXT:  (call $call-unreachable)
  ;; INCLUDE-NEXT:  (call $throw)
  ;; INCLUDE-NEXT:  (call $throw-and-import)
  ;; INCLUDE-NEXT: )
  (func $main
    ;; Calling a function with no effects can be optimized away in INCLUDE (but
    ;; not WITHOUT or DISCARD, where the global effect info is not available).
    (call $nop)
    ;; Calling a function with effects cannot.
    (call $unreachable)
    ;; Calling something that calls something with no effects can be optimized
    ;; away, since we compute transitive effects
    (call $call-nop)
    ;; Calling something that calls something with effects cannot.
    (call $call-unreachable)
    ;; Calling something that only has unimportant effects can be optimized
    ;; (see below for details).
    (drop
      (call $unimportant-effects)
    )
    ;; A throwing function cannot be removed.
    (call $throw)
    ;; A function that throws and calls an import definitely cannot be removed.
    (call $throw-and-import)
  )

  ;; WITHOUT:      (func $cycle (type $void)
  ;; WITHOUT-NEXT:  (call $cycle)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $cycle (type $void)
  ;; INCLUDE-NEXT:  (call $cycle)
  ;; INCLUDE-NEXT: )
  (func $cycle
    ;; Calling a function with no effects in a cycle cannot be optimized out -
    ;; this must keep hanging forever.
    (call $cycle)
  )

  ;; WITHOUT:      (func $cycle-1 (type $void)
  ;; WITHOUT-NEXT:  (call $cycle-2)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $cycle-1 (type $void)
  ;; INCLUDE-NEXT:  (call $cycle-2)
  ;; INCLUDE-NEXT: )
  (func $cycle-1
    ;; $cycle-1 and -2 form a cycle together, in which no call can be removed.
    (call $cycle-2)
  )

  ;; WITHOUT:      (func $cycle-2 (type $void)
  ;; WITHOUT-NEXT:  (call $cycle-1)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $cycle-2 (type $void)
  ;; INCLUDE-NEXT:  (call $cycle-1)
  ;; INCLUDE-NEXT: )
  (func $cycle-2
    (call $cycle-1)
  )

  ;; WITHOUT:      (func $nop (type $void)
  ;; WITHOUT-NEXT:  (nop)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $nop (type $void)
  ;; INCLUDE-NEXT:  (nop)
  ;; INCLUDE-NEXT: )
  (func $nop
    (nop)
  )

  ;; WITHOUT:      (func $unreachable (type $void)
  ;; WITHOUT-NEXT:  (unreachable)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $unreachable (type $void)
  ;; INCLUDE-NEXT:  (unreachable)
  ;; INCLUDE-NEXT: )
  (func $unreachable
    (unreachable)
  )

  ;; WITHOUT:      (func $call-nop (type $void)
  ;; WITHOUT-NEXT:  (call $nop)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-nop (type $void)
  ;; INCLUDE-NEXT:  (nop)
  ;; INCLUDE-NEXT: )
  (func $call-nop
    ;; This call to a nop can be optimized out, as above, in INCLUDE.
    (call $nop)
  )

  ;; WITHOUT:      (func $call-unreachable (type $void)
  ;; WITHOUT-NEXT:  (call $unreachable)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-unreachable (type $void)
  ;; INCLUDE-NEXT:  (call $unreachable)
  ;; INCLUDE-NEXT: )
  (func $call-unreachable
    (call $unreachable)
  )

  ;; WITHOUT:      (func $unimportant-effects (type $1) (result i32)
  ;; WITHOUT-NEXT:  (local $x i32)
  ;; WITHOUT-NEXT:  (local.set $x
  ;; WITHOUT-NEXT:   (i32.const 100)
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT:  (return
  ;; WITHOUT-NEXT:   (local.get $x)
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $unimportant-effects (type $1) (result i32)
  ;; INCLUDE-NEXT:  (local $x i32)
  ;; INCLUDE-NEXT:  (local.set $x
  ;; INCLUDE-NEXT:   (i32.const 100)
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT:  (return
  ;; INCLUDE-NEXT:   (local.get $x)
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT: )
  (func $unimportant-effects (result i32)
    (local $x i32)
    ;; Operations on locals should not prevent optimization, as when we return
    ;; from the function they no longer matter.
    (local.set $x
      (i32.const 100)
    )
    ;; A return is an effect that no longer matters once we exit the function.
    (return
      (local.get $x)
    )
  )

  ;; WITHOUT:      (func $call-throw-and-catch (type $void)
  ;; WITHOUT-NEXT:  (block $tryend
  ;; WITHOUT-NEXT:   (try_table (catch_all $tryend)
  ;; WITHOUT-NEXT:    (call $throw)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT:  (block $tryend0
  ;; WITHOUT-NEXT:   (try_table (catch_all $tryend0)
  ;; WITHOUT-NEXT:    (call $throw-and-import)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-throw-and-catch (type $void)
  ;; INCLUDE-NEXT:  (block $tryend
  ;; INCLUDE-NEXT:   (try_table (catch_all $tryend)
  ;; INCLUDE-NEXT:    (call $throw)
  ;; INCLUDE-NEXT:   )
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT:  (block $tryend0
  ;; INCLUDE-NEXT:   (try_table (catch_all $tryend0)
  ;; INCLUDE-NEXT:    (call $throw-and-import)
  ;; INCLUDE-NEXT:   )
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT: )
  (func $call-throw-and-catch
    (block $tryend
      (try_table (catch_all $tryend)
        ;; This call cannot be optimized out, as the target throws. However, the
        ;; entire try-catch could be, since the call's only effect is to throw,
        ;; and the catch_all catches that. We do this for `try` but not yet for
        ;; `try_table`.
        (call $throw)
      )
    )
    (block $tryend
      (try_table (catch_all $tryend)
        ;; This call both throws and calls an import, and cannot be removed.
        (call $throw-and-import)
      )
    )
  )

  ;; WITHOUT:      (func $return-call-throw-and-catch (type $void)
  ;; WITHOUT-NEXT:  (return_call $throw)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $return-call-throw-and-catch (type $void)
  ;; INCLUDE-NEXT:  (return_call $throw)
  ;; INCLUDE-NEXT: )
  (func $return-call-throw-and-catch
    (block $tryend
      (try_table (catch_all $tryend)
        ;; This call cannot be optimized out, as the target throws. However, the
        ;; surrounding try-catch can be removed even without global effects
        ;; because the throw from the return_call is never observed by this
        ;; try-catch.
        (return_call $throw)
      )
    )
  )

  ;; WITHOUT:      (func $return-call-indirect-throw-and-catch (type $void)
  ;; WITHOUT-NEXT:  (return_call_indirect $t (type $void)
  ;; WITHOUT-NEXT:   (i32.const 0)
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $return-call-indirect-throw-and-catch (type $void)
  ;; INCLUDE-NEXT:  (return_call_indirect $t (type $void)
  ;; INCLUDE-NEXT:   (i32.const 0)
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT: )
  (func $return-call-indirect-throw-and-catch
    (block $tryend
      (try_table (catch_all $tryend)
        ;; This call cannot be optimized out, as the target may throw. However,
        ;; the surrounding try-catch can be removed even without global effects
        ;; because the throw from the return_call is never observed by this
        ;; try-catch.
        (return_call_indirect
          (i32.const 0)
        )
      )
    )
  )

  ;; WITHOUT:      (func $return-call-ref-throw-and-catch (type $void)
  ;; WITHOUT-NEXT:  (return_call_ref $void
  ;; WITHOUT-NEXT:   (ref.func $throw)
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $return-call-ref-throw-and-catch (type $void)
  ;; INCLUDE-NEXT:  (return_call_ref $void
  ;; INCLUDE-NEXT:   (ref.func $throw)
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT: )
  (func $return-call-ref-throw-and-catch
    (block $tryend
      (try_table (catch_all $tryend)
        ;; This call cannot be optimized out, as the target may throw. However,
        ;; the surrounding try-catch can be removed even without global effects
        ;; because the throw from the return_call is never observed by this
        ;; try-catch.
        (return_call_ref $void
          (ref.func $throw)
        )
      )
    )
  )

  ;; WITHOUT:      (func $call-return-call-throw-and-catch (type $void)
  ;; WITHOUT-NEXT:  (block $tryend
  ;; WITHOUT-NEXT:   (try_table (catch_all $tryend)
  ;; WITHOUT-NEXT:    (call $return-call-throw-and-catch)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT:  (block $tryend0
  ;; WITHOUT-NEXT:   (try_table (catch_all $tryend0)
  ;; WITHOUT-NEXT:    (call $return-call-indirect-throw-and-catch)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT:  (block $tryend1
  ;; WITHOUT-NEXT:   (try_table (catch_all $tryend1)
  ;; WITHOUT-NEXT:    (call $return-call-ref-throw-and-catch)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT:  (call $return-call-throw-and-catch)
  ;; WITHOUT-NEXT:  (call $return-call-indirect-throw-and-catch)
  ;; WITHOUT-NEXT:  (call $return-call-ref-throw-and-catch)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-return-call-throw-and-catch (type $void)
  ;; INCLUDE-NEXT:  (block $tryend
  ;; INCLUDE-NEXT:   (try_table (catch_all $tryend)
  ;; INCLUDE-NEXT:    (call $return-call-throw-and-catch)
  ;; INCLUDE-NEXT:   )
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT:  (block $tryend0
  ;; INCLUDE-NEXT:   (try_table (catch_all $tryend0)
  ;; INCLUDE-NEXT:    (call $return-call-indirect-throw-and-catch)
  ;; INCLUDE-NEXT:   )
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT:  (block $tryend1
  ;; INCLUDE-NEXT:   (try_table (catch_all $tryend1)
  ;; INCLUDE-NEXT:    (call $return-call-ref-throw-and-catch)
  ;; INCLUDE-NEXT:   )
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT:  (call $return-call-throw-and-catch)
  ;; INCLUDE-NEXT:  (call $return-call-indirect-throw-and-catch)
  ;; INCLUDE-NEXT:  (call $return-call-ref-throw-and-catch)
  ;; INCLUDE-NEXT: )
  (func $call-return-call-throw-and-catch
    (block $tryend
      (try_table (catch_all $tryend)
        ;; Even though the body of the previous function is a try-catch_all, the
        ;; function still throws because of its return_call, so this cannot be
        ;; optimized out, but once again the entire try-catch could be. Again,
        ;; this is something we do for `try` for not yet for `try_table`.
        (call $return-call-throw-and-catch)
      )
    )
    (block $tryend
      (try_table (catch_all $tryend)
        ;; This would be the same, except since it performs an indirect call, we
        ;; conservatively assume it could have any effect, so we can't optimize.
        (call $return-call-indirect-throw-and-catch)
      )
    )
    (block $tryend
      (try_table (catch_all $tryend)
        ;; Same here.
        (call $return-call-ref-throw-and-catch)
      )
    )

    ;; These cannot be optimized out at all.
    (call $return-call-throw-and-catch)
    (call $return-call-indirect-throw-and-catch)
    (call $return-call-ref-throw-and-catch)
  )

  ;; WITHOUT:      (func $call-unreachable-and-catch (type $void)
  ;; WITHOUT-NEXT:  (block $tryend
  ;; WITHOUT-NEXT:   (try_table (catch_all $tryend)
  ;; WITHOUT-NEXT:    (call $unreachable)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-unreachable-and-catch (type $void)
  ;; INCLUDE-NEXT:  (call $unreachable)
  ;; INCLUDE-NEXT: )
  (func $call-unreachable-and-catch
    (block $tryend
      (try_table (catch_all $tryend)
        ;; This call has a non-throw effect. We can optimize away the try-catch
        ;; (since no exception can be thrown anyhow), but we must leave the
        ;; call.
        (call $unreachable)
      )
    )
  )

  ;; WITHOUT:      (func $call-throw-or-unreachable-and-catch (type $2) (param $x i32)
  ;; WITHOUT-NEXT:  (block $tryend
  ;; WITHOUT-NEXT:   (try_table (catch_all $tryend)
  ;; WITHOUT-NEXT:    (if
  ;; WITHOUT-NEXT:     (local.get $x)
  ;; WITHOUT-NEXT:     (then
  ;; WITHOUT-NEXT:      (call $throw)
  ;; WITHOUT-NEXT:     )
  ;; WITHOUT-NEXT:     (else
  ;; WITHOUT-NEXT:      (call $unreachable)
  ;; WITHOUT-NEXT:     )
  ;; WITHOUT-NEXT:    )
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-throw-or-unreachable-and-catch (type $2) (param $x i32)
  ;; INCLUDE-NEXT:  (block $tryend
  ;; INCLUDE-NEXT:   (try_table (catch_all $tryend)
  ;; INCLUDE-NEXT:    (if
  ;; INCLUDE-NEXT:     (local.get $x)
  ;; INCLUDE-NEXT:     (then
  ;; INCLUDE-NEXT:      (call $throw)
  ;; INCLUDE-NEXT:     )
  ;; INCLUDE-NEXT:     (else
  ;; INCLUDE-NEXT:      (call $unreachable)
  ;; INCLUDE-NEXT:     )
  ;; INCLUDE-NEXT:    )
  ;; INCLUDE-NEXT:   )
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT: )
  (func $call-throw-or-unreachable-and-catch (param $x i32)
    ;; This try-catch-all's body will either call a throw or an unreachable.
    ;; Since we have both possible effects, we cannot optimize anything here.
    (block $tryend
      (try_table (catch_all $tryend)
        (if
          (local.get $x)
          (then
            (call $throw)
          )
          (else
            (call $unreachable)
          )
        )
      )
    )
  )

  ;; WITHOUT:      (func $throw (type $void)
  ;; WITHOUT-NEXT:  (throw $tag)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $throw (type $void)
  ;; INCLUDE-NEXT:  (throw $tag)
  ;; INCLUDE-NEXT: )
  (func $throw
    (throw $tag)
  )

  ;; WITHOUT:      (func $throw-and-import (type $void)
  ;; WITHOUT-NEXT:  (throw $tag)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $throw-and-import (type $void)
  ;; INCLUDE-NEXT:  (throw $tag)
  ;; INCLUDE-NEXT: )
  (func $throw-and-import
    (if
      (i32.const 1)
      (then
        (throw $tag)
      )
      (else
        (call $import)
      )
    )
  )

  ;; WITHOUT:      (func $cycle-with-unknown-call (type $void)
  ;; WITHOUT-NEXT:  (call $cycle-with-unknown-call)
  ;; WITHOUT-NEXT:  (call $import)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $cycle-with-unknown-call (type $void)
  ;; INCLUDE-NEXT:  (call $cycle-with-unknown-call)
  ;; INCLUDE-NEXT:  (call $import)
  ;; INCLUDE-NEXT: )
  (func $cycle-with-unknown-call
    ;; This function can not only call itself recursively, but also calls an
    ;; import. We should not remove anything here, and not error during the
    ;; analysis (this guards against a bug where the import would make us toss
    ;; away the effects object, and the infinite loop makes us set a property on
    ;; that object, so it must check the object still exists).
    (call $cycle-with-unknown-call)
    (call $import)
  )
)
