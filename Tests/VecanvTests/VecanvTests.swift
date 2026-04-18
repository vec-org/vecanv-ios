// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import Testing
@testable import Vecanv

@Suite("Vecanv umbrella")
struct VecanvTests {
    @Test("exposes A2UI version")
    func a2uiVersionIsPinned() {
        #expect(Vecanv.a2uiVersion == "0.9")
    }

    @Test("exposes umbrella version")
    func umbrellaVersionIsSet() {
        #expect(Vecanv.version == "0.1.0")
    }

}
// The umbrella's `@_exported import` re-exports are verified at compile time:
// if `Vecanv` builds and links, Primitives / A2UISwiftCore / A2UISwiftUI are
// accessible to consumers via `import Vecanv` alone.
