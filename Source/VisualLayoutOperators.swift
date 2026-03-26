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
infix operator .= : VisualLayoutHeightPrecedence

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

// MARK: - Infix := — height

/// Sets the height of all views in the row to `rhs` points.
@discardableResult
public func .= (lhs: VisualRow, rhs: CGFloat) -> VisualRow {
    var r = lhs
    r.height = rhs
    r.heightRelation = .equal
    return r
}
