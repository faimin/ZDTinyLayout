//
//  ZDTLScrollingStackView.swift
//  ZDTinyLayout
//
//  Adapted from Stackable (https://github.com/rightpoint/Stackable)
//  Copyright 2020 Rightpoint and other contributors
//

#if os(macOS)
import Cocoa
#else
import UIKit

/// A stack view in a scroll view whose content height prefers to be at least the
/// frame height of the scroll view. If content grows beyond the frame, scrolling is enabled.
open class ZDTLScrollingStackView: UIScrollView {

    open override var layoutMargins: UIEdgeInsets {
        set { contentView.layoutMargins = newValue }
        get { return contentView.layoutMargins }
    }

    /// All subviews should be added to `stackView` directly.
    public let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    override open func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIControl
            && !(view is UITextInput)
            && !(view is UISlider)
            && !(view is UISwitch) {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }

    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        topSafeAreaConstraint?.constant = safeAreaInsets.top
        bottomSafeAreaConstraint?.constant = safeAreaInsets.bottom
    }

    var topSafeAreaConstraint: NSLayoutConstraint?
    var bottomSafeAreaConstraint: NSLayoutConstraint?

    private let contentView = UIView()

    public init() {
        super.init(frame: .zero)

        contentInsetAdjustmentBehavior = .never

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.clipsToBounds = false

        topSafeAreaConstraint = contentView.topAnchor.constraint(equalTo: topAnchor, constant: safeAreaInsets.top)
        topSafeAreaConstraint?.isActive = true

        bottomSafeAreaConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: safeAreaInsets.bottom)
        bottomSafeAreaConstraint?.isActive = true

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.heightAnchor),
            contentView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
        ])

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Convenience add methods

public extension ZDTLScrollingStackView {

    func add(_ stackable: any ZDTLStackable) {
        stackView.tl.add(stackable)
    }

    @discardableResult
    func add(_ stackables: [any ZDTLStackable]) -> Self {
        stackView.tl.add(stackables)
        return self
    }

    @discardableResult
    func add(@ZDTLStackableBuilder _ stackablesBlock: () -> [any ZDTLStackable]) -> Self {
        stackView.tl.add(stackablesBlock())
        return self
    }
}
#endif
