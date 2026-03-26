//
//  VisualLayoutOperators.swift
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

/// Pins the last view's trailing edge to the container with zero margin.
@discardableResult
public postfix func | (views: [VisualLayoutView]) -> VisualRow {
	VisualRow(views: views, trailingMargin: 0)
}

/// Pins the last guide's trailing edge to the container with zero margin.
@discardableResult
public postfix func | (guides: [VisualLayoutGuide]) -> VisualRow {
	VisualRow(views: guides, trailingMargin: 0)
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

/// Starts a chain: `element -- spacing` stores the element with a pending inter-element gap.
public func -- (lhs: any VisualLayoutAnchorable, rhs: CGFloat) -> VisualRowChain {
	VisualRowChain(views: [lhs], spacings: [], pendingSpacing: rhs)
}

/// Starts a chain: `element -- element` uses `visualLayoutDefaultSpacing` as the gap.
public func -- (lhs: any VisualLayoutAnchorable, rhs: any VisualLayoutAnchorable) -> VisualRowChain {
	VisualRowChain(views: [lhs, rhs], spacings: [visualLayoutDefaultSpacing], pendingSpacing: nil)
}

/// Sets a new pending spacing on an existing chain: `chain -- spacing`.
public func -- (lhs: VisualRowChain, rhs: CGFloat) -> VisualRowChain {
	var chain = lhs
	chain.pendingSpacing = rhs
	return chain
}

/// Appends an element to a chain, consuming the pending spacing (or `visualLayoutDefaultSpacing`).
public func -- (lhs: VisualRowChain, rhs: any VisualLayoutAnchorable) -> VisualRowChain {
	var chain = lhs
	chain.spacings.append(lhs.pendingSpacing ?? visualLayoutDefaultSpacing)
	chain.views.append(rhs)
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
	chain.spacings.append(lhs.pendingSpacing ?? visualLayoutDefaultSpacing)
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
public postfix func --| (views: [VisualLayoutView]) -> VisualRow {
	VisualRow(views: views, trailingMargin: 0)
}

/// Pins the last guide's trailing edge to the container with zero margin.
@discardableResult
public postfix func --| (guides: [VisualLayoutGuide]) -> VisualRow {
	VisualRow(views: guides, trailingMargin: 0)
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

// MARK: - Postfix --| for VisualRowChain — closing fence

/// Closes a `VisualRowChain` with a trailing edge pin.
/// - If the chain ends with a pending spacing (`chain -- number --|`), that value becomes
///   the trailing margin: e.g. `|--16 -- a -- 16--|` → leading=16, trailing=16.
/// - Otherwise trailing margin is 0.
@discardableResult
public postfix func --| (chain: VisualRowChain) -> VisualRow {
	VisualRow(chain: chain, leadingMargin: chain.leadingMargin, trailingMargin: chain.pendingSpacing ?? 0)
}
