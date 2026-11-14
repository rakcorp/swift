// RUN: %target-typecheck-verify-swift -swift-version 5 -enable-experimental-feature GuardDoCatch

// REQUIRES: swift_feature_GuardDoCatch

struct MyError: Error {}
struct OtherError: Error {}

func throwing() throws -> Int { return 1 }
func throwingOptional() throws -> Int? { return nil }
func nonthrowing() -> Int { return 1 }

// The bindings of a 'do' condition are in scope after the guard.
func basic() {
  guard do let x = try throwing()
  catch { return }
  let _: Int = x
}

func var_binding() {
  guard do var x = try throwing() catch { return }
  x += 1
  _ = x
}

func patterns() {
  guard do let (a, b) = try (throwing(), throwing()) catch { return }
  _ = a + b
}

// A 'do' binding doesn't unwrap an optional.
func no_unwrapping() {
  guard do let x = try throwingOptional() catch { return }
  let _: Int? = x
}

// The error is implicitly bound in 'catch' clauses.
func error_binding() {
  guard do let x = try throwing()
  catch let e as MyError { _ = e; return }
  catch is OtherError { return }
  catch { _ = error; return }
  _ = x
}

// 'else' and 'catch' clauses can come in either order and be interleaved.
func mixed(_ s: String?) {
  guard let s = s, do let x = try throwing()
  catch is MyError { return }
  else { return }
  catch { return }
  _ = s
  _ = x
}

// Errors from non-'do' conditions aren't handled by the 'catch' clauses.
func other_conditions_not_covered() {
  guard do let x = try throwing(), try throwing() > 0 // expected-error {{errors thrown from here are not handled}}
  catch { return }
  else { return }
  _ = x
}

func else_only_with_other_conditions() {
  guard do let x = try throwing() else { return } catch { return } // expected-error {{'else' is never executed when all conditions are 'do' bindings; remove it}}
  _ = x
}

// Errors that aren't matched are rethrown.
func rethrows_unmatched() throws {
  guard do let x = try throwing() catch is MyError { return }
  _ = x
}

func unmatched_not_handled() {
  guard do let x = try throwing() catch is MyError { return } // expected-error {{errors thrown from here are not handled because the enclosing catch is not exhaustive}}
  _ = x
}

// Bindings aren't in scope in the clauses.
func not_in_scope_in_clauses(_ optionalString: String?) {
  guard let s = optionalString, do let x = try throwing()
  catch { _ = s; _ = x; return } // expected-error {{cannot find 's' in scope}} expected-error {{cannot find 'x' in scope}}
  else { _ = s; _ = x; return } // expected-error {{cannot find 's' in scope}} expected-error {{cannot find 'x' in scope}}
  _ = s
  _ = x
}

// 'try' is required.
func missing_try() {
  guard do let x = throwing() catch { return } // expected-error {{call can throw but is not marked with 'try'}}
  // expected-note@-1 {{did you mean to use 'try'?}} {{20-20=try }}
  // expected-note@-2 {{did you mean to handle error as optional value?}} {{20-20=try? }}
  // expected-note@-3 {{did you mean to disable error propagation?}} {{20-20=try! }}
  _ = x
}

func no_throw() {
  guard do let x = try nonthrowing() catch { return } // expected-warning {{no calls to throwing functions occur within 'try' expression}} // expected-warning {{'catch' block is unreachable because no errors are thrown in 'do' block}}
  _ = x
}

// Clause rules.
func missing_catch() {
  guard do let x = try throwing() else { return } // expected-error {{expected 'catch' after 'guard' condition with a 'do' binding}} expected-error {{errors thrown from here are not handled}}
  _ = x
}

func missing_else(_ b: Bool) {
  guard b, do let x = try throwing() catch { return } // expected-error {{expected 'else' after 'guard' condition}}
  _ = x
}

func extra_else(_ b: Bool) {
  guard b, do let x = try throwing() else { return } else { return } catch { return } // expected-error {{'guard' can have at most one 'else' clause}}
  _ = x
}

func refutable_patterns() {
  guard do let x? = try throwingOptional() catch { return } // expected-error {{'do' binding requires a pattern that matches every value}}
  guard do let .some(y) = try throwingOptional() catch { return } // expected-error {{'do' binding requires a pattern that matches every value}}
  _ = (x, y)
}

func only_in_guard() {
  if do let x = try throwing() { _ = x } // expected-error {{'do' bindings are only supported in 'guard' conditions}} expected-error {{errors thrown from here are not handled}} expected-warning {{initializer for conditional binding has non-optional type 'Int'}}
}

func closure_is_not_throwing() {
  let c = { () -> Int in
    guard do let x = try throwing() catch { return 0 }
    return x
  }
  _ = c()
}

func closure_is_throwing() {
  let c = { () -> Int in
    guard do let x = try throwing() catch is MyError { return 0 }
    return x
  }
  _ = try? c()
  _ = c() // expected-error {{call can throw, but it is not marked with 'try' and the error is not handled}}
}
