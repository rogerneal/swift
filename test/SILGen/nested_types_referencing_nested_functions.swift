
// RUN: %target-swift-emit-silgen-ossa -o /dev/null -enable-sil-opaque-values -verify -module-name nested_types_referencing_nested_functions %s
// RUN: %target-swift-emit-silgen -verify -module-name nested_types_referencing_nested_functions %s | %FileCheck %s

do {
  func foo() { bar(2) }
  func bar<T>(_: T) { foo() }

  class Foo {
    // CHECK-LABEL: sil private [ossa] @$s025nested_types_referencing_A10_functions3FooL_CACycfc : $@convention(method) (@owned Foo) -> @owned Foo {
    init() {
      foo()
    }
    // CHECK-LABEL: sil private [ossa] @$s025nested_types_referencing_A10_functions3FooL_C3zimyyF : $@convention(method) (@guaranteed Foo) -> ()
    func zim() {
      foo()
    }
    // CHECK-LABEL: sil private [ossa] @$s025nested_types_referencing_A10_functions3FooL_C4zangyyxlF : $@convention(method) <T> (@in_guaranteed T, @guaranteed Foo) -> ()
    func zang<T>(_ x: T) {
      bar(x)
    }
    // CHECK-LABEL: sil private [ossa] @$s025nested_types_referencing_A10_functions3FooL_CfD : $@convention(method) (@owned Foo) -> ()
    deinit {
      foo()
    }
  }

  let x = Foo()
  x.zim()
  x.zang(1)
  _ = Foo.zim
  _ = Foo.zang as (Foo) -> (Int) -> ()
  _ = x.zim
  _ = x.zang as (Int) -> ()
}

// Invalid cases
do {
  var x = 123 // expected-note {{captured value declared here}}
  // expected-warning@-1 {{variable 'x' was never mutated; consider changing to 'let' constant}}

  func local() {
    _ = x // expected-note {{captured here}}
  }

  class Bar { // expected-note {{type declared here}}
    func zang() {
      local() // expected-error {{local function 'local' cannot be used within a class declaration because it captures 'x' from an outer scope}}
    }
  }
}

// https://github.com/swiftlang/swift/issues/86200
do {
  var x = 0 // expected-note {{captured value declared here}}
  // expected-warning@-1 {{variable 'x' was never mutated; consider changing to 'let' constant}}

  func bar() {
    _ = x // expected-note {{captured here}}
  }

  struct S { // expected-note {{type declared here}}
    func baz() {
      bar() // expected-error {{local function 'bar' cannot be used within a struct declaration because it captures 'x' from an outer scope}}
    }
  }
}

// Ditto, but with an anonymous closure referencing the local function.
do {
  var y = 0 // expected-note {{captured value declared here}}
  // expected-warning@-1 {{variable 'y' was never mutated; consider changing to 'let' constant}}

  func local() {
    _ = y // expected-note {{captured here}}
  }

  class Baz { // expected-note {{type declared here}}
    func zang() {
      let fn = { local() } // expected-error {{closure cannot be used within a class declaration because it captures 'y' from an outer scope}}
      fn()
    }
  }
}
