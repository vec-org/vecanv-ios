// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT
//
// Root view: launches straight into the Vecanv live producer.
// A2UI demo pages (CatalogPage, ActionDemoPage, etc.) remain in the
// codebase for reference but are no longer reachable from the UI.

import SwiftUI
import v_08

struct ContentView: View {
    var body: some View {
        NavigationStack {
            LivePage()
        }
    }
}

#Preview {
    ContentView()
}
