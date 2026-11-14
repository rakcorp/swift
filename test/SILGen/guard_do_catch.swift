// RUN: %target-swift-emit-silgen -enable-experimental-feature GuardDoCatch %s | %FileCheck %s

// REQUIRES: swift_feature_GuardDoCatch

struct MyError: Error {}

func throwing() throws -> Int { return 1 }

// CHECK-LABEL: sil hidden [ossa] @$s14guard_do_catch5basicSiyF : $@convention(thin) () -> Int
func basic() -> Int {
  // CHECK: try_apply {{%.*}}() : $@convention(thin) () -> (Int, @error any Error), normal [[NORMAL:bb[0-9]+]], error [[ERROR:bb[0-9]+]]
  guard do let x = try throwing()
  catch { return -1 }
  // CHECK: [[NORMAL]]({{%.*}} : $Int):
  // CHECK: return
  return x
  // CHECK: [[ERROR]]({{%.*}} : @owned $any Error):
  // CHECK: integer_literal $Builtin.IntLiteral, -1
}

// A non-exhaustive 'catch' rethrows the error.
// CHECK-LABEL: sil hidden [ossa] @$s14guard_do_catch10rethrowingyyKF : $@convention(thin) () -> @error any Error
func rethrowing() throws {
  guard do let x = try throwing() catch is MyError { return }
  // CHECK: checked_cast_addr_br {{.*}} to MyError
  // CHECK: throw
  _ = x
}
