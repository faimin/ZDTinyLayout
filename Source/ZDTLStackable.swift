//
//  ZDTLStackable.swift
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

// MARK: - ZDTLStackable

/// Any object conforming to `ZDTLStackable` simply needs to define how it interacts with a
/// stack view, most often by adding views or spacing.
///
/// Objects that simply add a single arranged subview can conform to `ZDTLStackableView` instead
/// to receive automatic insetting and alignment functionality.
///
/// ```swift
/// extension String: ZDTLStackable {
///     func configure(stackView: UIStackView) {
///         let label = UILabel()
///         label.text = self
///         stackView.addArrangedSubview(label)
///     }
/// }
/// ```
@MainActor
public protocol ZDTLStackable {
    /// Defines how to interact with a stack view.
    /// Never call this method directly.
    ///
    /// - Parameter stackView: The stack view to be manipulated.
    func configure(stackView: UIStackView)
}

// MARK: - ZDTLStackableView

/// Conformance to `ZDTLStackableView` receives automatic conformance to `ZDTLStackable`,
/// and inherits functionality for insetting and alignment.
///
/// Types that manipulate a stack view further than simply adding a single arranged subview
/// should conform to `ZDTLStackable` directly.
@MainActor
public protocol ZDTLStackableView: ZDTLStackable {
    /// Creates the view to be added to the stack view.
    ///
    /// - Parameter stackView: The stack view that your view will be added to.
    ///   Should not be manipulated, but can be queried for `.axis`, etc.
    /// - Returns: A view to be added to the stack view.
    func makeStackableView(for stackView: UIStackView) -> UIView
}

extension ZDTLStackableView {
    public func configure(stackView: UIStackView) {
        let view = makeStackableView(for: stackView)
        stackView.addArrangedSubview(view)
    }
}

// MARK: - tl namespace: UIStackView add methods

@MainActor
extension ZDTinyLayoutNamespace where Base: UIStackView {

    /// Adds a `ZDTLStackable` item to the stack view.
    ///
    /// ```swift
    /// stackView.tl.add("Hello World!")
    /// stackView.tl.add(20)
    /// stackView.tl.add(UIStackView.tl.hairline)
    /// stackView.tl.add(UIStackView.tl.flexibleSpace)
    /// ```
    @discardableResult
    public func add(_ stackable: any ZDTLStackable) -> Base {
        add([stackable])
        return base
    }

    /// Adds `ZDTLStackable` items to the stack view.
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
    public func add(_ stackables: [any ZDTLStackable]) -> Base {
        stackables.forEach { $0.configure(stackView: base) }
        return base
    }

    /// Adds `ZDTLStackable` items to the stack view using a result builder.
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
    public func add(@ZDTLStackableBuilder _ stackables: () -> [any ZDTLStackable]) -> Base {
        add(stackables())
        return base
    }
}

// MARK: - Array Conformance

@MainActor
extension Array: ZDTLStackable where Element: ZDTLStackable {
    public func configure(stackView: UIStackView) {
        forEach { $0.configure(stackView: stackView) }
    }
}

// MARK: - Optional Conformance

@MainActor
extension Optional: ZDTLStackable where Wrapped: ZDTLStackable {
    public func configure(stackView: UIStackView) {
        map { $0.configure(stackView: stackView) }
    }
}

#endif
