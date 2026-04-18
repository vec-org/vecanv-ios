// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT
//
// Vecanv umbrella module.
//
// This module re-exports the SwiftUI-facing surface of the underlying
// a2ui-swift implementation. Import `Vecanv` to get the full SwiftUI
// rendering stack in one line:
//
//     import Vecanv
//
// UIKit and AppKit renderers are not re-exported; import them directly
// (`import A2UIUIKit`, `import A2UIAppKit`) if you need them.
//
// Internal module names are kept aligned with the upstream project
// (`BBC6BAE9/a2ui-swift`) so upstream fixes can be pulled via git merge.
// A future release may absorb the internals under first-party names.

@_exported import Primitives
@_exported import A2UISwiftCore
@_exported import A2UISwiftUI

public enum Vecanv {
    /// A2UI wire-format version this build targets.
    public static let a2uiVersion = "0.9"

    /// Umbrella module version.
    public static let version = "0.1.0"
}
