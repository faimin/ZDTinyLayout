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

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

// MARK: - Operator Declarations

postfix operator |
postfix operator --|
prefix operator |
prefix operator |--

// `higherThan: PriorityPrecedence` (rather than AssignmentPrecedence) ensures that
// `/=/` binds before `~`, so `row /=/ 44 ~ .high` parses as `(row /=/ 44) ~ .high`.
precedencegroup VisualLayoutHeightPrecedence {
	lowerThan: AdditionPrecedence
	higherThan: PriorityPrecedence
	associativity: left
}
infix operator /=/ : VisualLayoutHeightPrecedence
infix operator -- : AdditionPrecedence

// MARK: - Postfix | — trailing, no margin

/// Pins the view or guide's trailing edge to the container with zero margin.
@discardableResult
public postfix func | (element: any VisualLayoutAnchorable) -> VisualRow {
	VisualRow(views: [element], trailingMargin: 0)
}

/// Trailing-margin carrier for integer literals in `chain -- N|` expressions.
/// Swift can parse the tail as `N|` before `--` binds, so this empty row carries
/// the trailing margin and is merged by `func -- (VisualRowChain, VisualRow)`.
@discardableResult
public postfix func | (trailing: Int) -> VisualRow {
	VisualRow(views: [], trailingMargin: CGFloat(trailing))
}

/// Trailing-margin carrier for floating-point literals in `chain -- N.0|` expressions.
@discardableResult
public postfix func | (trailing: Double) -> VisualRow {
	VisualRow(views: [], trailingMargin: CGFloat(trailing))
}

/// Trailing-margin carrier for float values in `chain -- value|` expressions.
@discardableResult
public postfix func | (trailing: Float) -> VisualRow {
	VisualRow(views: [], trailingMargin: CGFloat(trailing))
}

/// Trailing-margin carrier for `CGFloat` values in `chain -- value|` expressions.
@discardableResult
public postfix func | (trailing: CGFloat) -> VisualRow {
	VisualRow(views: [], trailingMargin: trailing)
}

/// Pins the last view's trailing edge to the container with zero margin.
@discardableResult
public postfix func | (views: [View]) -> VisualRow {
	VisualRow(views: views, trailingMargin: 0)
}

/// Pins the last guide's trailing edge to the container with zero margin.
@discardableResult
public postfix func | (guides: [LayoutGuide]) -> VisualRow {
	VisualRow(views: guides, trailingMargin: 0)
}

/// Pins a mixed array's trailing edge to the container with zero margin.
/// Supports arrays containing views/layout guides and numeric spacing values:
/// `|--[view1, 10, view2, 50.0, view3]--|`
@discardableResult
public postfix func | (items: VisualLayoutArrayItems) -> VisualRow {
	rowFromMixedArray(items, trailingMargin: 0)
}

// MARK: - Prefix | and |-- — leading, zero margin
//
// Both `|` and `|--` pin the leading edge with zero margin; they are semantically
// identical on the prefix side. The two forms exist purely for visual symmetry:
//   `|view|`          — compact, edge-to-edge look
//   `|--view--|`       — explicit fence markers that match the `--` chain style
//
// Use whichever reads more clearly for the surrounding syntax.

/// Passthrough for the explicit-margin syntax: `|16 -- view -- 16|`.
/// The value is forwarded to the existing `CGFloat -- VisualLayoutAnchorable` chain starter.
public prefix func | (margin: CGFloat) -> CGFloat { margin }
/// Integer overload of `|` margin passthrough.
public prefix func | (margin: Int) -> CGFloat { CGFloat(margin) }
/// Double overload of `|` margin passthrough.
public prefix func | (margin: Double) -> CGFloat { CGFloat(margin) }
/// Float overload of `|` margin passthrough.
public prefix func | (margin: Float) -> CGFloat { CGFloat(margin) }

/// Pins the row's first view's leading edge to the container with zero margin.
@discardableResult
public prefix func | (row: VisualRow) -> VisualRow {
	var r = row
	r.leadingMargin = 0
	return r
}

/// Opens a `--` chain with zero leading margin: `|element -- spacing -- element|`.
@discardableResult
public prefix func | (element: any VisualLayoutAnchorable) -> VisualRowChain {
	VisualRowChain(views: [element], spacings: [], pendingSpacing: nil, leadingMargin: 0)
}

/// Passthrough for the explicit-margin syntax: `|--16 -- view -- 16--|`.
/// The value is forwarded to the existing `CGFloat -- VisualLayoutAnchorable` chain starter.
public prefix func |-- (margin: CGFloat) -> CGFloat { margin }
/// Integer overload of `|--` margin passthrough.
public prefix func |-- (margin: Int) -> CGFloat { CGFloat(margin) }
/// Double overload of `|--` margin passthrough.
public prefix func |-- (margin: Double) -> CGFloat { CGFloat(margin) }
/// Float overload of `|--` margin passthrough.
public prefix func |-- (margin: Float) -> CGFloat { CGFloat(margin) }

/// Pins the row's first view's leading edge to the container with zero margin.
/// Semantically identical to `prefix |`; use `|--` when pairing with the `--|` closing fence.
@discardableResult
public prefix func |-- (row: VisualRow) -> VisualRow {
	var r = row
	r.leadingMargin = 0
	return r
}

/// Opens a `--` chain with zero leading margin: `|--element -- spacing -- element--|`.
/// Semantically identical to `prefix |`; use `|--` when pairing with the `--|` closing fence.
@discardableResult
public prefix func |-- (element: any VisualLayoutAnchorable) -> VisualRowChain {
	VisualRowChain(views: [element], spacings: [], pendingSpacing: nil, leadingMargin: 0)
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

/// Integer overload for height assignment: `row /=/ 44`.
@discardableResult
public func /=/ (lhs: VisualRow, rhs: Int) -> VisualRow {
	lhs /=/ CGFloat(rhs)
}

/// Double overload for height assignment: `row /=/ 44.0`.
@discardableResult
public func /=/ (lhs: VisualRow, rhs: Double) -> VisualRow {
	lhs /=/ CGFloat(rhs)
}

/// Float overload for height assignment: `row /=/ (44 as Float)`.
@discardableResult
public func /=/ (lhs: VisualRow, rhs: Float) -> VisualRow {
	lhs /=/ CGFloat(rhs)
}

// MARK: - Infix ~ — height priority

/// Sets the constraint priority for the height set by `/=/`.
/// Syntax: `|--view--| /=/ 44 ~ .high`
@discardableResult
public func ~ (lhs: VisualRow, rhs: Priority) -> VisualRow {
	var r = lhs
	r.heightPriority = rhs
	return r
}

// MARK: - Infix -- (VisualRowChain builder)
//
// Syntax A — zero-margin fences with custom inter-view spacing:
//   |--a--20--b--30--c--|
//   Parse: b--| (postfix) → VisualRow(trailing:0)
//          |-- a (prefix on View) → VisualRowChain([a], leading:0)
//          chain--20 / chain--VisualRow → final VisualRow
//
// Syntax B — explicit-margin fences:
//   |--16--a--8--b--16--|  or  |16--a--8--b--16|
//   Parse: |--16 (prefix) → CGFloat(16)
//          16 -- a → VisualRowChain([a], leading:16)
//          chain--8 / chain--b → appends b with gap 8
//          chain--16 → pendingSpacing=16
//          chain--| (postfix) → VisualRow(leading:16, trailing:16)
//
// Syntax C — custom leading margin via leading number + postfix fence:
//   20--a--3--b|
//   Parse: b| (postfix) → VisualRow(trailing:0)
//          20--a (CGFloat--View) → VisualRowChain([a], leading:20)
//          chain--3 / chain--VisualRow → final VisualRow

/// Starts a chain with a **custom leading margin**: `spacing -- element`.
/// The `CGFloat` becomes the distance from the container's leading edge to `element`.
public func -- (lhs: CGFloat, rhs: any VisualLayoutAnchorable) -> VisualRowChain {
	VisualRowChain(views: [rhs], spacings: [], pendingSpacing: nil, leadingMargin: lhs)
}

/// Applies a custom leading margin to an already-closed row:
/// `|--8--view--|` parses as `8 -- (view--|)`.
public func -- (lhs: CGFloat, rhs: VisualRow) -> VisualRow {
	var row = rhs
	row.leadingMargin = lhs
	return row
}

/// Integer overload for custom leading margin: `spacing -- element`.
public func -- (lhs: Int, rhs: any VisualLayoutAnchorable) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Double overload for custom leading margin: `spacing -- element`.
public func -- (lhs: Double, rhs: any VisualLayoutAnchorable) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Float overload for custom leading margin: `spacing -- element`.
public func -- (lhs: Float, rhs: any VisualLayoutAnchorable) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Integer overload for leading margin + already-closed row.
public func -- (lhs: Int, rhs: VisualRow) -> VisualRow {
	CGFloat(lhs) -- rhs
}

/// Double overload for leading margin + already-closed row.
public func -- (lhs: Double, rhs: VisualRow) -> VisualRow {
	CGFloat(lhs) -- rhs
}

/// Float overload for leading margin + already-closed row.
public func -- (lhs: Float, rhs: VisualRow) -> VisualRow {
	CGFloat(lhs) -- rhs
}

/// Starts a chain with a **custom leading margin** and an array of views: `spacing -- [view, view]`.
public func -- (lhs: CGFloat, rhs: [View]) -> VisualRowChain {
	let spacings = Array(repeating: CGFloat(0), count: max(0, rhs.count - 1))
	return VisualRowChain(views: rhs, spacings: spacings, pendingSpacing: nil, leadingMargin: lhs)
}

/// Integer overload for custom leading margin with view arrays: `spacing -- [view, view]`.
public func -- (lhs: Int, rhs: [View]) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Double overload for custom leading margin with view arrays: `spacing -- [view, view]`.
public func -- (lhs: Double, rhs: [View]) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Float overload for custom leading margin with view arrays: `spacing -- [view, view]`.
public func -- (lhs: Float, rhs: [View]) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Starts a chain with a **custom leading margin** and an array of guides: `spacing -- [guide, guide]`.
public func -- (lhs: CGFloat, rhs: [LayoutGuide]) -> VisualRowChain {
	let spacings = Array(repeating: CGFloat(0), count: max(0, rhs.count - 1))
	return VisualRowChain(views: rhs, spacings: spacings, pendingSpacing: nil, leadingMargin: lhs)
}

/// Starts a chain with a **custom leading margin** and a mixed array of views/guides and spacings:
/// `spacing -- [view1, 10, view2, 50.0, view3]`.
public func -- (lhs: CGFloat, rhs: VisualLayoutArrayItems) -> VisualRowChain {
	let parsed = parseMixedArrayItems(rhs)
	return VisualRowChain(views: parsed.views, spacings: parsed.spacings, pendingSpacing: nil, leadingMargin: lhs)
}

/// Integer overload for custom leading margin with guide arrays: `spacing -- [guide, guide]`.
public func -- (lhs: Int, rhs: [LayoutGuide]) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Double overload for custom leading margin with guide arrays: `spacing -- [guide, guide]`.
public func -- (lhs: Double, rhs: [LayoutGuide]) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Float overload for custom leading margin with guide arrays: `spacing -- [guide, guide]`.
public func -- (lhs: Float, rhs: [LayoutGuide]) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Integer overload for custom leading margin with mixed arrays.
public func -- (lhs: Int, rhs: VisualLayoutArrayItems) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Double overload for custom leading margin with mixed arrays.
public func -- (lhs: Double, rhs: VisualLayoutArrayItems) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Float overload for custom leading margin with mixed arrays.
public func -- (lhs: Float, rhs: VisualLayoutArrayItems) -> VisualRowChain {
	CGFloat(lhs) -- rhs
}

/// Starts a chain: `element -- spacing` stores the element with a pending inter-element gap.
public func -- (lhs: any VisualLayoutAnchorable, rhs: CGFloat) -> VisualRowChain {
	VisualRowChain(views: [lhs], spacings: [], pendingSpacing: rhs)
}

/// Integer overload for pending inter-element spacing: `element -- spacing`.
public func -- (lhs: any VisualLayoutAnchorable, rhs: Int) -> VisualRowChain {
	lhs -- CGFloat(rhs)
}

/// Double overload for pending inter-element spacing: `element -- spacing`.
public func -- (lhs: any VisualLayoutAnchorable, rhs: Double) -> VisualRowChain {
	lhs -- CGFloat(rhs)
}

/// Float overload for pending inter-element spacing: `element -- spacing`.
public func -- (lhs: any VisualLayoutAnchorable, rhs: Float) -> VisualRowChain {
	lhs -- CGFloat(rhs)
}

/// Starts a chain: `element -- element` defaults the gap to 0 unless explicitly set.
public func -- (lhs: any VisualLayoutAnchorable, rhs: any VisualLayoutAnchorable) -> VisualRowChain {
	VisualRowChain(views: [lhs, rhs], spacings: [0], pendingSpacing: nil)
}

/// Sets a new pending spacing on an existing chain: `chain -- spacing`.
public func -- (lhs: VisualRowChain, rhs: CGFloat) -> VisualRowChain {
	var chain = lhs
	chain.pendingSpacing = rhs
	return chain
}

/// Integer overload for pending spacing on an existing chain: `chain -- spacing`.
public func -- (lhs: VisualRowChain, rhs: Int) -> VisualRowChain {
	lhs -- CGFloat(rhs)
}

/// Double overload for pending spacing on an existing chain: `chain -- spacing`.
public func -- (lhs: VisualRowChain, rhs: Double) -> VisualRowChain {
	lhs -- CGFloat(rhs)
}

/// Float overload for pending spacing on an existing chain: `chain -- spacing`.
public func -- (lhs: VisualRowChain, rhs: Float) -> VisualRowChain {
	lhs -- CGFloat(rhs)
}

/// Appends an element to a chain, consuming the pending spacing (or 0).
public func -- (lhs: VisualRowChain, rhs: any VisualLayoutAnchorable) -> VisualRowChain {
	var chain = lhs
	chain.spacings.append(lhs.pendingSpacing ?? 0)
	chain.views.append(rhs)
	chain.pendingSpacing = nil
	return chain
}

/// Appends an array of views to a chain. The first view consumes the pending spacing;
/// subsequent views default to 0 spacing.
public func -- (lhs: VisualRowChain, rhs: [View]) -> VisualRowChain {
	var chain = lhs
	for (i, view) in rhs.enumerated() {
		chain.spacings.append(i == 0 ? (lhs.pendingSpacing ?? 0) : 0)
		chain.views.append(view)
	}
	chain.pendingSpacing = nil
	return chain
}

/// Appends an array of guides to a chain. The first guide consumes the pending spacing;
/// subsequent guides default to 0 spacing.
public func -- (lhs: VisualRowChain, rhs: [LayoutGuide]) -> VisualRowChain {
	var chain = lhs
	for (i, guide) in rhs.enumerated() {
		chain.spacings.append(i == 0 ? (lhs.pendingSpacing ?? 0) : 0)
		chain.views.append(guide)
	}
	chain.pendingSpacing = nil
	return chain
}

/// Closes a chain when the last element already had its trailing margin set by a postfix operator.
///
/// This overload handles the parse order in `|--a--20--b--|`:
/// - `b--|` fires first (postfix) → `VisualRow(b, trailing: 0)`
/// - `|-- a` fires next (prefix on element) → `VisualRowChain([a], leading: 0)`
/// - `chain -- 20` → sets pending spacing
/// - `chain -- VisualRow(b)` → this overload: merges chain + row into final `VisualRow`
public func -- (lhs: VisualRowChain, rhs: VisualRow) -> VisualRow {
	// An empty-view rhs is a trailing-margin carrier produced by `N--|` parse.
	// Just close the chain with rhs.trailingMargin, discarding the pending spacing.
	guard !rhs.views.isEmpty else {
		return VisualRow(chain: lhs, leadingMargin: lhs.leadingMargin, trailingMargin: rhs.trailingMargin)
	}
	var chain = lhs
	chain.spacings.append(lhs.pendingSpacing ?? 0)
	chain.views.append(contentsOf: rhs.views)
	return VisualRow(chain: chain, leadingMargin: chain.leadingMargin, trailingMargin: rhs.trailingMargin)
}

// MARK: - Postfix | for VisualRowChain — trailing, no margin (or pending spacing)

/// Closes a `VisualRowChain` with a trailing edge pin.
/// - If the chain ends with a pending spacing (`chain -- number |`), that value becomes
///   the trailing margin: e.g. `20--a--3--b--5|` → leading=20, spacing=3, trailing=5.
/// - Otherwise trailing margin is 0.
@discardableResult
public postfix func | (chain: VisualRowChain) -> VisualRow {
	VisualRow(chain: chain, leadingMargin: chain.leadingMargin, trailingMargin: chain.pendingSpacing ?? 0)
}

// MARK: - Postfix --| for element/array — trailing, zero margin

/// Pins the view or guide's trailing edge to the container with zero margin.
@discardableResult
public postfix func --| (element: any VisualLayoutAnchorable) -> VisualRow {
	VisualRow(views: [element], trailingMargin: 0)
}

/// Pins the last view's trailing edge to the container with zero margin.
@discardableResult
public postfix func --| (views: [View]) -> VisualRow {
	VisualRow(views: views, trailingMargin: 0)
}

/// Pins the last guide's trailing edge to the container with zero margin.
@discardableResult
public postfix func --| (guides: [LayoutGuide]) -> VisualRow {
	VisualRow(views: guides, trailingMargin: 0)
}

/// Pins a mixed array's trailing edge to the container with zero margin.
/// Supports arrays containing views/layout guides and numeric spacing values:
/// `|--[view1, 10, view2, 50.0, view3]--|`
@discardableResult
public postfix func --| (items: VisualLayoutArrayItems) -> VisualRow {
	rowFromMixedArray(items, trailingMargin: 0)
}

/// Trailing-margin carrier for integer literals in `chain -- N--|` expressions.
/// Swift applies `--|` to the literal before `--` can consume it;
/// the resulting empty-view row carries the trailing margin and is merged
/// by the `func -- (VisualRowChain, VisualRow)` overload.
@discardableResult
public postfix func --| (trailing: Int) -> VisualRow {
	VisualRow(views: [], trailingMargin: CGFloat(trailing))
}

/// Trailing-margin carrier for floating-point literals in `chain -- N.0--|` expressions.
@discardableResult
public postfix func --| (trailing: Double) -> VisualRow {
	VisualRow(views: [], trailingMargin: CGFloat(trailing))
}

/// Trailing-margin carrier for float values in `chain -- value--|` expressions.
@discardableResult
public postfix func --| (trailing: Float) -> VisualRow {
	VisualRow(views: [], trailingMargin: CGFloat(trailing))
}

/// Trailing-margin carrier for `CGFloat` values in `chain -- value--|` expressions.
@discardableResult
public postfix func --| (trailing: CGFloat) -> VisualRow {
	VisualRow(views: [], trailingMargin: trailing)
}

// MARK: - Postfix --| for VisualRowChain — closing fence

/// Closes a `VisualRowChain` with a trailing edge pin.
/// - If the chain ends with a pending spacing (`chain -- number --|`), that value becomes
///   the trailing margin: e.g. `|--16 -- a -- 16--|` → leading=16, trailing=16.
/// - Otherwise trailing margin is 0.
@discardableResult
public postfix func --| (chain: VisualRowChain) -> VisualRow {
	VisualRow(chain: chain, leadingMargin: chain.leadingMargin, trailingMargin: chain.pendingSpacing ?? 0)
}

// MARK: - Mixed Array Parsing

private func rowFromMixedArray(_ items: VisualLayoutArrayItems, trailingMargin: CGFloat) -> VisualRow {
	let parsed = parseMixedArrayItems(items)
	var row = VisualRow(views: parsed.views, trailingMargin: trailingMargin)
	row.interViewSpacings = parsed.spacings
	return row
}

private func parseMixedArrayItems(_ items: VisualLayoutArrayItems) -> (views: [any VisualLayoutAnchorable], spacings: [CGFloat]) {
	var views: [any VisualLayoutAnchorable] = []
	var spacings: [CGFloat] = []
	var pendingSpacing: CGFloat?

	for token in items.tokens {
		switch token {
		case let .anchor(view):
			if !views.isEmpty {
				spacings.append(pendingSpacing ?? 0)
			}
			views.append(view)
			pendingSpacing = nil
		case let .spacing(spacing):
			precondition(!views.isEmpty, "Visual layout mixed arrays must start with a view or layout guide.")
			// If multiple spacing literals appear in a row, the last one wins.
			pendingSpacing = spacing
		}
	}

	precondition(pendingSpacing == nil, "Visual layout mixed arrays cannot end with a spacing value.")
	return (views, spacings)
}
