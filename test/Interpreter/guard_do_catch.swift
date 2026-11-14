// RUN: %target-run-simple-swift(-enable-experimental-feature GuardDoCatch) | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: swift_feature_GuardDoCatch

struct MyError: Error {}
struct OtherError: Error {}

func value(_ n: Int) throws -> Int {
  if n == 1 { throw MyError() }
  if n == 2 { throw OtherError() }
  return n * 10
}

func guarded(_ n: Int, _ s: String?) throws -> String {
  guard let s = s, do let x = try value(n)
  catch is MyError { return "my error" }
  catch let e as OtherError { _ = e; return "other error" }
  else { return "no string" }
  return "\(s)\(x)"
}

// CHECK: a0
print(try guarded(0, "a"))
// CHECK: my error
print(try guarded(1, "a"))
// CHECK: other error
print(try guarded(2, "a"))
// CHECK: no string
print(try guarded(0, nil))

func rethrown(_ n: Int) throws -> Int {
  guard do let x = try value(n) catch is MyError { return -1 }
  return x
}

// CHECK: 30
print(try rethrown(3))
// CHECK: -1
print(try rethrown(1))
do {
  _ = try rethrown(2)
} catch {
  // CHECK: propagated OtherError()
  print("propagated \(error)")
}

class Tracked {
  static var live = 0
  init() { Tracked.live += 1 }
  deinit { Tracked.live -= 1 }
}

func make(_ fail: Bool) throws -> Tracked {
  if fail { throw MyError() }
  return Tracked()
}

func lifetimes(_ fail: Bool) -> Int {
  guard let keep = Optional(Tracked()), do let t = try make(fail)
  catch { return Tracked.live }
  else { return -1 }
  _ = keep
  _ = t
  return Tracked.live
}

// The binding of the guard is alive in the rest of the scope; the bindings of
// the failed guard are destroyed before the 'catch' clause.
// CHECK: 2
print(lifetimes(false))
// CHECK: 0
print(lifetimes(true))
// CHECK: 0
print(Tracked.live)

// Multiple conditions, including several 'do' bindings.
func two(_ a: Int, _ b: Int) throws -> String {
  guard do let x = try value(a), do let y = try value(b)
  catch is MyError { return "my error" }
  catch is OtherError { return "other error" }
  return "\(x),\(y)"
}

// CHECK: 30,40
print(try two(3, 4))
// CHECK: my error
print(try two(1, 4))
// CHECK: other error
print(try two(3, 2))

func interleaved(_ a: Int, _ b: Int) throws -> String {
  guard do let x = try value(a), x > 25, do let y = try value(b), let z = Optional(y + 1)
  catch is MyError { return "my error" }
  else { return "else" }
  return "\(x),\(y),\(z)"
}

// CHECK: 30,40,41
print(try interleaved(3, 4))
// CHECK: else
print(try interleaved(0, 4))
// CHECK: my error
print(try interleaved(3, 1))
