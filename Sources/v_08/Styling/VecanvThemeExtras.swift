// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import SwiftUI

/// Vecanv-specific theme fields that don't fit into the vanilla
/// `A2UIStyle` struct — kept separate so vendored A2UI code stays clean.
/// Injected as a SwiftUI environment value alongside `A2UIStyle`.
///
/// Components that want to honor these extras do so via an explicit
/// lookup (`@Environment(\.vecanvThemeExtras)`). Components that don't
/// know about extras fall back to their vanilla rendering — the whole
/// thing degrades gracefully.
public struct VecanvThemeExtras: Equatable, Sendable {
    // ---- Shape registry lookups ----

    /// Shape to use for Card surfaces. Nil → fall back to rounded rect.
    public var cardShape: A2UIShapeKind?
    /// Shape to use for Button surfaces. Nil → fall back to rounded rect.
    public var buttonShape: A2UIShapeKind?
    /// Shape to use for TextField surfaces. Nil → fall back to rounded rect.
    public var textFieldShape: A2UIShapeKind?

    // ---- Gradients ----

    /// Gradient applied to Card fill (overrides cardBackgroundColor).
    public var cardFillGradient: ThemeGradient?
    /// Gradient applied to the surface background (behind everything).
    public var backgroundGradient: ThemeGradient?
    /// Gradient applied under chart area fills.
    public var chartFillGradient: ThemeGradient?

    // ---- Borders ----

    public var cardBorderColor: Color?
    public var textFieldBorderColor: Color?
    public var buttonSecondaryBorderColor: Color?

    // ---- Fills ----

    public var buttonPrimaryFill: Color?
    public var buttonSecondaryFill: Color?
    public var buttonPrimaryTextColor: Color?
    public var buttonSecondaryTextColor: Color?
    public var textFieldBackground: Color?
    public var textFieldCornerRadius: CGFloat?

    // ---- Chart ----

    public var chartLineColor: Color?
    public var chartFillOpacity: Double?

    // ---- Shadow opacity (to complement cardStyle.shadowColor/radius) ----

    public var cardShadowOpacity: Double?

    // ---- Animation ----

    public enum CardAnimation: String, Sendable {
        case none, breathe, float, ripple
    }
    public enum AnimationSpeed: String, Sendable {
        case fast, medium, slow
    }

    public var cardAnimation: CardAnimation?
    public var animationSpeed: AnimationSpeed?

    public init(
        cardShape: A2UIShapeKind? = nil,
        buttonShape: A2UIShapeKind? = nil,
        textFieldShape: A2UIShapeKind? = nil,
        cardFillGradient: ThemeGradient? = nil,
        backgroundGradient: ThemeGradient? = nil,
        chartFillGradient: ThemeGradient? = nil,
        cardBorderColor: Color? = nil,
        textFieldBorderColor: Color? = nil,
        buttonSecondaryBorderColor: Color? = nil,
        buttonPrimaryFill: Color? = nil,
        buttonSecondaryFill: Color? = nil,
        buttonPrimaryTextColor: Color? = nil,
        buttonSecondaryTextColor: Color? = nil,
        textFieldBackground: Color? = nil,
        textFieldCornerRadius: CGFloat? = nil,
        chartLineColor: Color? = nil,
        chartFillOpacity: Double? = nil,
        cardShadowOpacity: Double? = nil,
        cardAnimation: CardAnimation? = nil,
        animationSpeed: AnimationSpeed? = nil
    ) {
        self.cardShape = cardShape
        self.buttonShape = buttonShape
        self.textFieldShape = textFieldShape
        self.cardFillGradient = cardFillGradient
        self.backgroundGradient = backgroundGradient
        self.chartFillGradient = chartFillGradient
        self.cardBorderColor = cardBorderColor
        self.textFieldBorderColor = textFieldBorderColor
        self.buttonSecondaryBorderColor = buttonSecondaryBorderColor
        self.buttonPrimaryFill = buttonPrimaryFill
        self.buttonSecondaryFill = buttonSecondaryFill
        self.buttonPrimaryTextColor = buttonPrimaryTextColor
        self.buttonSecondaryTextColor = buttonSecondaryTextColor
        self.textFieldBackground = textFieldBackground
        self.textFieldCornerRadius = textFieldCornerRadius
        self.chartLineColor = chartLineColor
        self.chartFillOpacity = chartFillOpacity
        self.cardShadowOpacity = cardShadowOpacity
        self.cardAnimation = cardAnimation
        self.animationSpeed = animationSpeed
    }

    /// Parse the full Vecanv theme dict produced by `cloud migration 022`.
    /// Unknown / malformed values are silently dropped — the theme layer
    /// must degrade gracefully so a malformed style key never breaks the
    /// scene.
    public static func parse(from styles: [String: String]) -> VecanvThemeExtras {
        var e = VecanvThemeExtras()
        e.cardShape = styles["cardShape"].flatMap(A2UIShapeKind.init(rawValue:))
        e.buttonShape = styles["buttonShape"].flatMap(A2UIShapeKind.init(rawValue:))
        e.textFieldShape = styles["textFieldShape"].flatMap(A2UIShapeKind.init(rawValue:))

        e.cardFillGradient = styles["cardFillGradient"].flatMap(ThemeGradient.parse)
        e.backgroundGradient = styles["backgroundGradient"].flatMap(ThemeGradient.parse)
        e.chartFillGradient = styles["chartFillGradient"].flatMap(ThemeGradient.parse)

        e.cardBorderColor = styles["cardBorderColor"].map { Color(hex: $0) }
        e.textFieldBorderColor = styles["textFieldBorder"].map { Color(hex: $0) }
        e.buttonSecondaryBorderColor = styles["buttonSecondaryBorder"].map { Color(hex: $0) }

        e.buttonPrimaryFill = styles["buttonPrimaryFill"].map { Color(hex: $0) }
        e.buttonSecondaryFill = styles["buttonSecondaryFill"].flatMap { val in
            val == "transparent" ? Color.clear : Color(hex: val)
        }
        e.buttonPrimaryTextColor = styles["buttonPrimaryTextColor"].map { Color(hex: $0) }
        e.buttonSecondaryTextColor = styles["buttonSecondaryText"].map { Color(hex: $0) }

        e.textFieldBackground = styles["textFieldBackground"].map { Color(hex: $0) }
        e.textFieldCornerRadius = styles["textFieldCornerRadius"].flatMap(CGFloatParser.parse)

        e.chartLineColor = styles["chartLineColor"].map { Color(hex: $0) }
        e.chartFillOpacity = styles["chartFillOpacity"].flatMap(Double.init)

        e.cardShadowOpacity = styles["cardShadowOpacity"].flatMap(Double.init)

        e.cardAnimation = styles["cardAnimation"].flatMap(CardAnimation.init(rawValue:))
        e.animationSpeed = styles["animationSpeed"].flatMap(AnimationSpeed.init(rawValue:))
        return e
    }
}


/// Tiny helper so we can parse `CGFloat` from a string across platforms
/// where `CGFloat.init?(String)` isn't available directly.
enum CGFloatParser {
    static func parse(_ s: String) -> CGFloat? {
        Double(s).map { CGFloat($0) }
    }
}


// MARK: - Environment plumbing

private struct VecanvThemeExtrasKey: EnvironmentKey {
    static let defaultValue = VecanvThemeExtras()
}

extension EnvironmentValues {
    /// Vecanv-specific theme extras (shape, gradient, animation).
    /// Set once at the canvas root alongside `\.a2uiStyle`.
    public var vecanvThemeExtras: VecanvThemeExtras {
        get { self[VecanvThemeExtrasKey.self] }
        set { self[VecanvThemeExtrasKey.self] = newValue }
    }
}

extension View {
    /// Inject Vecanv theme extras into the environment. Typically called
    /// once at the canvas root, derived from `beginRendering.styles`.
    public func vecanvThemeExtras(_ extras: VecanvThemeExtras) -> some View {
        environment(\.vecanvThemeExtras, extras)
    }
}
