//
//  View+.swift
//  ZDTinyLayout
//
//  Created by Zero.D.Saber on 2026/4/1.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

// MARK: - ZDTLComponetBuilder

/// Result builder used by `View.tl.addComponents`.
///
/// It supports direct expressions, optionals, conditionals, switches,
/// availability branches, and loops, then flattens everything into `[T]`.
@resultBuilder
public struct ZDTLComponentBuilder<T> {
    // MARK: Nested Types

    public typealias Expression = T
    public typealias Component = [T]

    // MARK: Static Functions

    public static func buildExpression(_ expression: Expression?) -> Component {
        guard let expression = expression else {
            return []
        }
        return [expression]
    }

    public static func buildExpression(_ expression: Expression) -> Component {
        [expression]
    }

    /// Handles `if` branches without `else`.
    public static func buildOptional(_ component: Component?) -> Component {
        guard let component = component else {
            return []
        }
        return component
    }

    /// Handles the `if` branch in `if-else`, and `switch` cases.
    public static func buildEither(first component: Component) -> Component {
        component
    }

    /// Handles the `else` branch in `if-else`, and `switch` cases.
    public static func buildEither(second component: Component) -> Component {
        component
    }

    /// Handles `if #available` branches.
    public static func buildLimitedAvailability(_ component: Component) -> Component {
        component
    }

    /// Handles `for-in` loops.
    public static func buildArray(_ components: [Component]) -> Component {
        components.flatMap { $0 }
    }

    /// Combines all child components into one flat array.
    public static func buildBlock(_ components: Component...) -> Component {
        components.flatMap { $0 }
    }

    public static func buildPartialBlock(first: Component) -> Component {
        first
    }

    public static func buildPartialBlock(
        accumulated: Component,
        next: Component
    ) -> Component {
        accumulated + next
    }
}

// MARK: - ZDTLComponentsProtocol

/// Marker protocol for component types accepted by `addComponents`.
///
/// Supported concrete types:
/// - `View`
/// - `LayoutGuide`
/// - `CALayer`
/// - `ViewController`
public protocol ZDTLComponentsProtocol: AnyObject {}

// MARK: - UIView + ZDTLComponentsProtocol

extension View: ZDTLComponentsProtocol {}

// MARK: - UIViewController + ZDTLComponentsProtocol

extension ViewController: ZDTLComponentsProtocol {}

// MARK: - CALayer + ZDTLComponentsProtocol

extension CALayer: ZDTLComponentsProtocol {}

// MARK: - UILayoutGuide + ZDTLComponentsProtocol

extension LayoutGuide: ZDTLComponentsProtocol {}

extension VisualLayoutNamespace where Base: View {
    /// Adds components to the receiver in declaration order.
    ///
    /// - Views are added via `addSubview(_:)`.
    /// - Layout guides are added via `addLayoutGuide(_:)`.
    /// - Layers are added to `base.layer`.
    /// - View controllers contribute their `view` as a subview.
    ///
    /// Usage:
    /// ```swift
    /// container.tl.addComponents {
    ///     headerView
    ///     if showFooter { footerView }
    ///     separatorLayer
    /// }
    /// ```
    ///
    /// - Returns: The receiver (`base`) for chaining.
    @discardableResult
    func addComponents(
        @ZDTLComponentBuilder<any ZDTLComponentsProtocol> _ components: () -> [any ZDTLComponentsProtocol]
    ) -> Base {
        for item in components() {
            if let view = item as? View {
                base.addSubview(view)
            } else if let guide = item as? LayoutGuide {
                base.addLayoutGuide(guide)
            } else if let layer = item as? CALayer {
#if os(macOS)
                if base.layer == nil {
                    base.wantsLayer = true
                }
                base.layer?.addSublayer(layer)
#else
                base.layer.addSublayer(layer)
#endif
            } else if let vc = item as? ViewController {
                base.addSubview(vc.view)
            } else {
                assertionFailure("Not supported type => \(String(describing: item))")
            }
        }
        return base
    }
}
