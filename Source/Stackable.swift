//
//  Stackable.swift
//  ZDTinyLayout
//
//  Adapted from Stackable (https://github.com/rightpoint/Stackable)
//  Copyright 2020 Rightpoint and other contributors
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

#if !os(macOS)

// MARK: - Stackable

/// Any object conforming to `Stackable` simply needs to define how it interacts with a
/// stack view, most often by adding views or spacing.
///
/// Objects that simply add a single arranged subview can conform to `StackableView` instead
/// to receive automatic insetting and alignment functionality.
///
/// ```swift
/// extension String: Stackable {
///     func configure(stackView: UIStackView) {
///         let label = UILabel()
///         label.text = self
///         stackView.addArrangedSubview(label)
///     }
/// }
/// ```
@MainActor
public protocol Stackable {
    /// Defines how to interact with a stack view.
    /// Never call this method directly.
    ///
    /// - Parameter stackView: The stack view to be manipulated.
    func configure(stackView: UIStackView)
}

// MARK: - StackableView

/// Conformance to `StackableView` receives automatic conformance to `Stackable`,
/// and inherits functionality for insetting and alignment.
///
/// Types that manipulate a stack view further than simply adding a single arranged subview
/// should conform to `Stackable` directly.
@MainActor
public protocol StackableView: Stackable {
    /// Creates the view to be added to the stack view.
    ///
    /// - Parameter stackView: The stack view that your view will be added to.
    ///   Should not be manipulated, but can be queried for `.axis`, etc.
    /// - Returns: A view to be added to the stack view.
    func makeStackableView(for stackView: UIStackView) -> UIView
}

extension StackableView {
    public func configure(stackView: UIStackView) {
        let view = makeStackableView(for: stackView)
        stackView.addArrangedSubview(view)
    }
}

// MARK: - tl namespace: UIStackView add methods

@MainActor
extension ZDTinyLayoutNamespace where Base: UIStackView {

    /// Adds a `Stackable` item to the stack view.
    ///
    /// ```swift
    /// stackView.tl.add("Hello World!")
    /// stackView.tl.add(20)
    /// stackView.tl.add(UIStackView.tl.hairline)
    /// stackView.tl.add(UIStackView.tl.flexibleSpace)
    /// ```
    @discardableResult
    public func add(_ stackable: any Stackable) -> Base {
        add([stackable])
        return base
    }

    /// Adds `Stackable` items to the stack view.
    ///
    /// ```swift
    /// let cells: [UIView] = ...
    /// stackView.tl.add([
    ///     "Hello World!",
    ///     20,
    ///     UIStackView.tl.hairline,
    ///     cells,
    ///     UIStackView.tl.flexibleSpace,
    /// ])
    /// ```
    @discardableResult
    public func add(_ stackables: [any Stackable]) -> Base {
        stackables.forEach { $0.configure(stackView: base) }
        return base
    }

    /// Adds `Stackable` items to the stack view using a result builder.
    ///
    /// ```swift
    /// stackView.tl.add {
    ///     "Hello World!"
    ///     20
    ///     UIStackView.tl.hairline
    ///     cells
    ///     UIStackView.tl.flexibleSpace
    /// }
    /// ```
    @discardableResult
    public func add(@StackableBuilder _ stackables: () -> [any Stackable]) -> Base {
        add(stackables())
        return base
    }
}

// MARK: - Array Conformance

extension Array: @MainActor Stackable where Element: Stackable {
    public func configure(stackView: UIStackView) {
        forEach { $0.configure(stackView: stackView) }
    }
}

// MARK: - Optional Conformance

extension Optional: @MainActor Stackable where Wrapped: Stackable {
    public func configure(stackView: UIStackView) {
        map { $0.configure(stackView: stackView) }
    }
}

#endif
