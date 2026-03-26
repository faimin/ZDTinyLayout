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
postfix operator -|
prefix operator |
prefix operator |-

precedencegroup VisualLayoutHeightPrecedence {
    lowerThan: AdditionPrecedence
    higherThan: AssignmentPrecedence
    associativity: left
}
infix operator /=/ : VisualLayoutHeightPrecedence
infix operator -- : AdditionPrecedence

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

/// Opens a `--` chain with zero leading margin: `|view -- spacing -- view`.
@discardableResult
public prefix func | (view: VisualLayoutView) -> VisualRowChain {
    VisualRowChain(views: [view], spacings: [], pendingSpacing: nil, leadingMargin: 0)
}

// MARK: - Prefix |- — leading, default margin

/// Pins the row's first view's leading edge to the container with `visualLayoutDefaultMargin`.
@discardableResult
public prefix func |- (row: VisualRow) -> VisualRow {
    var r = row
    r.leadingMargin = visualLayoutDefaultMargin
    return r
}

/// Opens a `--` chain with `visualLayoutDefaultMargin` leading margin: `|-view -- spacing -- view`.
@discardableResult
public prefix func |- (view: VisualLayoutView) -> VisualRowChain {
    VisualRowChain(views: [view], spacings: [], pendingSpacing: nil, leadingMargin: visualLayoutDefaultMargin)
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

// MARK: - Infix -- (VisualRowChain builder)
//
// Syntax A — custom inter-view spacing with prefix leading margin:
//   |-a--20--b--30--c-|
//   Parse: b-| (postfix) → VisualRow(trailing:8)
//          |- a (prefix on View) → VisualRowChain([a], leading:8)
//          chain--20 / chain--VisualRow → final VisualRow
//
// Syntax B — custom leading margin via leading number:
//   20--a--3--b|
//   Parse: b| (postfix) → VisualRow(trailing:0)
//          20--a (CGFloat--View) → VisualRowChain([a], leading:20)
//          chain--3 / chain--VisualRow → final VisualRow

/// Starts a chain with a **custom leading margin**: `spacing -- view`.
/// The `CGFloat` becomes the distance from the container's leading edge to `view`.
public func -- (lhs: CGFloat, rhs: VisualLayoutView) -> VisualRowChain {
    VisualRowChain(views: [rhs], spacings: [], pendingSpacing: nil, leadingMargin: lhs)
}

/// Starts a chain: `view -- spacing` stores the view with a pending inter-view gap.
public func -- (lhs: VisualLayoutView, rhs: CGFloat) -> VisualRowChain {
    VisualRowChain(views: [lhs], spacings: [], pendingSpacing: rhs)
}

/// Starts a chain: `view -- view` uses `visualLayoutDefaultMargin` as the gap.
public func -- (lhs: VisualLayoutView, rhs: VisualLayoutView) -> VisualRowChain {
    VisualRowChain(views: [lhs, rhs], spacings: [visualLayoutDefaultMargin], pendingSpacing: nil)
}

/// Sets a new pending spacing on an existing chain: `chain -- spacing`.
public func -- (lhs: VisualRowChain, rhs: CGFloat) -> VisualRowChain {
    var chain = lhs
    chain.pendingSpacing = rhs
    return chain
}

/// Appends a view to a chain, consuming the pending spacing (or `visualLayoutDefaultMargin`).
public func -- (lhs: VisualRowChain, rhs: VisualLayoutView) -> VisualRowChain {
    var chain = lhs
    chain.spacings.append(lhs.pendingSpacing ?? visualLayoutDefaultMargin)
    chain.views.append(rhs)
    chain.pendingSpacing = nil
    return chain
}

/// Closes a chain when the last view already had its trailing margin set by a postfix operator.
///
/// This overload handles the parse order in `|-a--20--b-|`:
/// - `b -|` fires first (postfix) → `VisualRow(b, trailing: 8)`
/// - `|- a` fires next (prefix on View) → `VisualRowChain([a], leading: 8)`
/// - `chain -- 20` → sets pending spacing
/// - `chain -- VisualRow(b)` → this overload: merges chain + row into final `VisualRow`
public func -- (lhs: VisualRowChain, rhs: VisualRow) -> VisualRow {
    var chain = lhs
    chain.spacings.append(lhs.pendingSpacing ?? visualLayoutDefaultMargin)
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

// MARK: - Postfix -| for VisualRowChain — trailing, default margin

/// Closes a `VisualRowChain` with a trailing edge pin of `visualLayoutDefaultMargin`.
@discardableResult
public postfix func -| (chain: VisualRowChain) -> VisualRow {
    VisualRow(chain: chain, leadingMargin: chain.leadingMargin, trailingMargin: visualLayoutDefaultMargin)
}
