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

    // MARK: - Operator Tests

    func testPostfixPipeNoMargin() {
        let row = view1|
        XCTAssertEqual(row.views.count, 1)
        XCTAssertTrue(row.views[0] === view1)
        XCTAssertEqual(row.trailingMargin, 0)
        XCTAssertNil(row.leadingMargin)
    }

    func testPostfixDashPipeDefaultMargin() {
        let row = view1-|
        XCTAssertEqual(row.views.count, 1)
        XCTAssertEqual(row.trailingMargin, visualLayoutDefaultMargin)
        XCTAssertNil(row.leadingMargin)
    }

    func testPrefixPipeNoMargin() {
        let row = |view1|    // postfix | then prefix |
        XCTAssertEqual(row.leadingMargin, 0)
        XCTAssertEqual(row.trailingMargin, 0)
    }

    func testPrefixDashPipeZeroMargin() {
        let row = |-view1-|  // postfix -| then prefix |-
        XCTAssertEqual(row.leadingMargin, 0)
        XCTAssertEqual(row.trailingMargin, 0)
    }

    func testColonEqualsAssignsHeight() {
        let row = |-view1-| /=/ 44
        XCTAssertEqual(row.height, 44)
        XCTAssertEqual(row.heightRelation, .equal)
    }

    func testMultiViewArrayPostfixOperator() {
        let row = |-[view1, view2]-|
        XCTAssertEqual(row.views.count, 2)
        XCTAssertTrue(row.views[0] === view1)
        XCTAssertTrue(row.views[1] === view2)
        XCTAssertEqual(row.leadingMargin, 0)
        XCTAssertEqual(row.trailingMargin, 0)
    }

    // MARK: - layout(in:) Single View

    func testSingleViewWithMarginsAndHeight() {
        let constraints = layout(in: container) {
            100
            |-view1-| /=/ 44
            0
        }
        XCTAssertEqual(constraints.count, 5)

        let top = constraints[0]
        XCTAssertTrue(top.firstItem === view1)
        XCTAssertEqual(top.firstAttribute, .top)
        XCTAssertTrue(top.secondItem === container)
        XCTAssertEqual(top.secondAttribute, .top)
        XCTAssertEqual(top.constant, 100)
        XCTAssertEqual(top.relation, .equal)
        XCTAssertTrue(top.isActive)

        let leading = constraints[1]
        XCTAssertTrue(leading.firstItem === view1)
        XCTAssertEqual(leading.firstAttribute, .leading)
        XCTAssertTrue(leading.secondItem === container)
        XCTAssertEqual(leading.secondAttribute, .leading)
        XCTAssertEqual(leading.constant, 0)

        let trailing = constraints[2]
        XCTAssertTrue(trailing.firstItem === view1)
        XCTAssertEqual(trailing.firstAttribute, .trailing)
        XCTAssertTrue(trailing.secondItem === container)
        XCTAssertEqual(trailing.secondAttribute, .trailing)
        XCTAssertEqual(trailing.constant, 0)

        let height = constraints[3]
        XCTAssertTrue(height.firstItem === view1)
        XCTAssertEqual(height.firstAttribute, .height)
        XCTAssertNil(height.secondItem)
        XCTAssertEqual(height.secondAttribute, .notAnAttribute)
        XCTAssertEqual(height.constant, 44)
        XCTAssertEqual(height.relation, .equal)

        let bottom = constraints[4]
        XCTAssertTrue(bottom.firstItem === container)
        XCTAssertEqual(bottom.firstAttribute, .bottom)
        XCTAssertTrue(bottom.secondItem === view1)
        XCTAssertEqual(bottom.secondAttribute, .bottom)
        XCTAssertEqual(bottom.constant, 0)
    }

    func testEdgePinnedViewNoMargin() {
        let constraints = layout(in: container) {
            |view1|
        }
        XCTAssertEqual(constraints.count, 3)
        XCTAssertEqual(constraints[1].constant, 0)
        XCTAssertEqual(constraints[2].constant, 0)
    }

    func testViewWithNoHeightHasNoHeightConstraint() {
        let constraints = layout(in: container) {
            |-view1-|
        }
        XCTAssertEqual(constraints.count, 3)
        XCTAssertFalse(constraints.contains { $0.firstAttribute == .height })
    }

    func testNoTrailingNumberLeavesBottomUnconstrained() {
        let constraints = layout(in: container) {
            |-view1-| /=/ 44
        }
        XCTAssertEqual(constraints.count, 4)
        XCTAssertFalse(constraints.contains { $0.firstItem === container && $0.firstAttribute == .bottom })
    }

    func testTwoViewsVerticalSpacing() {
        let constraints = layout(in: container) {
            |-view1-| /=/ 44
            8
            |-view2-| /=/ 50
        }
        XCTAssertEqual(constraints.count, 8)

        let view2Top = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .top
        }
        XCTAssertNotNil(view2Top)
        XCTAssertTrue(view2Top?.secondItem === view1)
        XCTAssertEqual(view2Top?.secondAttribute, .bottom)
        XCTAssertEqual(view2Top?.constant, 8)
    }

    // MARK: - layout(in:) Multi-View Row

    func testMultiViewRowEqualWidthsAndSpacing() {
        let constraints = layout(in: container) {
            |-[view1, view2]-| /=/ 44
        }
        XCTAssertEqual(constraints.count, 8)

        let alignedTop = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .top &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .top
        }
        XCTAssertNotNil(alignedTop)

        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertNotNil(leading)
        XCTAssertEqual(leading?.constant, 0)

        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertNotNil(trailing)
        XCTAssertEqual(trailing?.constant, 0)

        let widthC = constraints.first {
            $0.firstAttribute == .width && $0.secondAttribute == .width
        }
        XCTAssertNotNil(widthC)
        XCTAssertEqual(widthC?.multiplier, 1)

        let spacingC = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertNotNil(spacingC)
        XCTAssertEqual(spacingC?.constant, 8)

        let view1Height = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .height
        }
        XCTAssertNotNil(view1Height)
        XCTAssertEqual(view1Height?.constant, 44)

        let view2Height = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .height
        }
        XCTAssertNotNil(view2Height)
        XCTAssertEqual(view2Height?.constant, 44)
    }

    func testThreeViewMultiRow() {
        let constraints = layout(in: container) {
            |-[view1, view2, view3]-|
        }
        XCTAssertEqual(constraints.count, 9)

        let widthEquality = constraints.first {
            $0.firstAttribute == .width && $0.secondAttribute == .width
        }
        XCTAssertNotNil(widthEquality)

        let interViewSpacing = constraints.first {
            $0.firstAttribute == .leading && $0.secondAttribute == .trailing
        }
        XCTAssertNotNil(interViewSpacing)
    }

    // MARK: - -- custom inter-view spacing

    func testChainOperatorCustomSpacing() {
        let constraints = layout(in: container) {
            |-view1--20--view2-|
        }
        let spacingC = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertNotNil(spacingC)
        XCTAssertEqual(spacingC?.constant, 20)
    }

    func testChainOperatorThreeViewsCustomSpacing() {
        let constraints = layout(in: container) {
            |-view1--20--view2--30--view3-|
        }
        let gap12 = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(gap12?.constant, 20)

        let gap23 = constraints.first {
            ($0.firstItem as? TestView) === view3 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view2 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(gap23?.constant, 30)
    }

    func testChainOperatorDefaultSpacingWhenOmitted() {
        let constraints = layout(in: container) {
            |-view1--view2-|
        }
        let spacingC = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(spacingC?.constant, visualLayoutDefaultMargin)
    }

    func testChainOperatorAlignedTops() {
        let constraints = layout(in: container) {
            |-view1--20--view2-|
        }
        let topAlign = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .top &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .top
        }
        XCTAssertNotNil(topAlign)
    }

    // MARK: - -- explicit leading + trailing (no postfix needed)

    func testChainBothMarginsExplicit() {
        // 20--a--3--b--10  → leading=20, spacing=3, trailing=10 (via buildExpression)
        let constraints = layout(in: container) {
            20--view1--3--view2--10
        }
        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertEqual(leading?.constant, 20)
        let spacing = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading && $0.secondAttribute == .trailing
        }
        XCTAssertEqual(spacing?.constant, 3)
        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertEqual(trailing?.constant, -10)
    }

    func testChainLeadingOnlyNoTrailing() {
        // 20--a--3--b  → leading=20, spacing=3, trailing unconstrained
        let constraints = layout(in: container) {
            20--view1--3--view2
        }
        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertEqual(leading?.constant, 20)
        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertNil(trailing, "no trailing number → no trailing constraint")
    }

    func testChainTrailingOnlyNoLeading() {
        // a--3--b--10  → leading unconstrained, spacing=3, trailing=10
        let constraints = layout(in: container) {
            view1--3--view2--10
        }
        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertNil(leading, "no leading number → no leading constraint")
        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertEqual(trailing?.constant, -10)
    }

    // MARK: - -- custom leading margin via leading number (postfix style)

    func testLeadingNumberSetsLeadingMargin() {
        // 20--a--3--b| → leading=20, spacing=3, trailing=0
        let constraints = layout(in: container) {
            20--view1--3--view2|
        }
        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertNotNil(leading)
        XCTAssertEqual(leading?.constant, 20)

        let spacing = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(spacing?.constant, 3)

        // trailing=0 → constant = -0 = 0
        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertNotNil(trailing)
        XCTAssertEqual(trailing?.constant, 0, "trailing margin 0 → constraint constant should be 0")
    }

    // MARK: - layout(in:) Flexible Spacing

    func testAtLeastSpacingBeforeView() {
        let constraints = layout(in: container) {
            atLeast(20)
            |view1|
        }
        XCTAssertEqual(constraints.count, 3)
        XCTAssertEqual(constraints[0].relation, .greaterThanOrEqual)
        XCTAssertEqual(constraints[0].constant, 20)
    }

    func testAtMostTrailingSpacing() {
        let constraints = layout(in: container) {
            |-view1-|
            atMost(30)
        }
        XCTAssertEqual(constraints.count, 4)
        let bottom = constraints[3]
        XCTAssertTrue(bottom.firstItem === container)
        XCTAssertEqual(bottom.firstAttribute, .bottom)
        XCTAssertEqual(bottom.relation, .lessThanOrEqual)
        XCTAssertEqual(bottom.constant, 30)
    }

    func testAtLeastTrailingSpacing() {
        let constraints = layout(in: container) {
            |-view1-|
            atLeast(16)
        }
        XCTAssertEqual(constraints.count, 4)
        let bottom = constraints[3]
        XCTAssertTrue(bottom.firstItem === container)
        XCTAssertEqual(bottom.firstAttribute, .bottom)
        XCTAssertEqual(bottom.relation, .greaterThanOrEqual)
        XCTAssertEqual(bottom.constant, 16)
    }

    func testTranslatesAutoresizingMaskIsDisabled() {
        _ = layout(in: container) {
            |-view1-|
        }
        XCTAssertFalse(view1.translatesAutoresizingMaskIntoConstraints)
    }

    // MARK: - Auto-addSubview

    func testLayoutAutoAddsViewsWithoutSuperview() {
        let orphan1 = TestView()
        let orphan2 = TestView()
        XCTAssertNil(orphan1.superview)
        XCTAssertNil(orphan2.superview)

        _ = layout(in: container) {
            |-orphan1-| /=/ 30
            8
            |-orphan2-| /=/ 30
        }

        XCTAssertTrue(orphan1.superview === container)
        XCTAssertTrue(orphan2.superview === container)
    }

    func testLayoutAutoAddsGuideWithoutOwningView() {
        let guide = VisualLayoutGuide()
        XCTAssertNil(guide.owningView)

        _ = layout(in: container) {
            |-guide-| /=/ 30
        }

        XCTAssertTrue(guide.owningView === container)
    }

    func testGuideConstraintsAreGenerated() {
        let guide = VisualLayoutGuide()
        let constraints = layout(in: container) {
            |-guide-| /=/ 44
        }

        let leading = constraints.first {
            $0.firstItem === guide && $0.firstAttribute == .leading
        }
        XCTAssertNotNil(leading)
        XCTAssertEqual(leading?.constant, 0)

        let trailing = constraints.first {
            $0.firstItem === guide && $0.firstAttribute == .trailing
        }
        XCTAssertNotNil(trailing)
        XCTAssertEqual(trailing?.constant, 0)

        let height = constraints.first {
            $0.firstItem === guide && $0.firstAttribute == .height
        }
        XCTAssertNotNil(height)
        XCTAssertEqual(height?.constant, 44)
    }

    func testLayoutDoesNotReparentAlreadyAddedViews() {
        // view1 is already added to container in setUp — should stay there
        XCTAssertTrue(view1.superview === container)
        _ = layout(in: container) {
            |-view1-| /=/ 30
        }
        XCTAssertTrue(view1.superview === container)
    }

    // MARK: - Explicit margin syntax (|-- / --)

    func testPipeExplicitMargins() {
        // |16 -- view -- 16| — leading=16, trailing=16
        let constraints = layout(in: container) {
            |16 -- view1 -- 16| /=/ 44
        }
        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertEqual(leading?.constant, 16)

        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .trailing
        }
        XCTAssertEqual(trailing?.constant, -16)
    }

    func testDoubleDashPipeExplicitMargins() {
        // |--16 -- view -- 16--| — leading=16, trailing=16
        let constraints = layout(in: container) {
            |--16 -- view1 -- 16--| /=/ 44
        }
        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertEqual(leading?.constant, 16)

        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .trailing
        }
        XCTAssertEqual(trailing?.constant, -16)
    }

    func testDoubleDashMultiViewExplicitMargins() {
        // |8 -- view1 -- 12 -- view2 -- 8| — leading=8, inter=12, trailing=8
        let constraints = layout(in: container) {
            |8 -- view1 -- 12 -- view2 -- 8|
        }
        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertEqual(leading?.constant, 8)

        let spacing = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(spacing?.constant, 12)

        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertEqual(trailing?.constant, -8)
    }
}
