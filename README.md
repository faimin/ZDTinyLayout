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
let constraints = layout(in: container) {
    16
    |--15--titleLabel--15--| /=/ 20
    8
    |--subtitleLabel1--10--subtitleLabel2--|
    >= 12
    |--[leftButton, rightButton]--| /=/ 44 ~ .high
    16
}
```

`layout(in:)` returns all generated constraints, already active.

You can also use the view-returning convenience overload:

```swift
let card = VisualLayoutView().layout {
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
layout(in: container) {
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

Rows accept both views and layout guides (`VisualLayoutGuide`, aliased to `UILayoutGuide`/`NSLayoutGuide`):

```swift
let guide = VisualLayoutGuide()
layout(in: container) {
    |--guide--| /=/ 44
}
```

If a view has no superview (or a guide has no owning view), ZDTinyLayout automatically adds it to the container passed to `layout(in:)`. If a view/guide is already attached to a different container, `layout(in:)` triggers a precondition failure to prevent invalid cross-container layout constraints.

### Default inter-item spacing

In Visual Layout DSL (`--` chain and array syntax), omitted inter-item spacing defaults to `0`:

```swift
layout(in: container) {
    |--view1--view2--|              // gap(view1, view2) = 0
    |--[view1, view2, view3]--|     // gaps = [0, 0]
    |--[view1, 10, view2, view3]--| // gaps = [10, 0]
    |--15--view1--view2--20--|      // gap(view1, view2) = 0
}
```

Use explicit spacing when non-zero is desired:

```swift
layout(in: container) {
    |--view1--12--view2--|
    |--[view1, 12, view2]--|
}
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
