# Visual Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `layout(in:)` Visual Layout DSL to ZDTinyLayout that lets developers describe Auto Layout using ASCII-style vertical structure with `|-view-| /=/ height` syntax.

**Architecture:** Two new source files — `VisualLayout.swift` (types + `layout(in:)` function) and `VisualLayoutOperators.swift` (operator declarations and overloads). Tests go in a new `VisualLayoutTests.swift` file following the existing XCTest pattern. Existing source files are not modified except `Package.swift` and `ZDTinyLayout.podspec` for the Swift 5.9 version bump.

**Tech Stack:** Swift 5.9, NSLayoutAnchor/NSLayoutConstraint, XCTest, `@resultBuilder`

**Spec:** `docs/superpowers/specs/2026-03-25-visual-layout-design.md`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `Source/VisualLayout.swift` | `VisualLayoutView` public typealias, `VisualLayoutItem` protocol, `VisualRow`/`VisualSpacing`/`VisualFlexibleSpacing` structs, `VisualLayoutBuilder` @resultBuilder, `atLeast`/`atMost` functions, `visualLayoutDefaultMargin` global, `layout(in:)` function + private constraint helpers |
| Create | `Source/VisualLayoutOperators.swift` | All `operator` declarations + public overloads for postfix `\|`/`-\|`, prefix `\|`/`\|-`, infix `/=/` |
| Create | `ZDTinyLayoutTests/VisualLayoutTests.swift` | XCTest suite — operator tests, constraint-attribute tests for `layout(in:)` |
| Modify | `Package.swift` | `swift-tools-version:5.9`, add `.visionOS(.v1)` |
| Modify | `ZDTinyLayout.podspec` | `swift_versions = ['5.9']`, add visionOS deployment target |

---

## Task 1: Update Manifest Files

**Files:**
- Modify: `Package.swift`
- Modify: `ZDTinyLayout.podspec`

- [ ] **Step 1: Update `Package.swift`**

Replace:
```swift
// swift-tools-version:5.1
```
with:
```swift
// swift-tools-version:5.9
```

Replace the `platforms` array:
```swift
platforms: [
    .iOS(.v9),
    .macOS(.v10_11),
    .tvOS(.v9),
    .watchOS(.v7),
    .visionOS(.v1),
],
```

- [ ] **Step 2: Update `ZDTinyLayout.podspec`**

Replace:
```ruby
s.swift_versions = ['4.0', '4.2', '5.0']
```
with:
```ruby
s.swift_versions = ['5.9']
```

Add visionOS deployment target after the existing targets:
```ruby
s.visionos.deployment_target = '1.0'
```

- [ ] **Step 3: Verify the package builds**

Run:
```bash
swift build
```
Expected: Build succeeded. (Tests may still fail — that's fine.)

- [ ] **Step 4: Commit**

```bash
git add Package.swift ZDTinyLayout.podspec
git commit -m "chore: bump minimum Swift version to 5.9, add visionOS platform"
```

---

## Task 2: Core Types — `VisualLayout.swift` (TDD)

**Files:**
- Create: `ZDTinyLayoutTests/VisualLayoutTests.swift`
- Create: `Source/VisualLayout.swift`

### Step 1 — Write failing tests for core types

- [ ] **Create `ZDTinyLayoutTests/VisualLayoutTests.swift`:**

```swift
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
}
```

- [ ] **Step 2: Run tests to verify they fail (types not found)**

Run:
```bash
swift test --filter VisualLayoutTests
```
Expected: Compile error — `atLeast`, `atMost`, `VisualRow` not found.

### Step 3 — Create `Source/VisualLayout.swift`

- [ ] **Create `Source/VisualLayout.swift`:**

```swift
//
//  VisualLayout.swift
//  ZDTinyLayout
//
//  Copyright 2024 Rightpoint and other contributors
//  http://rightpoint.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#if os(macOS)
import Cocoa
/// The platform-specific view type used in Visual Layout APIs.
public typealias VisualLayoutView = NSView
#else
import UIKit
/// The platform-specific view type used in Visual Layout APIs.
public typealias VisualLayoutView = UIView
#endif

// MARK: - Default Margin

/// The default spacing (in points) applied by `|-` and `-|` operators.
/// Defaults to 8. Can be changed globally.
public var visualLayoutDefaultMargin: CGFloat = 8

// MARK: - VisualLayoutItem

/// A type that can appear as a line in a `layout(in:)` block.
public protocol VisualLayoutItem {}

// MARK: - VisualRow

/// Represents one horizontal row in a visual layout block.
/// Built incrementally by the `|`, `|-`, `-|` operators.
public struct VisualRow: VisualLayoutItem {

    internal var views: [VisualLayoutView]

    /// Distance from the container's leading edge. `nil` means no leading constraint.
    /// `0` pins to edge; `8` (default) adds the default margin.
    internal var leadingMargin: CGFloat?

    /// Distance from the container's trailing edge. `nil` means no trailing constraint.
    internal var trailingMargin: CGFloat?

    internal var height: CGFloat?
    internal var heightRelation: NSLayoutConstraint.Relation = .equal

    internal init(
        views: [VisualLayoutView],
        leadingMargin: CGFloat? = nil,
        trailingMargin: CGFloat? = nil
    ) {
        self.views = views
        self.leadingMargin = leadingMargin
        self.trailingMargin = trailingMargin
    }
}

// MARK: - VisualSpacing

/// Fixed vertical spacing. Produced by integer/float literals in a `layout` block.
/// Internal — never exposed directly in the public API.
internal struct VisualSpacing: VisualLayoutItem {
    let value: CGFloat
}

// MARK: - VisualFlexibleSpacing

/// Flexible vertical spacing. Produced by `atLeast(_:)` and `atMost(_:)`.
public struct VisualFlexibleSpacing: VisualLayoutItem {
    public let points: CGFloat
    public let relation: NSLayoutConstraint.Relation
}

// MARK: - Flexible Spacing Helpers

/// Returns a flexible spacing requiring at least `value` points.
public func atLeast(_ value: CGFloat) -> VisualFlexibleSpacing {
    VisualFlexibleSpacing(points: value, relation: .greaterThanOrEqual)
}

/// Returns a flexible spacing requiring at most `value` points.
public func atMost(_ value: CGFloat) -> VisualFlexibleSpacing {
    VisualFlexibleSpacing(points: value, relation: .lessThanOrEqual)
}

// MARK: - VisualLayoutBuilder

/// Result builder that powers the `layout(in:) { }` DSL.
/// Converts numeric literals, `VisualRow`, and `VisualFlexibleSpacing` expressions
/// into a flat `[VisualLayoutItem]` array without retroactive conformances.
@resultBuilder
public enum VisualLayoutBuilder {
    public static func buildExpression(_ value: CGFloat) -> VisualLayoutItem {
        VisualSpacing(value: value)
    }
    public static func buildExpression(_ value: Double) -> VisualLayoutItem {
        VisualSpacing(value: CGFloat(value))
    }
    public static func buildExpression(_ value: Int) -> VisualLayoutItem {
        VisualSpacing(value: CGFloat(value))
    }
    public static func buildExpression(_ row: VisualRow) -> VisualLayoutItem {
        row
    }
    public static func buildExpression(_ flex: VisualFlexibleSpacing) -> VisualLayoutItem {
        flex
    }
    public static func buildBlock(_ items: VisualLayoutItem...) -> [VisualLayoutItem] {
        items
    }
}

// MARK: - layout(in:)

/// Describes the vertical layout of views inside `view` using an ASCII-style DSL.
///
/// ```swift
/// layout(in: container) {
///     100
///     |-emailField-| /=/ 44
///     8
///     |-[nameField, phoneField]-| /=/ 44
///     atLeast(20)
///     |loginButton| /=/ 50
///     0
/// }
/// ```
///
/// - Returns: All generated constraints, already activated.
@discardableResult
public func layout(
    in view: VisualLayoutView,
    @VisualLayoutBuilder _ items: () -> [VisualLayoutItem]
) -> [NSLayoutConstraint] {
    let layoutItems = items()
    var constraints: [NSLayoutConstraint] = []
    var prevAnchor: NSLayoutYAxisAnchor = view.topAnchor
    var pendingSpacing: VisualLayoutItem?

    for item in layoutItems {
        switch item {
        case let spacing as VisualSpacing:
            pendingSpacing = spacing

        case let flex as VisualFlexibleSpacing:
            pendingSpacing = flex

        case let row as VisualRow:
            guard let firstView = row.views.first else { continue }
            row.views.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

            // 1. Vertical (top) constraint
            let topC = topConstraint(from: firstView.topAnchor, to: prevAnchor, spacing: pendingSpacing)
            topC.isActive = true
            constraints.append(topC)

            // 2. Leading constraint
            if let margin = row.leadingMargin {
                let c = firstView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin)
                c.isActive = true
                constraints.append(c)
            }

            // 3. Trailing constraint
            if let margin = row.trailingMargin, let lastView = row.views.last {
                let c = lastView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin)
                c.isActive = true
                constraints.append(c)
            }

            // 4. Multi-view: equal widths + adjacent spacing
            if row.views.count > 1 {
                for i in 1..<row.views.count {
                    let prev = row.views[i - 1]
                    let cur = row.views[i]
                    let widthC = cur.widthAnchor.constraint(equalTo: prev.widthAnchor)
                    widthC.isActive = true
                    constraints.append(widthC)
                    let spacingC = cur.leadingAnchor.constraint(
                        equalTo: prev.trailingAnchor,
                        constant: visualLayoutDefaultMargin
                    )
                    spacingC.isActive = true
                    constraints.append(spacingC)
                }
            }

            // 5. Height constraints (one per view in the row)
            if let height = row.height {
                for v in row.views {
                    let c = heightConstraint(for: v, value: height, relation: row.heightRelation)
                    c.isActive = true
                    constraints.append(c)
                }
            }

            prevAnchor = row.views.last!.bottomAnchor
            pendingSpacing = nil

        default:
            break
        }
    }

    // Trailing bottom constraint (last number or flexible spacing)
    if let spacing = pendingSpacing {
        let bottomC = bottomConstraint(from: view.bottomAnchor, to: prevAnchor, spacing: spacing)
        bottomC.isActive = true
        constraints.append(bottomC)
    }

    return constraints
}

// MARK: - Private Constraint Helpers

private func topConstraint(
    from anchor: NSLayoutYAxisAnchor,
    to prevAnchor: NSLayoutYAxisAnchor,
    spacing: VisualLayoutItem?
) -> NSLayoutConstraint {
    if let s = spacing as? VisualSpacing {
        return anchor.constraint(equalTo: prevAnchor, constant: s.value)
    }
    if let f = spacing as? VisualFlexibleSpacing {
        switch f.relation {
        case .greaterThanOrEqual:
            return anchor.constraint(greaterThanOrEqualTo: prevAnchor, constant: f.points)
        case .lessThanOrEqual:
            return anchor.constraint(lessThanOrEqualTo: prevAnchor, constant: f.points)
        default:
            return anchor.constraint(equalTo: prevAnchor, constant: f.points)
        }
    }
    return anchor.constraint(equalTo: prevAnchor, constant: 0)
}

private func bottomConstraint(
    from bottomAnchor: NSLayoutYAxisAnchor,
    to prevAnchor: NSLayoutYAxisAnchor,
    spacing: VisualLayoutItem
) -> NSLayoutConstraint {
    if let s = spacing as? VisualSpacing {
        return bottomAnchor.constraint(equalTo: prevAnchor, constant: s.value)
    }
    if let f = spacing as? VisualFlexibleSpacing {
        switch f.relation {
        case .greaterThanOrEqual:
            return bottomAnchor.constraint(greaterThanOrEqualTo: prevAnchor, constant: f.points)
        case .lessThanOrEqual:
            return bottomAnchor.constraint(lessThanOrEqualTo: prevAnchor, constant: f.points)
        default:
            return bottomAnchor.constraint(equalTo: prevAnchor, constant: f.points)
        }
    }
    return bottomAnchor.constraint(equalTo: prevAnchor, constant: 0)
}

private func heightConstraint(
    for view: VisualLayoutView,
    value: CGFloat,
    relation: NSLayoutConstraint.Relation
) -> NSLayoutConstraint {
    switch relation {
    case .greaterThanOrEqual:
        return view.heightAnchor.constraint(greaterThanOrEqualToConstant: value)
    case .lessThanOrEqual:
        return view.heightAnchor.constraint(lessThanOrEqualToConstant: value)
    default:
        return view.heightAnchor.constraint(equalToConstant: value)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
swift test --filter VisualLayoutTests
```
Expected: `testAtLeastCreatesGreaterThanOrEqualSpacing`, `testAtMostCreatesLessThanOrEqualSpacing`, `testVisualRowDefaultHeightRelationIsEqual` all PASS.

- [ ] **Step 5: Commit**

```bash
git add Source/VisualLayout.swift ZDTinyLayoutTests/VisualLayoutTests.swift
git commit -m "feat: add VisualLayout core types and layout(in:) function"
```

---

## Task 3: Operators — `VisualLayoutOperators.swift` (TDD)

**Files:**
- Modify: `ZDTinyLayoutTests/VisualLayoutTests.swift`
- Create: `Source/VisualLayoutOperators.swift`

### Step 1 — Add failing tests for operators

- [ ] **Append to `VisualLayoutTests.swift`, inside the class:**

```swift
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

func testPrefixDashPipeDefaultMargin() {
    let row = |-view1-|  // postfix -| then prefix |-
    XCTAssertEqual(row.leadingMargin, visualLayoutDefaultMargin)
    XCTAssertEqual(row.trailingMargin, visualLayoutDefaultMargin)
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
    XCTAssertEqual(row.leadingMargin, visualLayoutDefaultMargin)
    XCTAssertEqual(row.trailingMargin, visualLayoutDefaultMargin)
}
```

- [ ] **Step 2: Run tests to verify they fail (operators not found)**

Run:
```bash
swift test --filter VisualLayoutTests
```
Expected: Compile errors — operators `|`, `-|`, `|-`, `/=/` not declared.

### Step 3 — Create `Source/VisualLayoutOperators.swift`

- [ ] **Create `Source/VisualLayoutOperators.swift`:**

```swift
//
//  VisualLayoutOperators.swift
//  ZDTinyLayout
//
//  Copyright 2024 Rightpoint and other contributors
//  http://rightpoint.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// MARK: - Operator Declarations

postfix operator |
postfix operator -|
prefix operator |
prefix operator |-

precedencegroup VisualLayoutHeightPrecedence {
    lowerThan: AdditionPrecedence
    higherThan: AssignmentPrecedence
    associativity: left
}
infix operator /=/ : VisualLayoutHeightPrecedence

// MARK: - Postfix | — trailing, no margin

/// Pins the view's trailing edge to the container with zero margin.
@discardableResult
public postfix func | (view: VisualLayoutView) -> VisualRow {
    VisualRow(views: [view], trailingMargin: 0)
}

/// Pins the last view's trailing edge to the container with zero margin.
@discardableResult
public postfix func | (views: [VisualLayoutView]) -> VisualRow {
    VisualRow(views: views, trailingMargin: 0)
}

// MARK: - Postfix -| — trailing, default margin

/// Pins the view's trailing edge to the container with `visualLayoutDefaultMargin`.
@discardableResult
public postfix func -| (view: VisualLayoutView) -> VisualRow {
    VisualRow(views: [view], trailingMargin: visualLayoutDefaultMargin)
}

/// Pins the last view's trailing edge to the container with `visualLayoutDefaultMargin`.
@discardableResult
public postfix func -| (views: [VisualLayoutView]) -> VisualRow {
    VisualRow(views: views, trailingMargin: visualLayoutDefaultMargin)
}

// MARK: - Prefix | — leading, no margin

/// Pins the row's first view's leading edge to the container with zero margin.
@discardableResult
public prefix func | (row: VisualRow) -> VisualRow {
    var r = row
    r.leadingMargin = 0
    return r
}

// MARK: - Prefix |- — leading, default margin

/// Pins the row's first view's leading edge to the container with `visualLayoutDefaultMargin`.
@discardableResult
public prefix func |- (row: VisualRow) -> VisualRow {
    var r = row
    r.leadingMargin = visualLayoutDefaultMargin
    return r
}

// MARK: - Infix /=/ — height

/// Sets the height of all views in the row to `rhs` points.
@discardableResult
public func /=/ (lhs: VisualRow, rhs: CGFloat) -> VisualRow {
    var r = lhs
    r.height = rhs
    r.heightRelation = .equal
    return r
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
swift test --filter VisualLayoutTests
```
Expected: All 9 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Source/VisualLayoutOperators.swift ZDTinyLayoutTests/VisualLayoutTests.swift
git commit -m "feat: add VisualLayout operators (|, -|, |-) and /=/ height operator"
```

---

## Task 4: `layout(in:)` Constraint Verification Tests (TDD)

The `layout(in:)` function was already implemented in Task 2. This task adds tests that verify the exact constraint attributes.

**Files:**
- Modify: `ZDTinyLayoutTests/VisualLayoutTests.swift`

### Step 1 — Add failing tests that verify constraint attributes

- [ ] **Append to `VisualLayoutTests.swift`, inside the class:**

```swift
// MARK: - layout(in:) Single View

func testSingleViewWithMarginsAndHeight() {
    // layout(in: container) { 100; |-view1-| /=/ 44; 0 }
    // Expected constraints (in order):
    //   [0] view1.top == container.top + 100
    //   [1] view1.leading == container.leading + 8
    //   [2] view1.trailing == container.trailing - 8
    //   [3] view1.height == 44
    //   [4] container.bottom == view1.bottom + 0
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
    XCTAssertEqual(leading.constant, 8)

    let trailing = constraints[2]
    XCTAssertTrue(trailing.firstItem === view1)
    XCTAssertEqual(trailing.firstAttribute, .trailing)
    XCTAssertTrue(trailing.secondItem === container)
    XCTAssertEqual(trailing.secondAttribute, .trailing)
    XCTAssertEqual(trailing.constant, -8)

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
    // |view1| — leading and trailing with 0 margin (pinned to edges)
    let constraints = layout(in: container) {
        |view1|
    }
    // [0] view1.top == container.top + 0 (no leading spacing)
    // [1] view1.leading == container.leading + 0
    // [2] view1.trailing == container.trailing - 0
    XCTAssertEqual(constraints.count, 3)
    XCTAssertEqual(constraints[1].constant, 0)  // leading no margin
    XCTAssertEqual(constraints[2].constant, 0)  // trailing no margin
}

func testViewWithNoHeightHasNoHeightConstraint() {
    // |-view1-| without /=/ produces no height constraint
    let constraints = layout(in: container) {
        |-view1-|
    }
    // [0] view1.top == container.top + 0
    // [1] view1.leading == container.leading + 8
    // [2] view1.trailing == container.trailing - 8
    // No height, no bottom
    XCTAssertEqual(constraints.count, 3)
    XCTAssertFalse(constraints.contains { $0.firstAttribute == .height })
}

func testNoTrailingNumberLeavesBottomUnconstrained() {
    // Layout ending with a VisualRow should not add a bottom constraint
    let constraints = layout(in: container) {
        |-view1-| /=/ 44
    }
    // [0] top, [1] leading, [2] trailing, [3] height — no bottom
    XCTAssertEqual(constraints.count, 4)
    XCTAssertFalse(constraints.contains { $0.firstItem === container && $0.firstAttribute == .bottom })
}

func testTwoViewsVerticalSpacing() {
    let constraints = layout(in: container) {
        |-view1-| /=/ 44
        8
        |-view2-| /=/ 50
    }
    // view1: top(0)+leading+trailing+height = 4
    // view2: top(8)+leading+trailing+height = 4
    // Total = 8
    XCTAssertEqual(constraints.count, 8)

    // Find the constraint where view2.top == view1.bottom + 8
    // (filter by attribute instead of relying on index)
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
    // |-[view1, view2]-| /=/ 44
    // Expected:
    //   [0] view1.top == container.top + 0
    //   [1] view1.leading == container.leading + 8
    //   [2] view2.trailing == container.trailing - 8
    //   [3] view2.width == view1.width
    //   [4] view2.leading == view1.trailing + 8
    //   [5] view1.height == 44
    //   [6] view2.height == 44
    let constraints = layout(in: container) {
        |-[view1, view2]-| /=/ 44
    }
    XCTAssertEqual(constraints.count, 7)

    // Leading: view1 pinned to container
    XCTAssertTrue(constraints[1].firstItem === view1)
    XCTAssertEqual(constraints[1].firstAttribute, .leading)
    XCTAssertEqual(constraints[1].constant, 8)

    // Trailing: view2 pinned to container
    XCTAssertTrue(constraints[2].firstItem === view2)
    XCTAssertEqual(constraints[2].firstAttribute, .trailing)
    XCTAssertEqual(constraints[2].constant, -8)

    // Equal widths: view2.width == view1.width
    let widthC = constraints[3]
    XCTAssertEqual(widthC.firstAttribute, .width)
    XCTAssertEqual(widthC.secondAttribute, .width)
    XCTAssertEqual(widthC.multiplier, 1)

    // Adjacent spacing: view2.leading == view1.trailing + 8
    let spacingC = constraints[4]
    XCTAssertTrue(spacingC.firstItem === view2)
    XCTAssertEqual(spacingC.firstAttribute, .leading)
    XCTAssertTrue(spacingC.secondItem === view1)
    XCTAssertEqual(spacingC.secondAttribute, .trailing)
    XCTAssertEqual(spacingC.constant, 8)

    // Heights
    XCTAssertEqual(constraints[5].constant, 44)
    XCTAssertEqual(constraints[6].constant, 44)
}

func testThreeViewMultiRow() {
    let constraints = layout(in: container) {
        |-[view1, view2, view3]-|
    }
    // top + leading + trailing + (width+spacing) * 2 = 1+1+1+4 = 7
    XCTAssertEqual(constraints.count, 7)
}

// MARK: - layout(in:) Flexible Spacing

func testAtLeastSpacingBeforeView() {
    let constraints = layout(in: container) {
        atLeast(20)
        |view1|
    }
    // [0] view1.top >= container.top + 20
    // [1] view1.leading == container.leading + 0
    // [2] view1.trailing == container.trailing - 0
    XCTAssertEqual(constraints.count, 3)
    XCTAssertEqual(constraints[0].relation, .greaterThanOrEqual)
    XCTAssertEqual(constraints[0].constant, 20)
}

func testAtMostTrailingSpacing() {
    let constraints = layout(in: container) {
        |-view1-|
        atMost(30)
    }
    // [0] top, [1] leading, [2] trailing — then atMost as bottom
    // [3] container.bottom <= view1.bottom + 30
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
    // [0] top, [1] leading, [2] trailing — then atLeast as bottom
    // [3] container.bottom >= view1.bottom + 16
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
```

- [ ] **Step 2: Run tests to verify they pass (implementation already in place)**

Run:
```bash
swift test --filter VisualLayoutTests
```
Expected: All tests PASS. If any fail, the bug is in `layout(in:)` — debug the specific failing assertion and fix in `VisualLayout.swift`.

- [ ] **Step 3: Run the full test suite to ensure nothing is broken**

Run:
```bash
swift test
```
Expected: All tests PASS (existing `ZDTinyLayoutTests` unaffected, all new `VisualLayoutTests` PASS).

- [ ] **Step 4: Commit**

```bash
git add ZDTinyLayoutTests/VisualLayoutTests.swift
git commit -m "test: add comprehensive VisualLayout constraint verification tests"
```

---

## Task 5: Final Verification

- [ ] **Step 1: Run the full test suite one final time**

Run:
```bash
swift test
```
Expected: All tests PASS.

- [ ] **Step 2: Verify the library builds cleanly with no warnings**

Run:
```bash
swift build 2>&1 | grep -E "(error:|warning:)"
```
Expected: No errors. Warnings (if any) from pre-existing code are acceptable, but no new warnings from the Visual Layout files.

- [ ] **Step 3: Final commit**

```bash
git add Source/VisualLayout.swift Source/VisualLayoutOperators.swift \
    ZDTinyLayoutTests/VisualLayoutTests.swift Package.swift ZDTinyLayout.podspec
git commit -m "feat: add Visual Layout DSL to ZDTinyLayout

Adds layout(in:) function with @resultBuilder DSL for expressing
Auto Layout in an ASCII-style vertical structure:

    layout(in: container) {
        100
        |-emailField-| /=/ 44
        8
        |-[nameField, phoneField]-| /=/ 44
        atLeast(20)
        |loginButton| /=/ 50
        0
    }

New operators: postfix |, -|, prefix |, |-; infix /=/
New functions: atLeast(_:), atMost(_:)
New files: Source/VisualLayout.swift, Source/VisualLayoutOperators.swift
Bumps minimum Swift to 5.9, adds visionOS platform support"
```

---

## Constraint Order Reference

For `layout(in: container) { spacing?; row; spacing?; row; ...; spacing? }`:

Each `VisualRow` contributes constraints in this order:
1. Top (vertical from previous anchor)
2. Leading (if `leadingMargin != nil`)
3. Trailing (if `trailingMargin != nil`)
4. For each adjacent view pair in multi-view rows: width equality, then leading spacing
5. Height (one per view, if `height != nil`)

Trailing bottom constraint (from final spacing/`atLeast`/`atMost`) is appended last.

## Known Limitations

- `if`/`else` and `for` inside `layout { }` blocks are not supported (v1 non-goal).
- Inter-view spacing in multi-view rows is always `visualLayoutDefaultMargin` (non-configurable in v1).
- A layout block ending with a `VisualRow` (no trailing number) leaves the container's bottom unconstrained — add `0` as the last item to pin the bottom edge.
- `VisualRow.heightRelation` can only be `.equal` in v1. There is no DSL syntax for `>= height` or `<= height` (no `VisualFlexibleSpacing` overload for `/=/`). The field exists for forward compatibility.
