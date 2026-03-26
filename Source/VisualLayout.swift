//
//  VisualLayout.swift
//  Anchorage
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
/// The platform-specific layout guide type used in Visual Layout APIs.
public typealias VisualLayoutGuide = NSLayoutGuide
#else
import UIKit
/// The platform-specific view type used in Visual Layout APIs.
public typealias VisualLayoutView = UIView
/// The platform-specific layout guide type used in Visual Layout APIs.
public typealias VisualLayoutGuide = UILayoutGuide
#endif

// MARK: - VisualLayoutAnchorable

/// A type that can participate in a visual layout row — either a view or a layout guide.
/// Exposes the layout anchors needed to build horizontal and vertical constraints.
public protocol VisualLayoutAnchorable: AnyObject {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
}

extension VisualLayoutView: VisualLayoutAnchorable {}
extension VisualLayoutGuide: VisualLayoutAnchorable {}

// MARK: - Default Margin

/// The default spacing (in points) applied by `|--` and `--|` operators.
/// Defaults to 8. Can be changed globally.
public var visualLayoutDefaultMargin: CGFloat = 8

// MARK: - VisualLayoutItem

/// A type that can appear as a line in a `layout(in:)` block.
public protocol VisualLayoutItem {}

// MARK: - VisualRowChain

/// An intermediate value produced by the `--` operator while building a multi-view row
/// with custom inter-view spacing. Converted to `VisualRow` by the postfix `|` or `--|` operators.
///
/// Parse flow for `|--a--20--b--|`:
///   1. `b--|` (postfix)           → `VisualRow(trailing: 0)`
///   2. `|-- a` (prefix on View)   → `VisualRowChain([a], leading: 0)`
///   3. `chain -- 20`              → `VisualRowChain([a], pending: 20)`
///   4. `chain -- VisualRow(b)`    → `VisualRow([a,b], leading: 0, trailing: 0, spacings:[20])`
public struct VisualRowChain {
    internal var views: [any VisualLayoutAnchorable]
    /// Collected spacings; `spacings[i]` is the gap between `views[i]` and `views[i+1]`.
    internal var spacings: [CGFloat]
    /// A spacing value set by `chain -- number` that will be consumed when the next view is appended.
    internal var pendingSpacing: CGFloat?
    /// Leading margin set by the opening `|--` or `|` prefix operator.
    internal var leadingMargin: CGFloat?
}

// MARK: - VisualRow

/// Represents one horizontal row in a visual layout block.
/// Built incrementally by the `|`, `|--`, `--|` operators.
public struct VisualRow: VisualLayoutItem {

    internal var views: [any VisualLayoutAnchorable]
    /// Spacing between adjacent elements. `interViewSpacings[i]` is the gap between
    /// `views[i]` and `views[i+1]`. Always has `max(0, views.count - 1)` elements.
    internal var interViewSpacings: [CGFloat]

    /// Distance from the container's leading edge. `nil` means no leading constraint.
    /// `0` pins to edge; positive value adds margin.
    internal var leadingMargin: CGFloat?

    /// Distance from the container's trailing edge. `nil` means no trailing constraint.
    internal var trailingMargin: CGFloat?

    internal var height: CGFloat?
    internal var heightRelation: NSLayoutConstraint.Relation = .equal
    internal var heightPriority: Priority = .required

    /// Creates a row from an array of anchorables, using `visualLayoutDefaultMargin` for all gaps.
    internal init(
        views: [any VisualLayoutAnchorable],
        leadingMargin: CGFloat? = nil,
        trailingMargin: CGFloat? = nil
    ) {
        self.views = views
        self.interViewSpacings = Array(repeating: visualLayoutDefaultMargin, count: max(0, views.count - 1))
        self.leadingMargin = leadingMargin
        self.trailingMargin = trailingMargin
    }

    /// Creates a row from a `VisualRowChain`, preserving custom per-gap spacings.
    internal init(
        chain: VisualRowChain,
        leadingMargin: CGFloat? = nil,
        trailingMargin: CGFloat? = nil
    ) {
        self.views = chain.views
        var spacings = chain.spacings
        while spacings.count < max(0, chain.views.count - 1) {
            spacings.append(visualLayoutDefaultMargin)
        }
        self.interViewSpacings = spacings
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
/// Converts numeric literals, `VisualRow`, and `VisualFlexibleSpacing`
/// expressions into a flat `[VisualLayoutItem]` array.
///
/// Rows must be closed with a fence operator (`|` or `--|`) to produce a `VisualRow`.
/// Use the explicit-margin syntax to set both edges:
/// ```
/// |--20--emailField--8--nameField--20--|   // leading=20, gap=8, trailing=20
/// |--8--loginButton--8--|                  // leading=8, trailing=8
/// ```
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
///     |--emailField--| /=/ 44
///     8
///     |--[nameField, phoneField]--| /=/ 44
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
			guard let first = row.views.first else { continue }
			row.views.forEach { element in
				if let v = element as? VisualLayoutView {
					if v.superview == nil { view.addSubview(v) }
					v.translatesAutoresizingMaskIntoConstraints = false
				} else if let g = element as? VisualLayoutGuide {
					if g.owningView == nil { view.addLayoutGuide(g) }
				}
			}

			// 1. Vertical (top) constraint
			let topC = topConstraint(from: first.topAnchor, to: prevAnchor, spacing: pendingSpacing)
			topC.isActive = true
			constraints.append(topC)

			// 2. Leading constraint
			if let margin = row.leadingMargin {
				let c = first.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin)
				c.isActive = true
				constraints.append(c)
			}

			// 3. Trailing constraint
			if let margin = row.trailingMargin, let last = row.views.last {
				let c = last.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin)
				c.isActive = true
				constraints.append(c)
			}

			// 4. Multi-element: equal widths, adjacent spacing, aligned tops
			let elementCount = row.views.count
			if elementCount > 1 {
				for i in 1..<elementCount {
					let prev = row.views[i - 1]
					let cur = row.views[i]
					let topC = cur.topAnchor.constraint(equalTo: first.topAnchor)
					topC.isActive = true
					constraints.append(topC)
					let widthC = cur.widthAnchor.constraint(equalTo: prev.widthAnchor)
					widthC.isActive = true
					constraints.append(widthC)
					let gap = row.interViewSpacings[i - 1]
					let spacingC = cur.leadingAnchor.constraint(
						equalTo: prev.trailingAnchor,
						constant: gap
					)
					spacingC.isActive = true
					constraints.append(spacingC)
				}
			}

			// 5. Height constraints (one per element in the row)
			if let height = row.height {
				for element in row.views {
					let c = heightConstraint(for: element, value: height, relation: row.heightRelation, priority: row.heightPriority)
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

// MARK: - layout(in:) — view-returning overload

public extension VisualLayoutView {
	/// Describes the vertical layout of subviews using an ASCII-style DSL,
	/// returning the receiver for declarative chaining.
	///
	/// ```swift
	/// let card = UIView().layout {
	///     16
	///     |--titleLabel--| /=/ 20
	///     8
	///     |--bodyLabel--|
	///     16
	/// }
	/// ```
	@discardableResult
	func layout(
		@VisualLayoutBuilder _ items: () -> [VisualLayoutItem]
	) -> Self {
		_ = Anchorage.layout(in: self, items)
		return self
	}
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
	for element: any VisualLayoutAnchorable,
	value: CGFloat,
	relation: NSLayoutConstraint.Relation,
	priority: Priority
) -> NSLayoutConstraint {
	let c: NSLayoutConstraint
	switch relation {
	case .greaterThanOrEqual:
		c = element.heightAnchor.constraint(greaterThanOrEqualToConstant: value)
	case .lessThanOrEqual:
		c = element.heightAnchor.constraint(lessThanOrEqualToConstant: value)
	default:
		c = element.heightAnchor.constraint(equalToConstant: value)
	}
	c.priority = priority.value
	return c
}
