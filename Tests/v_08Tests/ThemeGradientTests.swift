// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import XCTest
import SwiftUI
@testable import v_08

final class ThemeGradientTests: XCTestCase {

    // MARK: - Parse — linear form

    func test_parse_linearWithAllThreeParts() {
        let g = ThemeGradient.parse("#FFFFFF,#000000,90")
        XCTAssertNotNil(g)
        if case .linear(let angle) = g?.direction {
            XCTAssertEqual(angle, 90)
        } else {
            XCTFail("expected linear direction")
        }
    }

    func test_parse_linearDefaultsAngleTo180() {
        let g = ThemeGradient.parse("#FFFFFF,#000000")
        XCTAssertNotNil(g)
        if case .linear(let angle) = g?.direction {
            XCTAssertEqual(angle, 180)
        } else {
            XCTFail("expected linear direction")
        }
    }

    // MARK: - Parse — radial form

    func test_parse_radialPrefix() {
        let g = ThemeGradient.parse("radial:#FF00FF,#00FF00")
        XCTAssertNotNil(g)
        XCTAssertEqual(g?.direction, .radial)
    }

    func test_parse_radialRequiresTwoColors() {
        XCTAssertNil(ThemeGradient.parse("radial:#FF00FF"))
    }

    // MARK: - Parse — malformed input

    func test_parse_emptyStringReturnsNil() {
        XCTAssertNil(ThemeGradient.parse(""))
        XCTAssertNil(ThemeGradient.parse("   "))
    }

    func test_parse_singleColorReturnsNil() {
        XCTAssertNil(ThemeGradient.parse("#FFFFFF"))
    }

    func test_parse_invalidAngleFallsBackToDefault() {
        // Angle "xyz" can't parse → falls back to 180 default, gradient still valid.
        let g = ThemeGradient.parse("#FFFFFF,#000000,xyz")
        XCTAssertNotNil(g)
        if case .linear(let angle) = g?.direction {
            XCTAssertEqual(angle, 180)
        }
    }

    func test_parse_trimsWhitespace() {
        let g = ThemeGradient.parse("  #FFFFFF , #000000 , 45  ")
        XCTAssertNotNil(g)
        if case .linear(let angle) = g?.direction {
            XCTAssertEqual(angle, 45)
        }
    }

    // MARK: - unitPoints — angle conversion

    func test_unitPoints_zeroDegreesIsTopToBottom() {
        // CSS 0° = top → gradient starts at top (y=0), ends at bottom (y=1).
        let (start, end) = ThemeGradient.unitPoints(forAngleDegrees: 0)
        XCTAssertEqual(start.y, 0, accuracy: 0.01)
        XCTAssertEqual(end.y, 1, accuracy: 0.01)
    }

    func test_unitPoints_90DegreesIsLeftToRight() {
        let (start, end) = ThemeGradient.unitPoints(forAngleDegrees: 90)
        XCTAssertEqual(start.x, 0, accuracy: 0.01)
        XCTAssertEqual(end.x, 1, accuracy: 0.01)
    }

    func test_unitPoints_180DegreesIsBottomToTop() {
        let (start, end) = ThemeGradient.unitPoints(forAngleDegrees: 180)
        XCTAssertEqual(start.y, 1, accuracy: 0.01)
        XCTAssertEqual(end.y, 0, accuracy: 0.01)
    }

    func test_unitPoints_negativeAngleNormalizes() {
        let (s1, e1) = ThemeGradient.unitPoints(forAngleDegrees: -90)
        let (s2, e2) = ThemeGradient.unitPoints(forAngleDegrees: 270)
        XCTAssertEqual(s1.x, s2.x, accuracy: 0.01)
        XCTAssertEqual(s1.y, s2.y, accuracy: 0.01)
        XCTAssertEqual(e1.x, e2.x, accuracy: 0.01)
        XCTAssertEqual(e1.y, e2.y, accuracy: 0.01)
    }

    // MARK: - asShapeStyle produces a valid style

    func test_asShapeStyle_linearReturnsNonNil() {
        let g = ThemeGradient(
            startColor: .red, endColor: .blue,
            direction: .linear(angleDegrees: 45)
        )
        // No assertion other than it doesn't crash — SwiftUI gradient
        // internals aren't directly inspectable. Smoke test.
        _ = g.asShapeStyle()
    }

    func test_asShapeStyle_radialReturnsNonNil() {
        let g = ThemeGradient(
            startColor: .red, endColor: .blue,
            direction: .radial
        )
        _ = g.asShapeStyle()
    }
}
