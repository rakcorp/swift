// RUN: %target-swift-frontend -emit-sil -verify -enable-experimental-feature GuardDoCatch %s -o /dev/null

// REQUIRES: swift_feature_GuardDoCatch

func throwing() throws -> Int { return 1 }

func catch_falls_through() {
  guard do let x = try throwing() catch { print(error) } // expected-error {{'guard' body must not fall through, consider using a 'return' or 'throw' to exit the scope}}
  _ = x
}

func else_falls_through(_ b: Bool) {
  guard b, do let x = try throwing()
  catch { return }
  else { print("no") } // expected-error {{'guard' body must not fall through, consider using a 'return' or 'throw' to exit the scope}}
  _ = x
}

func exits_are_fine(_ b: Bool) throws {
  guard b, do let x = try throwing()
  catch is CancellationError { return }
  else { throw CancellationError() }
  _ = x
}
