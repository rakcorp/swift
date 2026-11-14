// RUN: %target-typecheck-verify-swift -swift-version 5

// Without the 'GuardDoCatch' feature, 'do' can't begin a condition.

func throwing() throws -> Int { return 1 }

func test() {
  guard do let value = try throwing() catch { return } // expected-error {{expected expression, var, let or case in 'guard' condition}} expected-error {{expected '{' after 'do'}}
  _ = value // expected-error {{cannot find 'value' in scope}}
}
