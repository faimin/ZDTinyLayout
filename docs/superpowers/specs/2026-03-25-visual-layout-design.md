# Visual Layout Feature Design

**Date:** 2026-03-25
**Status:** Approved
**Reference:** Stevia Visual Layout implementation

---

## Overview

Add a Visual Layout DSL to Anchorage that lets developers describe Auto Layout using an ASCII-style vertical structure. Inspired by Stevia's Visual Layout, but adapted to Anchorage's existing operator-based style and conventions.

**Entry point:**

```swift
@discardableResult
public func layout(
    in view: View,
    @VisualLayoutBuilder _ items: () -> [VisualLayoutItem]
) -> [NSLayoutConstraint]
```

**Example:**

```swift
layout(in: container) {
    100
    |-emailField-| := 44
    8
    |-[nameField, phoneField]-| := 44
    >=20
    |loginButton| := 50
    0
}
```

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Syntax style | Fusion with Anchorage style | Avoid divergence from existing API |
| Height operator | `:=` (e.g. `\|-email-\| := 44`) | Avoids conflict with Anchorage's `~` priority operator |
| Horizontal multi-view | Supported (`\|-[a, b, c]-\| := 44`) | Needed for common side-by-side layouts |
| View hierarchy (`subviews {}`) | Not added | Keeps Anchorage lightweight and focused |
| Calling style | Top-level function `layout(in: view) { }` | Consistent with Anchorage's non-UIView-extension style |
| Platform support | All Apple platforms (iOS, macOS, tvOS, watchOS, visionOS) | Uses existing `View` typealias from `Compatability.swift` |

---

## Core Types

### Protocol

```swift
public protocol VisualLayoutItem {}
```

All items placed inside a `layout { }` block conform to this protocol.

### VisualRow

Represents one horizontal row — a view (or multiple views) with leading/trailing constraints and an optional height.

```swift
public struct VisualRow: VisualLayoutItem {
    let views: [View]
    var leadingMargin: CGFloat?    // nil = no leading constraint
                                   // 0   = pin to edge (no margin)
                                   // 8   = default margin (visualLayoutDefaultMargin)
    var trailingMargin: CGFloat?   // same semantics as leadingMargin
    var height: CGFloat?
    var heightRelation: NSLayoutConstraint.Relation
}
```

### VisualSpacing

Represents a fixed vertical spacing (a plain number in the layout block).

```swift
struct VisualSpacing: VisualLayoutItem {
    let value: CGFloat
}
```

### VisualFlexibleSpacing

Represents a flexible vertical spacing (`>=20` or `<=20`).

```swift
public struct VisualFlexibleSpacing: VisualLayoutItem {
    let points: CGFloat
    let relation: NSLayoutConstraint.Relation
}
```

### VisualLayoutBuilder

A `@resultBuilder` that accepts multiple expression types and converts them to `[VisualLayoutItem]` via `buildExpression` overloads. Avoids retroactive conformances on `Double`/`Int`.

```swift
@resultBuilder
public enum VisualLayoutBuilder {
    public static func buildExpression(_ value: CGFloat) -> VisualLayoutItem
    public static func buildExpression(_ value: Double) -> VisualLayoutItem
    public static func buildExpression(_ value: Int) -> VisualLayoutItem
    public static func buildExpression(_ row: VisualRow) -> VisualLayoutItem
    public static func buildExpression(_ flex: VisualFlexibleSpacing) -> VisualLayoutItem
    public static func buildBlock(_ items: VisualLayoutItem...) -> [VisualLayoutItem]
}
```

---

## Operators

### Default Margin Constant

```swift
public var visualLayoutDefaultMargin: CGFloat = 8
```

Used by `|-` and `-|`. Globally overridable.

### Horizontal Constraint Operators

All operators work on both `View` and `[View]` (for multi-view rows).

| Operator | Fixity | Input | Result |
|----------|--------|-------|--------|
| `-|` | postfix | `View` / `[View]` | `VisualRow` with `trailingMargin = visualLayoutDefaultMargin` |
| `|` | postfix | `View` / `[View]` | `VisualRow` with `trailingMargin = 0` |
| `|-` | prefix | `VisualRow` | Adds `leadingMargin = visualLayoutDefaultMargin` |
| `|` | prefix | `VisualRow` | Adds `leadingMargin = 0` |

**Parse order** (Swift postfix > prefix precedence):

```
|-email-|   →  (email-|)  →  VisualRow(trailing=8)
             →  |-(row)    →  VisualRow(leading=8, trailing=8)

|email|     →  (email|)   →  VisualRow(trailing=0)
             →  |(row)     →  VisualRow(leading=0, trailing=0)

|-[a,b,c]-| →  ([a,b,c]-|) →  VisualRow(views:[a,b,c], trailing=8)
             →  |-(row)     →  VisualRow(views:[a,b,c], leading=8, trailing=8)
```

### Height Operator

```swift
infix operator :=

@discardableResult
public func := (lhs: VisualRow, rhs: CGFloat) -> VisualRow
```

### Flexible Spacing Operators

```swift
prefix operator >=   // Different fixity from Anchorage's infix >= — no conflict
prefix operator <=

public prefix func >= (value: CGFloat) -> VisualFlexibleSpacing
public prefix func <= (value: CGFloat) -> VisualFlexibleSpacing
```

---

## Constraint Generation Algorithm

The `layout(in:)` function scans items sequentially, maintaining:

- `prevAnchor`: the bottom anchor of the last processed row (starts as `view.topAnchor`)
- `pendingSpacing`: the next spacing/flexible spacing item to apply

```
prevAnchor = view.topAnchor
pendingSpacing = nil

for each item:

  VisualSpacing(value):
      pendingSpacing = item

  VisualFlexibleSpacing:
      pendingSpacing = item

  VisualRow:
      1. Vertical constraint:
         - VisualSpacing   → row.views[0].top == prevAnchor + value
         - FlexibleSpacing → row.views[0].top >= prevAnchor + value  (or <=)
         - nil             → row.views[0].top == prevAnchor

      2. Horizontal constraints:
         - leadingMargin != nil  → views[0].leading == container.leading + leadingMargin
         - trailingMargin != nil → views[last].trailing == container.trailing - trailingMargin
         - multiple views        → equalWidths(views)
                                   adjacent spacing = visualLayoutDefaultMargin

      3. Height constraint (if height != nil):
         - each view in row: view.height == height (using heightRelation)

      4. Update state:
         prevAnchor = row.views.last.bottomAnchor
         pendingSpacing = nil

After loop:
  if pendingSpacing != nil:
      container.bottom == prevAnchor + pendingSpacing  (or >= / <=)
```

### Multi-View Row Horizontal Distribution

For `|-[a, b, c]-|`:

```
a.leading == container.leading + margin
b.leading == a.trailing + visualLayoutDefaultMargin
c.leading == b.trailing + visualLayoutDefaultMargin
c.trailing == container.trailing - margin
a.width == b.width == c.width  (equal widths)
```

---

## File Structure

Two new files added to `Source/`:

```
Source/
├── Anchorage.swift                          (unchanged)
├── AnchorGroupProvider.swift                (unchanged)
├── NSLayoutAnchor+MultiplierConstraints.swift (unchanged)
├── Priority.swift                           (unchanged)
├── Internal.swift                           (unchanged)
├── Compatability.swift                      (unchanged)
├── VisualLayout.swift                       ← NEW: types + layout(in:) + constraint logic
└── VisualLayoutOperators.swift              ← NEW: operator declarations + overloads
```

**No changes** to `Anchorage.podspec` or `Package.swift` — both already include all `Source/*.swift` files.

---

## Platform Compatibility

All new code uses the existing `View` typealias defined in `Compatability.swift`:

```swift
#if os(macOS)
typealias View = NSView
#else
typealias View = UIView  // covers iOS, tvOS, watchOS, visionOS
#endif
```

No additional conditional compilation required in the Visual Layout files.

---

## Non-Goals

- `subviews { }` hierarchy management — not added (user calls `addSubview` manually)
- Styling DSL — out of scope
- Horizontal-axis `layout` (Stevia supports this; Anchorage does not need it given its existing operators)
