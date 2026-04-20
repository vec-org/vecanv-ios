// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

/// Spec v0.8 Card — pure visual container with a single `child`.
///
/// Spec requires only: `child` (component ID, required). No styling properties in the spec.
/// Card is NOT interactive — hover/focus effects belong to the outer Button/NavigationLink.
///
/// ## Rendering strategy: system defaults, zero hardcoded values.
///
/// Default appearance uses **only SwiftUI system APIs** with no magic numbers:
/// - `.padding()` — system-default inset per platform & size class.
/// - `.background(.background)` — system background ShapeStyle, auto light/dark.
/// - `.clipShape(.rect(cornerRadius:style:))` — continuous squircle when overridden.
/// - No shadow by default — Apple system cards (Settings, grouped lists) rely on
///   background color contrast for layer separation, not drop shadows.
///
/// All styling is overridable via `.a2uiCardStyle(...)`. Only explicitly set
/// properties take effect; `nil` means "use system default".
struct A2UICard_V08: View {
    let node: ComponentNode_V08
    var viewModel: SurfaceViewModel_V08

    @Environment(\.a2uiStyle) private var style
    @Environment(\.vecanvThemeExtras) private var vecanvExtras

    /// Returns the shape to clip the card to. Priority:
    ///   1. VecanvThemeExtras.cardShape (e.g. `.bubble`) → custom Path
    ///   2. card.cornerRadius → RoundedRectangle
    ///   3. No rounding → plain Rectangle
    @ViewBuilder
    private func background<V: View>(for view: V, radius r: CGFloat?) -> some View {
        let gradient = vecanvExtras.cardFillGradient?.asShapeStyle()
        let bgColor = style.cardStyle.backgroundColor
        let border = vecanvExtras.cardBorderColor

        if let kind = vecanvExtras.cardShape, kind != .rect {
            let shape = VecanvShape(kind: kind)
            view
                .background {
                    if let gradient {
                        shape.fill(gradient)
                    } else if let bgColor {
                        shape.fill(bgColor)
                    } else {
                        shape.fill(.background)
                    }
                }
                .overlay {
                    if let border {
                        shape.stroke(border, lineWidth: 1)
                    }
                }
                .clipShape(shape)
        } else if let r {
            let shape = RoundedRectangle(cornerRadius: r, style: .continuous)
            view
                .background {
                    if let gradient {
                        shape.fill(gradient)
                    } else if let bgColor {
                        shape.fill(bgColor)
                    } else {
                        shape.fill(.background)
                    }
                }
                .overlay {
                    if let border {
                        shape.stroke(border, lineWidth: 1)
                    }
                }
                .clipShape(shape)
        } else {
            view
                .background {
                    if let gradient {
                        Rectangle().fill(gradient)
                    } else if let bgColor {
                        Rectangle().fill(bgColor)
                    } else {
                        Rectangle().fill(.background)
                    }
                }
        }
    }

    var body: some View {
        if let child = node.children.first {
            let card = style.cardStyle
            let shadowOpacity = vecanvExtras.cardShadowOpacity
            let shadowRadius = card.shadowRadius ?? (shadowOpacity != nil ? 8 : nil)

            let content = A2UIComponentView_V08(node: child, viewModel: viewModel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modify { view in
                    if let p = card.padding {
                        view.padding(p)
                    } else {
                        view.padding()
                    }
                }

            background(for: content, radius: card.cornerRadius)
                .modify { view in
                    if let sr = shadowRadius {
                        let color = card.shadowColor
                            ?? .black.opacity(shadowOpacity ?? 0.1)
                        return AnyView(view.shadow(color: color, radius: sr, y: card.shadowY ?? 1))
                    }
                    return AnyView(view)
                }
        }
    }
}

// MARK: - Conditional modifier helper

private extension View {
    /// Applies a transform and returns the result. Avoids `AnyView` type-erasure.
    @ViewBuilder
    func modify<V: View>(@ViewBuilder _ transform: (Self) -> V) -> some View {
        transform(self)
    }
}

// MARK: - Previews

#Preview("Card") {
    if let (vm, root) = previewViewModel(jsonl: """
    {"beginRendering":{"surfaceId":"s","root":"root"}}
    {"surfaceUpdate":{"surfaceId":"s","components":[{"id":"root","component":{"Card":{"child":"content"}}},{"id":"content","component":{"Column":{"children":{"explicitList":["title","desc"]}}}},{"id":"title","component":{"Text":{"text":{"literalString":"Card Title"},"variant":"h4"}}},{"id":"desc","component":{"Text":{"text":{"literalString":"This is a card with some content inside."}}}}]}}
    """) {
        A2UIComponentView_V08(node: root, viewModel: vm).padding()
    }
}
