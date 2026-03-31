//
//  VisualLayoutTests.swift
//  ZDTinyLayoutTests
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@testable import ZDTinyLayout
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

    func testPostfixDashPipeZeroMargin() {
        let row = view1--|
        XCTAssertEqual(row.views.count, 1)
        XCTAssertEqual(row.trailingMargin, 0)
        XCTAssertNil(row.leadingMargin)
    }

    func testPrefixPipeNoMargin() {
        let row = |view1|    // postfix | then prefix |
        XCTAssertEqual(row.leadingMargin, 0)
        XCTAssertEqual(row.trailingMargin, 0)
    }

    func testPrefixDashPipeZeroMargin() {
        let row = |--view1--|  // postfix --| then prefix |--
        XCTAssertEqual(row.leadingMargin, 0)
        XCTAssertEqual(row.trailingMargin, 0)
    }

    func testColonEqualsAssignsHeight() {
        let row = |--view1--| /=/ 44
        XCTAssertEqual(row.height, 44)
        XCTAssertEqual(row.heightRelation, .equal)
    }

    func testMultiViewArrayPostfixOperator() {
        let row = |--[view1, view2]--|
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
            |--view1--| /=/ 44
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
        XCTAssertEqual(constraints.count, 4)
        XCTAssertEqual(constraints[1].constant, 0)
        XCTAssertEqual(constraints[2].constant, 0)
    }

    func testViewWithNoHeightHasNoHeightConstraint() {
        let constraints = layout(in: container) {
            |--view1--|
        }
        XCTAssertEqual(constraints.count, 4)
        XCTAssertFalse(constraints.contains { $0.firstAttribute == .height })
    }

    func testNoTrailingNumberDefaultsBottomToZero() {
        let constraints = layout(in: container) {
            |--view1--| /=/ 44
        }
        XCTAssertEqual(constraints.count, 5)
        let bottom = constraints.first {
            $0.firstItem === container && $0.firstAttribute == .bottom
        }
        XCTAssertNotNil(bottom)
        XCTAssertEqual(bottom?.constant, 0)
    }

    func testTwoViewsVerticalSpacing() {
        let constraints = layout(in: container) {
            |--view1--| /=/ 44
            8
            |--view2--| /=/ 50
        }
        XCTAssertEqual(constraints.count, 9)

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
            |--[view1, view2]--| /=/ 44
        }
        XCTAssertEqual(constraints.count, 9)

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
        XCTAssertEqual(spacingC?.constant, 0)

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
            |--[view1, view2, view3]--|
        }
        XCTAssertEqual(constraints.count, 10)

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
            |--view1--20--view2--|
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
            |--view1--20--view2--30--view3--|
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

    func testArraySyntaxSupportsCustomInterViewSpacingValues() {
        let constraints = layout(in: container) {
            |--[view1, 10, view2, 50.0, view3]--|
        }

        let gap12 = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(gap12?.constant, 10)

        let gap23 = constraints.first {
            ($0.firstItem as? TestView) === view3 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view2 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(gap23?.constant, 50.0)
    }

    func testArraySyntaxFallsBackToZeroSpacingWhenGapIsOmitted() {
        let constraints = layout(in: container) {
            |--[view1, 10, view2, view3]--|
        }

        let gap12 = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(gap12?.constant, 10)

        let gap23 = constraints.first {
            ($0.firstItem as? TestView) === view3 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view2 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(gap23?.constant, 0)
    }

    func testChainOperatorDefaultSpacingWhenOmitted() {
        let constraints = layout(in: container) {
            |--view1--view2--|
        }
        let spacingC = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(spacingC?.constant, 0)
    }

    func testChainOperatorAlignedTops() {
        let constraints = layout(in: container) {
            |--view1--20--view2--|
        }
        let topAlign = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .top &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .top
        }
        XCTAssertNotNil(topAlign)
    }

    // MARK: - |-- / --| explicit leading + trailing fences

    func testFencedExplicitMarginsAllEdges() {
        // |--20--a--3--b--10--| → leading=20, spacing=3, trailing=10
        let constraints = layout(in: container) {
            |--20--view1--3--view2--10--|
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

    func testFencedExplicitMargins_DefaultInterViewSpacingIsZero() {
        // |--15--a--b--20--| → leading=15, spacing=0, trailing=20
        let constraints = layout(in: container) {
            |--15--view1--view2--20--|
        }

        let spacing = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(spacing?.constant, 0)
    }

    func testFencedExplicitMarginsWithArrayAndIntLiterals() {
        // |--15--[a,b]--20--| should compile and apply both explicit margins.
        let constraints = layout(in: container) {
            |--15--[view1, view2]--20--| /=/ 50
        }

        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertEqual(leading?.constant, 15)

        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertEqual(trailing?.constant, -20)

        let view1Height = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .height
        }
        XCTAssertEqual(view1Height?.constant, 50)

        let view2Height = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .height
        }
        XCTAssertEqual(view2Height?.constant, 50)
    }

    func testFencedExplicitMarginsWithMixedArrayCustomSpacing() {
        // |--15--[a,50,b]--20--| should compile and apply leading/inter/trailing margins.
        let constraints = layout(in: container) {
            |--15--[view1, 50, view2]--20--|
        }

        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertEqual(leading?.constant, 15)

        let spacing = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertEqual(spacing?.constant, 50)

        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertEqual(trailing?.constant, -20)
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

    // MARK: - layout(in:) Spacing edge cases

    func testConsecutiveSpacingsLastOneWins() {
        // Two spacing literals in a row — the second silently overwrites the first.
        // This is the specified behavior: only the most recent pending spacing is applied.
        let constraints = layout(in: container) {
            8
            16
            |--view1--|
        }
        let topC = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .top
        }
        XCTAssertEqual(topC?.constant, 16, "last spacing wins when two appear consecutively")
    }

    func testAdjacentRowsWithoutSpacingDefaultsToZero() {
        // No spacing between two rows → top of second view is flush to bottom of first.
        let constraints = layout(in: container) {
            |--view1--| /=/ 44
            |--view2--| /=/ 44
        }
        let view2Top = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .top
        }
        XCTAssertNotNil(view2Top)
        XCTAssertTrue(view2Top?.secondItem === view1)
        XCTAssertEqual(view2Top?.secondAttribute, .bottom)
        XCTAssertEqual(view2Top?.constant, 0)
    }

    // MARK: - layout(in:) Flexible Spacing

    func testAtLeastSpacingBeforeView() {
        let constraints = layout(in: container) {
            atLeast(20)
            |view1|
        }
        XCTAssertEqual(constraints.count, 4)
        XCTAssertEqual(constraints[0].relation, .greaterThanOrEqual)
        XCTAssertEqual(constraints[0].constant, 20)
    }

    func testAtMostTrailingSpacing() {
        let constraints = layout(in: container) {
            |--view1--|
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
            |--view1--|
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
            |--view1--|
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
            |--orphan1--| /=/ 30
            8
            |--orphan2--| /=/ 30
        }

        XCTAssertTrue(orphan1.superview === container)
        XCTAssertTrue(orphan2.superview === container)
    }

    func testLayoutAutoAddsGuideWithoutOwningView() {
        let guide = VisualLayoutGuide()
        XCTAssertNil(guide.owningView)

        _ = layout(in: container) {
            |--guide--| /=/ 30
        }

        XCTAssertTrue(guide.owningView === container)
    }

    func testLayoutKeepsGuideAlreadyAddedToContainer() {
        let guide = VisualLayoutGuide()
        container.addLayoutGuide(guide)
        XCTAssertTrue(guide.owningView === container)

        _ = layout(in: container) {
            |--guide--| /=/ 30
        }

        XCTAssertTrue(guide.owningView === container)
    }

    func testGuideConstraintsAreGenerated() {
        let guide = VisualLayoutGuide()
        let constraints = layout(in: container) {
            |--guide--| /=/ 44
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
            |--view1--| /=/ 30
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

    // MARK: - Height priority

    func testHeightPriorityOperator() {
        let row = |--view1--| /=/ 44 ~ .high
        XCTAssertEqual(row.height, 44)
        XCTAssertEqual(row.heightPriority, .high)
    }

    func testHeightPriorityAppliedToConstraint() {
        let constraints = layout(in: container) {
            |--view1--| /=/ 44 ~ .high
        }
        let heightC = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .height
        }
        XCTAssertNotNil(heightC)
        XCTAssertEqual(heightC?.priority, Priority.high.value)
    }

    func testDefaultHeightPriorityIsRequired() {
        let constraints = layout(in: container) {
            |--view1--| /=/ 44
        }
        let heightC = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .height
        }
        XCTAssertEqual(heightC?.priority, Priority.required.value)
    }

    func testNestedLayoutWithIntSpacings() {
        let top = TestView()
        let middleLeft = TestView()
        let middleRight = TestView()
        let bottom = TestView()

        let nested = TestView().tl.layout {
            |--top--| /=/ 30
            8
            |--15--[middleLeft, middleRight]--20--| /=/ 50
            8
            |bottom|
        }

        let constraints = layout(in: container) {
            |--8--nested--|
        }

        XCTAssertTrue(top.superview === nested)
        XCTAssertTrue(middleLeft.superview === nested)
        XCTAssertTrue(middleRight.superview === nested)
        XCTAssertTrue(bottom.superview === nested)

        let leading = constraints.first {
            ($0.firstItem as? TestView) === nested && $0.firstAttribute == .leading
        }
        XCTAssertEqual(leading?.constant, 8)
    }

    // MARK: - tl namespace

    func testNamespaceLayoutReturnsReceiverForChaining() {
        let host = TestView()
        let child = TestView()

        let returned: TestView = host.tl.layout {
            |--child--|
        }

        XCTAssertTrue(returned === host)
        XCTAssertTrue(child.superview === host)
    }

    func testFencedExplicitMarginsWithDoubleValues() {
        let lead: Double = 10.5
        let inter: Double = 6.25
        let trail: Double = 12.75
        let height: Double = 40.5

        let constraints = layout(in: container) {
            |--lead--view1--inter--view2--trail--| /=/ height
        }

        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertNotNil(leading)
        XCTAssertEqual(leading!.constant, CGFloat(lead), accuracy: 0.0001)

        let spacing = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertNotNil(spacing)
        XCTAssertEqual(spacing!.constant, CGFloat(inter), accuracy: 0.0001)

        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertNotNil(trailing)
        XCTAssertEqual(trailing!.constant, -CGFloat(trail), accuracy: 0.0001)

        let view1Height = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .height
        }
        XCTAssertNotNil(view1Height)
        XCTAssertEqual(view1Height!.constant, CGFloat(height), accuracy: 0.0001)
    }

    func testFencedExplicitMarginsWithFloatValues() {
        let lead: Float = 9.5
        let inter: Float = 5.5
        let trail: Float = 11.5
        let height: Float = 32.5

        let constraints = layout(in: container) {
            |--lead--view1--inter--view2--trail--| /=/ height
        }

        let leading = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .leading
        }
        XCTAssertNotNil(leading)
        XCTAssertEqual(leading!.constant, CGFloat(lead), accuracy: 0.0001)

        let spacing = constraints.first {
            ($0.firstItem as? TestView) === view2 &&
            $0.firstAttribute == .leading &&
            ($0.secondItem as? TestView) === view1 &&
            $0.secondAttribute == .trailing
        }
        XCTAssertNotNil(spacing)
        XCTAssertEqual(spacing!.constant, CGFloat(inter), accuracy: 0.0001)

        let trailing = constraints.first {
            ($0.firstItem as? TestView) === view2 && $0.firstAttribute == .trailing
        }
        XCTAssertNotNil(trailing)
        XCTAssertEqual(trailing!.constant, -CGFloat(trail), accuracy: 0.0001)

        let view1Height = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .height
        }
        XCTAssertNotNil(view1Height)
        XCTAssertEqual(view1Height!.constant, CGFloat(height), accuracy: 0.0001)
    }

    func testVerticalSpacingBuilderAcceptsFloatExpression() {
        let topSpacing: Float = 7.5
        let bottomSpacing: Float = 4.25

        let constraints = layout(in: container) {
            topSpacing
            |--view1--|
            bottomSpacing
        }

        let top = constraints.first {
            ($0.firstItem as? TestView) === view1 && $0.firstAttribute == .top
        }
        XCTAssertNotNil(top)
        XCTAssertEqual(top!.constant, CGFloat(topSpacing), accuracy: 0.0001)

        let bottom = constraints.first {
            $0.firstItem === container && $0.firstAttribute == .bottom
        }
        XCTAssertNotNil(bottom)
        XCTAssertEqual(bottom!.constant, CGFloat(bottomSpacing), accuracy: 0.0001)
    }
}
