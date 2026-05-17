# ZDTinyLayout

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat)](https://swift.org)
[![CircleCI](https://img.shields.io/circleci/project/github/faimin/ZDTinyLayout/master.svg)](https://circleci.com/gh/faimin/ZDTinyLayout)
[![Version](https://img.shields.io/cocoapods/v/ZDTinyLayout.svg?style=flat)](https://cocoadocs.org/docsets/ZDTinyLayout)
[![Platform](https://img.shields.io/cocoapods/p/ZDTinyLayout.svg?style=flat)](http://cocoapods.org/pods/ZDTinyLayout)

A lightweight collection of intuitive operators and utilities that simplify Auto Layout code. ZDTinyLayout is built directly on top of the `NSLayoutAnchor` API.

Each expression acts on one or more `NSLayoutAnchor`s, and returns active `NSLayoutConstraint`s. If you want inactive constraints, [here's how to do that](#batching-constraints).

## Fork & Credits

This repository is forked from [Rightpoint/Anchorage](https://github.com/Rightpoint/Anchorage).

The Visual Layout implementation in this project is inspired by [freshOS/Stevia](https://github.com/freshOS/Stevia).

# Usage

## Alignment

```swift
// Pin the button to 12 pt from the leading edge of its container
button.leadingAnchor == container.leadingAnchor + 12

// Pin the button to at least 12 pt from the trailing edge of its container
button.trailingAnchor <= container.trailingAnchor - 12

// Center one or both axes of a view
button.centerXAnchor == container.centerXAnchor
button.centerAnchors == container.centerAnchors
```

## Relative Alignment

```swift
// Position a view to be centered at 2/3 of its container's width
view.centerXAnchor == 2 * container.trailingAnchor / 3

// Pin the top of a view at 25% of container's height
view.topAnchor == container.bottomAnchor / 4
```

## Sizing

```swift
// Constrain a view's width to be at most 100 pt
view.widthAnchor <= 100

// Constraint a view to a fixed size
imageView.sizeAnchors == CGSize(width: 100, height: 200)

// Constrain two views to be the same size
imageView.sizeAnchors == view.sizeAnchors

// Constrain view to 4:3 aspect ratio
view.widthAnchor == 4 * view.heightAnchor / 3
```

## Composite Anchors

Constrain multiple edges at a time with this syntax:

```swift
// Constrain the leading, trailing, top and bottom edges to be equal
imageView.edgeAnchors == container.edgeAnchors

// Inset the edges of a view from another view
let insets = UIEdgeInsets(top: 5, left: 10, bottom: 15, right: 20)
imageView.edgeAnchors == container.edgeAnchors + insets

// Inset the leading and trailing anchors by 10
imageView.horizontalAnchors >= container.horizontalAnchors + 10

// Inset the top and bottom anchors by 10
imageView.verticalAnchors >= container.verticalAnchors + 10
```

#### Use leading and trailing
Using `leftAnchor` and `rightAnchor` is rarely the right choice. To encourage this, `horizontalAnchors` and `edgeAnchors` use the `leadingAnchor` and `trailingAnchor` layout anchors.

#### Inset instead of Shift
When constraining leading/trailing or top/bottom, it is far more common to work in terms of an inset from the edges instead of shifting both edges in the same direction. When building the expression, ZDTinyLayout will flip the relationship and invert the constant in the constraint on the far side of the axis. This makes the expressions much more natural to work with.

## Visual Layout DSL

ZDTinyLayout also includes a visual-layout style DSL for describing rows vertically inside a container:

```swift
let constraints = container.tl.layoutConstraints {
    16
    |--15--titleLabel--15--| /=/ 20
    8
    |--subtitleLabel1--10--subtitleLabel2--|
    >= 12
    |--[leftButton, rightButton]--| /=/ 44 ~ .high
    16
}
```

`layoutConstraints` returns all generated constraints, already active.

You can also use the view-returning convenience overload:

```swift
let card = VisualLayoutView().tl.layout {
    12
    |--titleLabel--|
    8
    |--bodyLabel--|
    12
}
```

### Row syntax

- `|view|` or `|--view--|`: pin leading/trailing to container with 0 margin.
- `|--view1--20--view2--|`: custom inter-item spacing.
- `|--20--view1--8--view2--16--|`: explicit leading/inter-item/trailing margins.
- `20--view1--8--view2|`: custom leading margin with trailing pinned to 0.
- `|--[view1, view2, view3]--|`: multi-view row with equal widths and aligned tops.
- `|--[view1, 10, view2, 50.0, view3]--|`: mixed array form with explicit per-gap spacing values.
- `|--15--[middleLeft, 50, middleRight]--20--|`: mixed array form with explicit leading/trailing margins and custom inter-item spacing.
  Mixed-array spacing literals support `Int`, `Float`, `Double`, and `CGFloat`.
  Gaps without an explicit number default to `0`.
  Mixed arrays must start and end with a view/layout guide (not a number).

### Vertical spacing

Inside the block, numeric literals become vertical gaps between rows:

```swift
container.tl.layoutConstraints {
    |--header--| /=/ 44
    8
    |--content--|
    atMost(24)
}
```

Use `atLeast(_:)` and `atMost(_:)` for flexible vertical spacing constraints.

### Height and priority

Use `/=/` to set row item height, then `~` to set height constraint priority:

```swift
|--avatarView--| /=/ 44 ~ .high
```

### Layout guides and auto-add behavior

Rows accept both views and layout guides (`VisualLayoutGuide`, a shared platform alias also used by internal `LayoutGuide`):

```swift
let guide = VisualLayoutGuide()
container.tl.layoutConstraints {
    |--guide--| /=/ 44
}
```

If a view has no superview (or a guide has no owning view), ZDTinyLayout automatically adds it to the receiver view. If a view/guide is already attached to a different container, `layoutConstraints`/`layout` triggers a precondition failure to prevent invalid cross-container layout constraints.

### Default inter-item spacing

In Visual Layout DSL (`--` chain and array syntax), omitted inter-item spacing defaults to `0`:

```swift
container.tl.layoutConstraints {
    |--view1--view2--|              // gap(view1, view2) = 0
    |--[view1, view2, view3]--|     // gaps = [0, 0]
    |--[view1, 10, view2, view3]--| // gaps = [10, 0]
    |--15--view1--view2--20--|      // gap(view1, view2) = 0
}
```

Use explicit spacing when non-zero is desired:

```swift
container.tl.layoutConstraints {
    |--view1--12--view2--|
    |--[view1, 12, view2]--|
}
```

### Add Components

You can add views/layout guides/layers/view controllers in declaration order via `tl.addComponents`.
Arrays are supported directly inside the builder block.

```swift
let staticParts: [any ZDTLComponentsProtocol] = [titleLabel, subtitleLabel]

container.tl.addComponents {
    staticParts
    if showSeparator { separatorLayer }
}
```

## Stackable (iOS-only)

ZDTinyLayout includes a declarative `UIStackView` builder inspired by [Stackable](https://github.com/rightpoint/Stackable). All Stackable APIs are accessed through the `tl` namespace.

> **Note**: Stackable features require `UIStackView` and are only available on iOS, tvOS, watchOS, and visionOS.

### Adding Items to a Stack View

Add views, strings, images, spacing, hairlines, and more to a stack view using a result builder:

```swift
let stack = UIStackView()
stack.tl.add {
    "Hello World!"
    20
    someView
    UIStackView.tl.hairline
    UIStackView.tl.flexibleSpace
}
```

You can also add arrays directly:

```swift
stack.tl.add([
    titleLabel,
    8,
    bodyLabel,
    20,
    footerView,
])
```

#### Built-in Type Support

`String`, `NSAttributedString`, and `UIImage` automatically create their respective views:

```swift
stack.tl.add {
    "Plain String"                              // creates a UILabel
    NSAttributedString(string: "Styled Text")   // creates a UILabel
    UIImage(named: "icon")                      // creates a UIImageView
}
```

`UIViewController` contributes its `view`:

```swift
stack.tl.add([
    myViewController,   // same as adding myViewController.view
    actionButton,
])
```

### Smart Spacing

Numeric literals inside `tl.add` create spaces that track the visibility of the preceding view:

```swift
stack.tl.add {
    headerView
    16          // visible when headerView is visible
    contentView
    20          // visible when contentView is visible
}
```

Advanced spacing options via `UIStackView.tl.*`:

| API | Description |
|-----|-------------|
| `.space(_:)` | Smart space that coalesces to `.spaceAfter` or `.constantSpace` |
| `.constantSpace(_:)` | Always-visible spacer |
| `.flexibleSpace(_:)` | Flexible spacer (low hugging priority) |
| `.space(after:, _:)` | Tracks visibility of a specific view |
| `.space(before:, _:)` | Tracks visibility of a specific view |
| `.spaceBetween(_, _, _)` | Visible when both views are visible |
| `.space(afterGroup:, _:)` | Visible when any member of a group is visible |
| `.flexibleSpace` | Flexible spacer with no minimum |

Flexible ranges:

```swift
stack.tl.add {
    headerView
    10...20        // closed range: 10pt ≤ space ≤ 20pt
    contentView
    10...          // partial range: space ≥ 10pt
    footerView
    ...20          // partial range: space ≤ 20pt
}
```

Flexible space factory methods:

```swift
stack.tl.add {
    viewA
    UIStackView.tl.flexibleSpace(.atLeast(20))    // ≥ 20pt
    viewB
    UIStackView.tl.flexibleSpace(.atMost(20))     // ≤ 20pt
    viewC
    UIStackView.tl.flexibleSpace(.range(10...20)) // 10pt…20pt
    viewD
    UIStackView.tl.flexibleSpace                  // ≥ 0pt, no maximum
}
```

#### Advanced Spaces

Space after a group (visible when any member of the group is visible):

```swift
let sectionCells: [UIView] = [cell1, cell2, cell3]
stack.tl.add {
    sectionCells
    UIStackView.tl.space(afterGroup: sectionCells, 20)
    nextSection
}
```

### Hairlines

Add separator lines that track view visibility:

```swift
stack.tl.add {
    UIStackView.tl.hairline                 // simple hairline
    UIStackView.tl.hairline(after: view)    // after a specific view
    UIStackView.tl.hairline(before: view)   // before a specific view
    UIStackView.tl.hairline(around: view)   // above and below
}
```

Hairlines between views in an array:

```swift
let cells: [UIView] = [cell1, cell2, cell3]

stack.tl.add {
    // Hairlines between adjacent visible cells
    UIStackView.tl.hairlines(between: cells)

    // Hairlines after each visible cell
    UIStackView.tl.hairlines(after: cells)

    // Hairlines above the first and below each visible cell
    UIStackView.tl.hairlines(around: cells)
}
```

#### Hairline Alignment

Insets can be positive (padding) or negative (outset):

```swift
UIStackView.tl.hairline
    .inset(by: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))   // padded

UIStackView.tl.hairline
    .inset(by: UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)) // outset

UIStackView.tl.hairline
    .outset(to: ancestorView)  // pin transverse-axis edges to an ancestor
```

Customize hairlines with modifier chaining:

```swift
UIStackView.tl.hairline
    .color(.lightGray)
    .thickness(2)
    .inset(by: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
```

Global and per-instance defaults override order: per-hairline > per-instance > global:

```swift
UIStackView.tl.hairlineColor = .separator    // global
UIStackView.tl.hairlineThickness = 1.0       // global

stackView.tl.hairlineColor = .red            // per-instance override
stackView.tl.hairlineThickness = 2           // per-instance override
```

#### Hairline Provider

Supply a custom hairline factory for arbitrary styling:

```swift
stackView.tl.hairlineProvider = { stackView in
    let customView = UIView()
    customView.backgroundColor = .systemRed
    // apply any custom styling…
    return customView
}

// Global default for all stack views:
UIStackView.tl.hairlineProvider = { … }
```

### Alignment & Insets

Apply alignment and insets to any `StackableView` (UIView, String, UIImage, etc.):

```swift
stack.tl.add {
    titleLabel
        .aligned(.centerX)
    avatarView
        .inset(by: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
    // Transforms are composable:
    caption
        .inset(by: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
        .aligned(.right)
    heroImage
        .outset(to: container)               // pin transverse edges to ancestor
        .margins(alignedWith: container)      // align layout margins with ancestor
}
```

Batch array alignment:

```swift
[cell1, cell2, cell3]
    .aligned(.fillHorizontal)
    .inset(by: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
```

### ScrollingStackView

A scroll view containing a vertical stack view that matches the scroll view's height at minimum:

```swift
let scrollView = ZDTLScrollingStackView()
scrollView.add {
    "Section Header"
    16
    UIStackView.tl.hairline
    8
    contentBody
    UIStackView.tl.flexibleSpace
}
```

### VStack / HStack / Spacer

SwiftUI-style convenience builders:

```swift
let vStack = ZDTLStackUI.VStack(spacing: 8) {
    headerLabel
    bodyLabel
    Spacer()
}

let hStack = ZDTLStackUI.HStack(alignment: .center, spacing: 12) {
    iconView
    textLabel
    ZDTLStackUI.Spacer(minWidth: 20)
    badgeLabel
}
```

### View Modifiers

Chain modifiers directly on `View.tl`:

```swift
myView.tl
    .width(200)
    .height(44)

// or return the view for non-chaining use:
let configuredView = myView.tl.width(200)

// StackView modifiers:
stackView.tl
    .axis(.vertical)
    .spacing(8)
    .distribution(.fillEqually)
```

### Visibility Binding

Bind a view's `isHidden` to another view:

```swift
spacerView.tl.bindVisible(to: someView)           // mirrors isHidden
spacerView.tl.bindVisible(toAllVisible: [v1, v2]) // hidden if any is hidden
spacerView.tl.bindVisible(toAnyVisible: [v1, v2]) // hidden if all are hidden
```

## Priority

The `~` is used to specify priority of the constraint resulting from any ZDTinyLayout expression:

```swift
// Align view 20 points from the center of its superview, with system-defined low priority
view.centerXAnchor == view.superview.centerXAnchor + 20 ~ .low

// Align view 20 points from the center of its superview, with (required - 1) priority
view.centerXAnchor == view.superview.centerXAnchor + 20 ~ .required - 1

// Align view 20 points from the center of its superview, with custom priority
view.centerXAnchor == view.superview.centerXAnchor + 20 ~ 752
```
The layout priority is an enum with the following values:

- `.required` - `UILayoutPriorityRequired` (default)
- `.high` - `UILayoutPriorityDefaultHigh`
- `.low` - `UILayoutPriorityDefaultLow`
- `.fittingSize` - `UILayoutPriorityFittingSizeLevel`

## Storing Constraints

To store constraints created by ZDTinyLayout, simply assign the expression to a variable:

```swift
// A single (active) NSLayoutConstraint
let topConstraint = (imageView.topAnchor == container.topAnchor)

// EdgeConstraints represents a collection of constraints
// You can retrieve the NSLayoutConstraints individually,
// or get an [NSLayoutConstraint] via .all, .horizontal, or .vertical
let edgeConstraints = (button.edgeAnchors == container.edgeAnchors).all
```

## Batching Constraints

By default, ZDTinyLayout returns active layout constraints. If you'd rather return inactive constraints for use with the [`NSLayoutConstraint.activate(_:)` method](https://developer.apple.com/reference/uikit/nslayoutconstraint/1526955-activate) for performance reasons, you can do it like this:

```swift
let constraints = ZDTinyLayout.batch(active: false) {
    view1.widthAnchor == view2.widthAnchor
    view1.heightAnchor == view2.heightAnchor / 2 ~ .low
    // ... as many constraints as you want
}

// Later:
NSLayoutConstraint.activate(constraints)
```

You can also pass `active: true` if you want the constraints in the array to be automatically activated in a batch.

## Updating Existing Constraints

ZDTinyLayout can update existing matching constraints in place (constant and priority), similar to SnapKit's `updateConstraints` behavior:

```swift
view.widthAnchor == other.widthAnchor + 8 ~ .low

ZDTinyLayout.updateConstraints {
    view.widthAnchor == other.widthAnchor + 24 ~ .high
}
```

### Unmatched behavior

If no matching installed constraint is found, the default behavior is to create a new one (`.makeNew`):

```swift
ZDTinyLayout.updateConstraints(unmatched: .makeNew) {
    view.widthAnchor == other.widthAnchor + 24
}
```

You can switch to strict mode to fail instead:

```swift
ZDTinyLayout.updateConstraints(unmatched: .fail) {
    view.widthAnchor == other.widthAnchor + 24
}
```

### Matching rules

ZDTinyLayout treats a constraint as a match when these properties are the same:

- `firstItem`
- `secondItem`
- `firstAttribute`
- `secondAttribute`
- `relation`
- `multiplier`

`constant` and `priority` are intentionally excluded from matching so they can be updated in place.

### Search scope

To keep updates efficient in deep hierarchies:

- If both sides of a constraint resolve to views, ZDTinyLayout starts from their nearest common superview and walks upward.
- If one side is a `UILayoutGuide`/`NSLayoutGuide`, ZDTinyLayout uses its owning view for this search.
- Single-item constraints search that item's superview chain.

## Autoresizing Mask

ZDTinyLayout sets the `translatesAutoresizingMaskIntoConstraints` property to `false` on the *left* hand side of the expression, so you should never need to set this property manually. This is important to be aware of in case the container view relies on `translatesAutoresizingMaskIntoConstraints` being set to `true`. We tend to keep child views on the left hand side of the expression to avoid this problem, especially when constraining to a system-supplied view.

## A Note on Compile Times

ZDTinyLayout overloads a few Swift operators, which can lead to increased compile times. You can reduce this overhead by surrounding these operators with `/`, like so:

| Operator | Faster Alternative |
|------|----------|
| `==` | `/==/` |
| `<=` | `/<=/` |
| `>=` | `/>=/` |

For example, `view1.edgeAnchors == view2.edgeAnchors` would become `view1.edgeAnchors /==/ view2.edgeAnchors`.

# Installation

## CocoaPods

To integrate ZDTinyLayout into your Xcode project using CocoaPods, specify it in
your Podfile:

```ruby
pod 'ZDTinyLayout'
```

# License

This code and tool is under the MIT License. See `LICENSE` file in this repository.

Any ideas and contributions welcome!
