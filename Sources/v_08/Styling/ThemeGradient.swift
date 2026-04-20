// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import SwiftUI

/// Gradient parsed from a theme styles-dict value.
///
/// Wire format: `"#RRGGBB,#RRGGBB,<angleDegrees>"` — e.g.
/// `"#FFFFFF,#EAF3FD,135"`. The angle is measured clockwise from
/// 12 o'clock, matching CSS `linear-gradient`.
///
/// Radial form: `"radial:#RRGGBB,#RRGGBB"` (no angle — center-to-edge).
///
/// Parsing is intentionally forgiving: bad input yields `nil` rather
/// than throwing. The A2UI spec treats styles as best-effort hints, and
/// a malformed gradient string shouldn't take the whole scene down.
public struct ThemeGradient: Equatable, Sendable {
    public enum Direction: Equatable, Sendable {
        case linear(angleDegrees: Double)
        case radial
    }

    public let startColor: Color
    public let endColor: Color
    public let direction: Direction

    public init(startColor: Color, endColor: Color, direction: Direction) {
        self.startColor = startColor
        self.endColor = endColor
        self.direction = direction
    }

    /// Parse a wire-format string. Returns nil for malformed input.
    public static func parse(_ raw: String) -> ThemeGradient? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }

        if s.hasPrefix("radial:") {
            let rest = String(s.dropFirst("radial:".count))
            let parts = rest.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { return nil }
            return ThemeGradient(
                startColor: Color(hex: parts[0]),
                endColor: Color(hex: parts[1]),
                direction: .radial
            )
        }

        let parts = s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2 else { return nil }

        let start = Color(hex: parts[0])
        let end = Color(hex: parts[1])
        let angle: Double
        if parts.count >= 3, let a = Double(parts[2]) {
            angle = a
        } else {
            angle = 180  // top → bottom default
        }
        return ThemeGradient(
            startColor: start,
            endColor: end,
            direction: .linear(angleDegrees: angle)
        )
    }

    /// Convert to a SwiftUI `ShapeStyle` appropriate for `.background(...)`
    /// or `.fill(...)`.
    public func asShapeStyle() -> AnyShapeStyle {
        switch direction {
        case .linear(let angleDegrees):
            // Convert CSS-style angle (0° = top, clockwise) to SwiftUI's
            // UnitPoint start/end.
            let (start, end) = Self.unitPoints(forAngleDegrees: angleDegrees)
            return AnyShapeStyle(
                LinearGradient(
                    colors: [startColor, endColor],
                    startPoint: start,
                    endPoint: end
                )
            )
        case .radial:
            return AnyShapeStyle(
                RadialGradient(
                    colors: [startColor, endColor],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
            )
        }
    }

    /// Translate an angle (CSS linear-gradient convention: 0° = top,
    /// clockwise) into SwiftUI `UnitPoint` pairs.
    static func unitPoints(forAngleDegrees deg: Double) -> (UnitPoint, UnitPoint) {
        let normalized = ((deg.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let radians = (normalized - 90) * .pi / 180  // CSS 0° = top; UnitPoint math uses 0° = right
        // The gradient axis passes through the unit circle; we take
        // diametrically-opposite points so the gradient spans the shape.
        let sx = 0.5 - 0.5 * CGFloat(cos(radians))
        let sy = 0.5 + 0.5 * CGFloat(sin(radians))
        let ex = 0.5 + 0.5 * CGFloat(cos(radians))
        let ey = 0.5 - 0.5 * CGFloat(sin(radians))
        return (
            UnitPoint(x: sx, y: sy),
            UnitPoint(x: ex, y: ey)
        )
    }
}
