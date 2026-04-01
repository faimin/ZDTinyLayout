//
//  NSLayoutConstraint+.swift
//  ZDTinyLayout
//
//  Created by Zero.D.Saber on 2026/3/31.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

/// Result builder used by `NSLayoutConstraint.tl.activate/deactivate`.
///
/// It lets call sites write constraints in a declarative block with support for:
/// - direct constraint expressions
/// - conditionals (`if` / `if-else`)
/// - loops (`for`)
@resultBuilder
public struct ZDTinyLayoutConstraintBuilder {
    /// Lifts a single constraint expression into a builder component.
    public static func buildExpression(_ expression: NSLayoutConstraint) -> [NSLayoutConstraint] {
        [expression]
    }

    /// Passes through array expressions used in advanced call sites.
    public static func buildExpression(_ expression: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
        expression
    }

    /// Merges all builder components from the block body.
    public static func buildBlock(_ components: [NSLayoutConstraint]...) -> [NSLayoutConstraint] {
        components.flatMap { $0 }
    }

    /// Flattens constraints produced by `for` loops.
    public static func buildArray(_ components: [[NSLayoutConstraint]]) -> [NSLayoutConstraint] {
        components.flatMap { $0 }
    }

    /// Handles optional branches (`if` without `else`).
    public static func buildOptional(_ component: [NSLayoutConstraint]?) -> [NSLayoutConstraint] {
        component ?? []
    }

    /// Handles the `if` branch in `if-else`.
    public static func buildEither(first component: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
        component
    }

    /// Handles the `else` branch in `if-else`.
    public static func buildEither(second component: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
        component
    }
}


@MainActor
public extension ZDTinyLayoutNamespace where Base: NSLayoutConstraint {
    /// Activates all constraints produced by the builder block.
    ///
    /// Usage:
    /// ```swift
    /// NSLayoutConstraint.tl.activate {
    ///     view1.topAnchor.constraint(equalTo: view2.bottomAnchor, constant: 8)
    ///     view1.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16)
    /// }
    /// ```
    static func activate(@ZDTinyLayoutConstraintBuilder _ constraints: () -> [NSLayoutConstraint]) {
        let constraintArr = constraints()
        guard !constraintArr.isEmpty else {
            return
        }
        NSLayoutConstraint.activate(constraintArr)
    }

    /// Deactivates all constraints produced by the builder block.
    static func deactivate(@ZDTinyLayoutConstraintBuilder _ constraints: () -> [NSLayoutConstraint]) {
        let constraintArr = constraints()
        guard !constraintArr.isEmpty else {
            return
        }
        NSLayoutConstraint.deactivate(constraintArr)
    }
}
