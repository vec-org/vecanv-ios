// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import XCTest
import SwiftUI
@testable import v_08

final class VecanvThemeExtrasTests: XCTestCase {

    // MARK: - Full parse round-trip on the vecanv seed

    /// Matches the exact keys seeded by cloud migration 022 — guarantees
    /// end-to-end parser coverage of the canonical base theme.
    func test_parse_vecanvBaseTheme() {
        let styles: [String: String] = [
            "primaryColor":           "#4A8FE7",
            "secondaryColor":         "#7AB8F5",
            "accentColor":            "#2E6FC7",
            "backgroundColor":        "#F4F8FE",
            "cardBackgroundColor":    "#FFFFFF",
            "cardBorderColor":        "#DCE8F7",
            "font":                   "SF Pro Rounded",
            "fontWeightBody":         "regular",
            "fontWeightHeading":      "semibold",
            "cardCornerRadius":       "24",
            "cardShape":              "bubble",
            "cardFillGradient":       "#FFFFFF,#EAF3FD,135",
            "cardShadowOpacity":      "0.06",
            "buttonCornerRadius":     "22",
            "buttonShape":            "pill",
            "buttonPrimaryFill":      "#4A8FE7",
            "buttonPrimaryTextColor": "#FFFFFF",
            "buttonSecondaryFill":    "transparent",
            "buttonSecondaryBorder":  "#4A8FE7",
            "buttonSecondaryText":    "#2E6FC7",
            "textFieldCornerRadius":  "22",
            "textFieldBackground":    "#FFFFFF",
            "textFieldBorder":        "#BFD7F2",
            "backgroundGradient":     "#F4F8FE,#E6EEFB,180",
            "animationSpeed":         "medium",
            "cardAnimation":          "breathe",
            "chartLineColor":         "#4A8FE7",
            "chartFillOpacity":       "0.18",
            "chartFillGradient":      "#4A8FE7,#7AB8F5,180",
        ]
        let e = VecanvThemeExtras.parse(from: styles)

        XCTAssertEqual(e.cardShape, .bubble)
        XCTAssertEqual(e.buttonShape, .pill)
        XCTAssertNotNil(e.cardFillGradient)
        XCTAssertNotNil(e.backgroundGradient)
        XCTAssertNotNil(e.chartFillGradient)
        XCTAssertNotNil(e.cardBorderColor)
        XCTAssertNotNil(e.textFieldBorderColor)
        XCTAssertNotNil(e.buttonSecondaryBorderColor)
        XCTAssertNotNil(e.buttonPrimaryFill)
        XCTAssertEqual(e.buttonSecondaryFill, .clear)
        XCTAssertNotNil(e.buttonPrimaryTextColor)
        XCTAssertNotNil(e.buttonSecondaryTextColor)
        XCTAssertNotNil(e.textFieldBackground)
        XCTAssertEqual(e.textFieldCornerRadius, 22)
        XCTAssertNotNil(e.chartLineColor)
        XCTAssertEqual(e.chartFillOpacity, 0.18)
        XCTAssertEqual(e.cardShadowOpacity, 0.06)
        XCTAssertEqual(e.cardAnimation, .breathe)
        XCTAssertEqual(e.animationSpeed, .medium)
    }

    // MARK: - Empty dict → all-nil extras

    func test_parse_emptyDict_returnsDefaultEmptyExtras() {
        let e = VecanvThemeExtras.parse(from: [:])
        XCTAssertNil(e.cardShape)
        XCTAssertNil(e.buttonShape)
        XCTAssertNil(e.cardFillGradient)
        XCTAssertNil(e.backgroundGradient)
        XCTAssertNil(e.cardBorderColor)
        XCTAssertNil(e.cardAnimation)
        XCTAssertNil(e.animationSpeed)
    }

    // MARK: - Graceful degradation on malformed values

    func test_parse_invalidShapeKind_dropsSilently() {
        let e = VecanvThemeExtras.parse(from: ["cardShape": "hexagon"])
        XCTAssertNil(e.cardShape)
    }

    func test_parse_invalidGradient_dropsSilently() {
        let e = VecanvThemeExtras.parse(from: ["cardFillGradient": "not-a-gradient"])
        XCTAssertNil(e.cardFillGradient)
    }

    func test_parse_transparentKeywordMapsToClear() {
        let e = VecanvThemeExtras.parse(from: ["buttonSecondaryFill": "transparent"])
        XCTAssertEqual(e.buttonSecondaryFill, .clear)
    }

    // MARK: - Individual key behaviors

    func test_parse_cardShapeBubble() {
        let e = VecanvThemeExtras.parse(from: ["cardShape": "bubble"])
        XCTAssertEqual(e.cardShape, .bubble)
    }

    func test_parse_cardFillGradientReturnsParsedGradient() {
        let e = VecanvThemeExtras.parse(from: [
            "cardFillGradient": "#FFFFFF,#000000,90",
        ])
        XCTAssertNotNil(e.cardFillGradient)
        if case .linear(let angle) = e.cardFillGradient?.direction {
            XCTAssertEqual(angle, 90)
        } else {
            XCTFail("expected linear gradient")
        }
    }

    func test_parse_animationSpeedUnknownDrops() {
        let e = VecanvThemeExtras.parse(from: ["animationSpeed": "blazing"])
        XCTAssertNil(e.animationSpeed)
    }
}


// MARK: - A2UIStyle parser extension tests

final class A2UIStyleThemeParsingTests: XCTestCase {

    func test_init_from_parsesCardCornerRadius() {
        let s = A2UIStyle(from: ["cardCornerRadius": "24"])
        XCTAssertEqual(s.cardStyle.cornerRadius, 24)
    }

    func test_init_from_parsesCardBackgroundColor() {
        let s = A2UIStyle(from: ["cardBackgroundColor": "#FF00FF"])
        XCTAssertNotNil(s.cardStyle.backgroundColor)
    }

    func test_init_from_parsesPrimaryButtonVariant() {
        let s = A2UIStyle(from: [
            "buttonPrimaryFill": "#4A8FE7",
            "buttonPrimaryTextColor": "#FFFFFF",
            "buttonCornerRadius": "22",
        ])
        let primary = s.buttonStyles["primary"]
        XCTAssertNotNil(primary)
        XCTAssertNotNil(primary?.backgroundColor)
        XCTAssertNotNil(primary?.foregroundColor)
        XCTAssertEqual(primary?.cornerRadius, 22)
    }

    func test_init_from_parsesSecondaryAsTransparent() {
        let s = A2UIStyle(from: [
            "buttonSecondaryFill": "transparent",
            "buttonCornerRadius": "22",
        ])
        let def = s.buttonStyles["default"]
        XCTAssertNotNil(def)
        XCTAssertEqual(def?.backgroundColor, .clear)
    }

    func test_init_from_parsesPrimaryColor() {
        let s = A2UIStyle(from: ["primaryColor": "#4A8FE7"])
        XCTAssertNotEqual(s.primaryColor, .accentColor)
    }

    func test_init_from_emptyDictFallsBack() {
        let s = A2UIStyle(from: [:])
        XCTAssertEqual(s.primaryColor, .accentColor)
        XCTAssertNil(s.cardStyle.cornerRadius)
        XCTAssertTrue(s.buttonStyles.isEmpty)
    }

    func test_init_from_absentButtonTextColorStillProducesVariant() {
        let s = A2UIStyle(from: ["buttonPrimaryFill": "#4A8FE7"])
        let primary = s.buttonStyles["primary"]
        XCTAssertNotNil(primary)
        XCTAssertNil(primary?.foregroundColor)  // omitted → nil
    }
}
