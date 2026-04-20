// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import SwiftUI

/// Built-in shape catalogue for Vecanv themes.
///
/// Added because the base theme (`vecanv`) explicitly wants organic,
/// bubble-shaped surfaces — not rounded rectangles. Shapes are
/// selectable from theme JSON (e.g. `"cardShape": "bubble"`). The
/// registry is hardcoded on purpose: themes are data, shapes are code,
/// and new shapes ship only with a new iOS build. Start with a
/// generous catalog so future theme variation doesn't require rebuild.
public enum A2UIShapeKind: String, CaseIterable, Sendable {
    /// Sharp rectangle. No rounding.
    case rect

    /// Horizontal pill — fully rounded on the short axis.
    case pill

    /// Organic bubble — asymmetric rounded shape with soft curves.
    /// Reads as "drop of water with surface tension", not a rounded
    /// rectangle. Good for chat bubbles, primary surfaces.
    case bubble

    /// Irregular blob — 4 organic lobes, each slightly different.
    /// Good for decorative background elements or hero cards.
    case blob

    /// Leaf-like — pointed at two diagonal corners, rounded at others.
    /// Good for tags, badges, status chips.
    case leaf

    /// Teardrop/droplet — pointed at the top, rounded bottom.
    /// Good for notifications, markers, callouts.
    case droplet

    /// Lozenge — four rounded sides meeting at four points.
    /// Good for buttons that want more character than a pill.
    case lozenge
}


/// A concrete SwiftUI Shape that draws any `A2UIShapeKind` into a rect.
///
/// Using a single type (rather than seven separate Shape structs)
/// keeps the call sites simple — the theme key maps straight to
/// `VecanvShape(kind:)` without a switch at every usage. Bezier paths
/// are defined relative to the rect so shapes scale to any size.
public struct VecanvShape: InsettableShape {
    public let kind: A2UIShapeKind
    public var inset: CGFloat = 0

    public init(kind: A2UIShapeKind) {
        self.kind = kind
    }

    public func inset(by amount: CGFloat) -> VecanvShape {
        var s = self
        s.inset += amount
        return s
    }

    public func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        switch kind {
        case .rect:
            return Path(r)
        case .pill:
            return Path(roundedRect: r, cornerRadius: min(r.width, r.height) / 2)
        case .bubble:
            return Self.bubblePath(in: r)
        case .blob:
            return Self.blobPath(in: r)
        case .leaf:
            return Self.leafPath(in: r)
        case .droplet:
            return Self.dropletPath(in: r)
        case .lozenge:
            return Self.lozengePath(in: r)
        }
    }

    // MARK: - Shape implementations

    /// Bubble: rounded on the left side generously, slightly less on
    /// the right — the asymmetry reads as a water bubble with surface
    /// tension, not a perfect squircle.
    static func bubblePath(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        let rTop = min(h * 0.55, w * 0.38)
        let rBottomLeft = min(h * 0.45, w * 0.30)
        let rBottomRight = min(h * 0.35, w * 0.22)
        let rTopRight = min(h * 0.40, w * 0.28)

        p.move(to: CGPoint(x: x + rTop, y: y))
        // top edge → top right
        p.addLine(to: CGPoint(x: x + w - rTopRight, y: y))
        p.addQuadCurve(
            to: CGPoint(x: x + w, y: y + rTopRight),
            control: CGPoint(x: x + w, y: y)
        )
        // right edge → bottom right
        p.addLine(to: CGPoint(x: x + w, y: y + h - rBottomRight))
        p.addQuadCurve(
            to: CGPoint(x: x + w - rBottomRight, y: y + h),
            control: CGPoint(x: x + w, y: y + h)
        )
        // bottom edge → bottom left
        p.addLine(to: CGPoint(x: x + rBottomLeft, y: y + h))
        p.addQuadCurve(
            to: CGPoint(x: x, y: y + h - rBottomLeft),
            control: CGPoint(x: x, y: y + h)
        )
        // left edge → top left (generous)
        p.addLine(to: CGPoint(x: x, y: y + rTop))
        p.addQuadCurve(
            to: CGPoint(x: x + rTop, y: y),
            control: CGPoint(x: x, y: y)
        )
        p.closeSubpath()
        return p
    }

    /// Blob: 4 lobes, each with a different outward bulge. Looks
    /// distinctly organic, not geometric.
    static func blobPath(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2
        let ry = rect.height / 2

        // Start at top, go clockwise through 4 anchor points, each
        // pushed out at a slightly different amount for organic feel.
        let top = CGPoint(x: cx, y: cy - ry)
        let right = CGPoint(x: cx + rx, y: cy)
        let bottom = CGPoint(x: cx, y: cy + ry)
        let left = CGPoint(x: cx - rx, y: cy)

        p.move(to: top)
        p.addQuadCurve(
            to: right,
            control: CGPoint(x: cx + rx * 1.15, y: cy - ry * 0.85)
        )
        p.addQuadCurve(
            to: bottom,
            control: CGPoint(x: cx + rx * 0.90, y: cy + ry * 1.10)
        )
        p.addQuadCurve(
            to: left,
            control: CGPoint(x: cx - rx * 1.10, y: cy + ry * 0.90)
        )
        p.addQuadCurve(
            to: top,
            control: CGPoint(x: cx - rx * 0.85, y: cy - ry * 1.15)
        )
        p.closeSubpath()
        return p
    }

    /// Leaf: pointed top-left and bottom-right, rounded at top-right
    /// and bottom-left. Works well for tags and status chips.
    static func leafPath(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.45
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: x, y: y))
        p.addLine(to: CGPoint(x: x + w - r, y: y))
        p.addQuadCurve(
            to: CGPoint(x: x + w, y: y + r),
            control: CGPoint(x: x + w, y: y)
        )
        p.addLine(to: CGPoint(x: x + w, y: y + h))
        p.addLine(to: CGPoint(x: x + r, y: y + h))
        p.addQuadCurve(
            to: CGPoint(x: x, y: y + h - r),
            control: CGPoint(x: x, y: y + h)
        )
        p.closeSubpath()
        return p
    }

    /// Droplet: teardrop shape, pointed top, rounded bottom.
    static func dropletPath(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let topY = rect.minY
        let bottomCy = rect.midY + rect.height * 0.25
        let radius = min(rect.width / 2, rect.height * 0.6)

        p.move(to: CGPoint(x: cx, y: topY))
        p.addQuadCurve(
            to: CGPoint(x: cx + radius, y: bottomCy),
            control: CGPoint(x: cx + radius * 0.75, y: topY + radius * 0.5)
        )
        p.addArc(
            center: CGPoint(x: cx, y: bottomCy),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        p.addQuadCurve(
            to: CGPoint(x: cx, y: topY),
            control: CGPoint(x: cx - radius * 0.75, y: topY + radius * 0.5)
        )
        p.closeSubpath()
        return p
    }

    /// Lozenge: four rounded sides meeting at four points.
    static func lozengePath(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2
        let ry = rect.height / 2
        let bulge: CGFloat = 0.55  // 0 = straight, 1 = circular

        p.move(to: CGPoint(x: cx, y: cy - ry))
        p.addQuadCurve(
            to: CGPoint(x: cx + rx, y: cy),
            control: CGPoint(x: cx + rx * bulge, y: cy - ry * bulge)
        )
        p.addQuadCurve(
            to: CGPoint(x: cx, y: cy + ry),
            control: CGPoint(x: cx + rx * bulge, y: cy + ry * bulge)
        )
        p.addQuadCurve(
            to: CGPoint(x: cx - rx, y: cy),
            control: CGPoint(x: cx - rx * bulge, y: cy + ry * bulge)
        )
        p.addQuadCurve(
            to: CGPoint(x: cx, y: cy - ry),
            control: CGPoint(x: cx - rx * bulge, y: cy - ry * bulge)
        )
        p.closeSubpath()
        return p
    }
}
