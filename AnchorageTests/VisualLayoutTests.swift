//
//  VisualLayoutTests.swift
//  AnchorageTests
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@testable import Anchorage
import XCTest

class VisualLayoutTests: XCTestCase {

    let container = TestView()
    let view1 = TestView()
    let view2 = TestView()
    let view3 = TestView()
    let window = TestWindow()

    override func setUp() {
        super.setUp()
#if os(macOS)
        window.contentView!.addSubview(container)
#else
        window.addSubview(container)
#endif
        container.addSubview(view1)
        container.addSubview(view2)
        container.addSubview(view3)
    }

    override func tearDown() {
        super.tearDown()
        container.removeFromSuperview()
    }

    // MARK: - Core Type Tests

    func testAtLeastCreatesGreaterThanOrEqualSpacing() {
        let s = atLeast(20)
        XCTAssertEqual(s.points, 20)
        XCTAssertEqual(s.relation, .greaterThanOrEqual)
    }

    func testAtMostCreatesLessThanOrEqualSpacing() {
        let s = atMost(15)
        XCTAssertEqual(s.points, 15)
        XCTAssertEqual(s.relation, .lessThanOrEqual)
    }

    func testVisualRowDefaultHeightRelationIsEqual() {
        let row = VisualRow(views: [view1])
        XCTAssertEqual(row.heightRelation, .equal)
        XCTAssertNil(row.height)
        XCTAssertNil(row.leadingMargin)
        XCTAssertNil(row.trailingMargin)
    }
}
