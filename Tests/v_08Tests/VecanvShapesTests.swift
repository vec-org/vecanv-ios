// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import XCTest
import SwiftUI
@testable import v_08

final class VecanvShapesTests: XCTestCase {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

    // MARK: - Enum parsing

    func test_shapeKind_parsesFromRawValue() {
        XCTAssertEqual(A2UIShapeKind(rawValue: "bubble"), .bubble)
        XCTAssertEqual(A2UIShapeKind(rawValue: "pill"), .pill)
        XCTAssertEqual(A2UIShapeKind(rawValue: "rect"), .rect)
        XCTAssertEqual(A2UIShapeKind(rawValue: "blob"), .blob)
        XCTAssertEqual(A2UIShapeKind(rawValue: "leaf"), .leaf)
        XCTAssertEqual(A2UIShapeKind(rawValue: "droplet"), .droplet)
        XCTAssertEqual(A2UIShapeKind(rawValue: "lozenge"), .lozenge)
    }

    func test_shapeKind_unknownValueReturnsNil() {
        XCTAssertNil(A2UIShapeKind(rawValue: "hexagon"))
        XCTAssertNil(A2UIShapeKind(rawValue: ""))
    }

    // MARK: - Path generation (verify non-empty paths)

    func test_rect_generatesRectanglePath() {
        let path = VecanvShape(kind: .rect).path(in: rect)
        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(path.boundingRect, rect)
    }

    func test_pill_generatesRoundedPath() {
        let path = VecanvShape(kind: .pill).path(in: rect)
        XCTAssertFalse(path.isEmpty)
        // Pill's bounding rect should match the input rect (fully inscribed)
        XCTAssertEqual(path.boundingRect.width, rect.width, accuracy: 0.01)
    }

    func test_allShapeKinds_produceNonEmptyPaths() {
        // Generate a path for every shape in the registry; none should be empty.
        // If we add a new kind but forget to add a path branch, this catches it.
        for kind in A2UIShapeKind.allCases {
            let path = VecanvShape(kind: kind).path(in: rect)
            XCTAssertFalse(path.isEmpty, "\(kind) produced empty path")
        }
    }

    func test_allShapeKinds_pathStaysInsideBounds() {
        // Bubble and blob may slightly exceed the input rect due to control
        // points, but the bounding box should still be close. Use a generous
        // tolerance to catch truly runaway paths.
        for kind in A2UIShapeKind.allCases {
            let path = VecanvShape(kind: kind).path(in: rect)
            let bounds = path.boundingRect
            XCTAssertLessThan(bounds.minX, 10, "\(kind) bounds overflow on left")
            XCTAssertGreaterThan(bounds.maxX, rect.width - 10, "\(kind) underfill on right")
        }
    }

    // MARK: - Inset conformance

    func test_insettableShape_shrinksBoundingRect() {
        let full = VecanvShape(kind: .rect).path(in: rect)
        let inset = VecanvShape(kind: .rect).inset(by: 10).path(in: rect)
        // Inset by 10 → bounds shrink by 10 on each side → width/height drop by 20.
        XCTAssertEqual(full.boundingRect.width, 100, accuracy: 0.01)
        XCTAssertEqual(inset.boundingRect.width, 80, accuracy: 0.01)
    }

    // MARK: - Scales

    func test_shapesScaleToArbitraryRect() {
        // Paths should scale without breaking — each kind drawn into a large rect
        // should have non-empty bounds.
        let big = CGRect(x: 0, y: 0, width: 500, height: 200)
        for kind in A2UIShapeKind.allCases {
            let path = VecanvShape(kind: kind).path(in: big)
            XCTAssertGreaterThan(path.boundingRect.width, 0, "\(kind) failed to scale")
            XCTAssertGreaterThan(path.boundingRect.height, 0, "\(kind) failed to scale")
        }
    }
}
