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
    |-emailField-| .= 44
    8
    |-[nameField, phoneField]-| .= 44
    atLeast(20)
    |loginButton| .= 50
    0
}
```

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Syntax style | Fusion with Anchorage style | Avoid divergence from existing API |
| Height operator | `.=` (e.g. `\|-email-\| .= 44`) | Avoids conflict with Anchorage's `~` priority operator |
| Horizontal multi-view | Supported (`\|-[a, b, c]-\| .= 44`) | Needed for common side-by-side layouts |
| Flexible spacing | Named functions `atLeast(n)` / `atMost(n)` | `prefix >=` / `<=` cannot be declared; conflicts with stdlib infix comparison operators |
| View hierarchy (`subviews {}`) | Not added | Keeps Anchorage lightweight and focused |
| Calling style | Top-level function `layout(in: view) { }` | Consistent with Anchorage's non-UIView-extension style |
| Platform support | All Apple platforms (iOS, macOS, tvOS, watchOS, visionOS) | Uses `public View` typealias with `#if os(macOS)` |
| Minimum Swift version | 5.9 | Required for `@resultBuilder` (stable API) |

---

## Swift Version Requirement

`@resultBuilder` was stabilized in Swift 5.4, and the minimum is set to **Swift 5.9** to align with modern toolchain support and enable future use of Swift 5.9+ language features (e.g., parameter packs, macros) if needed.

Required changes:

- **`Anchorage.podspec`**: update `swift_versions` from `['4.0', '4.2', '5.0']` to `['5.9']`
- **`Package.swift`**: update `swift-tools-version` from `5.1` to `5.9`

This is a breaking change from the library's current 4.x/5.0 support. It should be released as a minor or major version bump depending on Anchorage's semver policy.

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
    var heightRelation: NSLayoutConstraint.Relation = .equal  // defaults to equal; only changed via .= overloads
}
```

### VisualSpacing

Represents a fixed vertical spacing (a plain number in the layout block). Intentionally `internal` — it is an implementation detail produced by `VisualLayoutBuilder.buildExpression`, never part of the public API.

```swift
internal struct VisualSpacing: VisualLayoutItem {
    let value: CGFloat
}
```

### VisualFlexibleSpacing

Represents a flexible vertical spacing, produced by `atLeast(_:)` and `atMost(_:)`.

```swift
public struct VisualFlexibleSpacing: VisualLayoutItem {
    let points: CGFloat
    let relation: NSLayoutConstraint.Relation
}

public func atLeast(_ value: CGFloat) -> VisualFlexibleSpacing
public func atMost(_ value: CGFloat) -> VisualFlexibleSpacing
```

**Why named functions instead of `prefix >=` / `prefix <=`:** Swift does not allow declaring `>=` and `<=` with prefix fixity because they are already claimed as infix comparison operators by the standard library. Named functions are unambiguous and equally readable in context.

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

**Non-goals for v1:** `buildOptional`, `buildEither`, `buildArray` (supporting `if`/`else` branches and `for` loops inside the layout block) are explicitly out of scope. These can be added in a future version without breaking changes.

---

## Operators

### Public View Typealias

The existing `View` typealias in `Internal.swift` is `internal`. A new `public` typealias must be declared in `VisualLayout.swift` (or promoted in `Compatability.swift`) for use in public API signatures:

```swift
#if os(macOS)
public typealias VisualLayoutView = NSView
#else
public typealias VisualLayoutView = UIView  // iOS, tvOS, watchOS, visionOS
#endif
```

All public `VisualLayout` APIs use `VisualLayoutView` (or the promoted `public View` alias). Internal logic continues using the internal `View` typealias from `Internal.swift` where appropriate.

**Platform note:** watchOS and visionOS are not currently listed in `Package.swift`'s `platforms` array. They must be added when bumping the swift-tools-version (part of the Swift 5.4 bump described above).

### Default Margin Constant

```swift
public var visualLayoutDefaultMargin: CGFloat = 8
```

Used by `|-` and `-|`. Globally overridable.

### Horizontal Constraint Operators

The **postfix** operators (`-|` and `|`) work on `View` and `[View]` and produce a `VisualRow`. The **prefix** operators (`|-` and `|`) work on an already-constructed `VisualRow` and add the leading margin.

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

**Regarding `|view|` and bitwise OR ambiguity:** `|` is also Swift's infix bitwise OR operator. However, `UIView`/`NSView` do not conform to `BinaryInteger` or any protocol that makes infix `|` applicable. With no viable infix overload for `View` types, the compiler resolves `|view|` as `prefix |(postfix |(view))` unambiguously. This pattern is validated by Stevia, which uses identical operator declarations with no reported compile-time ambiguity.

### Height Operator

```swift
precedencegroup VisualLayoutHeightPrecedence {
    lowerThan: AdditionPrecedence
    higherThan: AssignmentPrecedence
    associativity: left
}
infix operator .= : VisualLayoutHeightPrecedence

@discardableResult
public func .= (lhs: VisualRow, rhs: CGFloat) -> VisualRow
```

The precedence group places `.=` below arithmetic (`AdditionPrecedence`) but above assignment (`AssignmentPrecedence`). This matches conventional assignment-style operator positioning: the right-hand side arithmetic is fully evaluated before `.=` binds it to the `VisualRow`. Since `|-view-|` is also fully evaluated before `.=` (postfix/prefix have higher precedence than any infix), the expression `|-view-| .= 44` always parses as intended.

### Flexible Spacing Functions

```swift
public func atLeast(_ value: CGFloat) -> VisualFlexibleSpacing {
    VisualFlexibleSpacing(points: value, relation: .greaterThanOrEqual)
}
public func atMost(_ value: CGFloat) -> VisualFlexibleSpacing {
    VisualFlexibleSpacing(points: value, relation: .lessThanOrEqual)
}
```

---

## Constraint Generation Algorithm

The `layout(in:)` function scans items sequentially, maintaining:

- `prevAnchor`: the bottom anchor of the last processed row (starts as `view.topAnchor`)
- `pendingSpacing`: the next spacing/flexible spacing item to apply (starts as `nil`)

**`nil` pending spacing behavior:** When `pendingSpacing` is `nil` at the time a `VisualRow` is processed, the row's top is pinned directly to `prevAnchor` with constant `0` (i.e., no gap). This means a layout block that starts with a `VisualRow` pins that view to the container's top edge. This is intentional and correct.

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
         - VisualSpacing(v) → row.views[0].top == prevAnchor + v
         - FlexibleSpacing  → row.views[0].top >= prevAnchor + v  (or <=)
         - nil              → row.views[0].top == prevAnchor + 0

      2. Horizontal constraints:
         - leadingMargin != nil  → views[0].leading == container.leading + leadingMargin
         - trailingMargin != nil → views[last].trailing == container.trailing - trailingMargin
         - multiple views        → equalWidths(views) + adjacent spacing = visualLayoutDefaultMargin

      3. Height constraint (if height != nil):
         - each view in row: view.height == height (using heightRelation)

      4. Update state:
         prevAnchor = row.views.last.bottomAnchor
         pendingSpacing = nil

After loop:
  if pendingSpacing != nil:
      container.bottom == prevAnchor + spacing  (or >= / <=)
  // if pendingSpacing == nil: container bottom is NOT constrained — see known limitation below
```

**Known limitation — no trailing spacing:** If the layout block ends with a `VisualRow` (no trailing number), the container's bottom edge is unconstrained by this layout block. For intrinsically-sized containers (e.g., `UIScrollView` content size, self-sizing cells), callers must explicitly add `0` as the last item to pin the bottom edge. This is consistent with Stevia's behavior and is an intentional design choice, not a bug.

---

### Multi-View Row Horizontal Distribution

For `|-[a, b, c]-|`:

```
a.leading == container.leading + margin
b.leading == a.trailing + visualLayoutDefaultMargin
c.leading == b.trailing + visualLayoutDefaultMargin
c.trailing == container.trailing - margin
a.width == b.width == c.width  (equal widths)
```

**Non-goal:** Per-row inter-view spacing override is not supported in v1. The spacing between adjacent views in a multi-view row is always `visualLayoutDefaultMargin`. Custom inter-view spacing requires using Anchorage's existing operators directly.

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

### Required changes to existing files

- **`Anchorage.podspec`**: update `swift_versions` to `['5.9']`
- **`Package.swift`**: update `swift-tools-version` to `5.9`, add `watchOS` and `visionOS` to `platforms`
- **`Internal.swift`** (or `Compatability.swift`): promote `View` typealias to `public`, OR define a separate `public VisualLayoutView` alias in `VisualLayout.swift`

---

## Platform Compatibility

Visual Layout targets all Apple platforms. The `View` typealias maps to `NSView` on macOS and `UIView` everywhere else (iOS, tvOS, watchOS, visionOS). All new code uses this typealias via a public alias, with no platform-specific branches inside the Visual Layout files themselves.

---

## Non-Goals

- `subviews { }` hierarchy management — not added (user calls `addSubview` manually)
- `if`/`else` and `for` inside `layout { }` blocks — deferred to v2 (`buildOptional`/`buildArray`)
- Per-row inter-view spacing for multi-view rows — always uses `visualLayoutDefaultMargin`
- Styling DSL — out of scope
- Horizontal-axis `layout` — Anchorage's existing operators handle this
