//
//  ZDTLStackable+Hairlines.swift
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

// MARK: - ZDTLStackableHairline

/// Carries information about where to build a hairline, plus any manipulations
/// needed before adding it to a stack view.
@MainActor
public struct ZDTLStackableHairline {

    internal enum HairlineType {
        case next
        case after(_ view: UIView?)
        case between(_ view1: UIView?, _ view2: UIView?)
        case before(_ view: UIView?)
        case around(_ view: UIView?)
    }

    internal let type: HairlineType
    internal var thicknessOverride: CGFloat?
    internal var colorOverride: UIColor?
    internal var inset: UIEdgeInsets = .zero
    internal var outsetAncestor: UIView?
}

// MARK: - tl namespace: Hairline factory methods

public extension ZDTinyLayoutNamespace where Base: UIStackView {

    static var hairline: ZDTLStackableHairline {
        return .init(type: .next)
    }

    static func hairline(after view: UIView) -> ZDTLStackableHairline {
        return .init(type: .after(view))
    }

    static func hairlineBetween(_ view1: UIView?, _ view2: UIView?) -> ZDTLStackableHairline {
        return .init(type: .between(view1, view2))
    }

    static func hairline(before view: UIView?) -> ZDTLStackableHairline {
        return .init(type: .before(view))
    }

    static func hairline(around view: UIView?) -> ZDTLStackableHairline {
        return .init(type: .around(view))
    }

    static func hairlines(between views: [UIView]) -> [ZDTLStackableHairline] {
        let pairs = zip(views, views.dropFirst())
        return pairs.map { UIStackView.tl.hairlineBetween($0.0, $0.1) }
    }

    static func hairlines(after views: [UIView]) -> [ZDTLStackableHairline] {
        return views.map { UIStackView.tl.hairline(after: $0) }
    }

    static func hairlines(around views: [UIView]) -> [ZDTLStackableHairline] {
        return views.map { $0 == views.first
            ? UIStackView.tl.hairline(around: $0)
            : UIStackView.tl.hairline(after: $0)
        }
    }
}

// MARK: - Hairline modifiers

public extension ZDTLStackableHairline {

    func inset(by margins: UIEdgeInsets) -> ZDTLStackableHairline {
        var hairline = self
        hairline.inset = margins
        return hairline
    }

    func outset(to ancestor: UIView) -> ZDTLStackableHairline {
        var hairline = self
        hairline.outsetAncestor = ancestor
        return hairline
    }

    func thickness(_ thickness: CGFloat) -> ZDTLStackableHairline {
        var hairline = self
        hairline.thicknessOverride = thickness
        return hairline
    }

    func color(_ color: UIColor) -> ZDTLStackableHairline {
        var hairline = self
        hairline.colorOverride = color
        return hairline
    }
}

@MainActor
public extension Array where Element == ZDTLStackableHairline {

    func inset(by margins: UIEdgeInsets) -> Self {
        return map { $0.inset(by: margins) }
    }

    func outset(to ancestor: UIView) -> Self {
        return map { $0.outset(to: ancestor) }
    }

    func thickness(_ thickness: CGFloat) -> Self {
        return map { $0.thickness(thickness) }
    }

    func color(_ color: UIColor) -> Self {
        return map { $0.color(color) }
    }
}

// MARK: - ZDTLStackableHairlineView

internal final class ZDTLStackableHairlineView: UIView {

    init(stackAxis axis: NSLayoutConstraint.Axis, thickness: CGFloat, color: UIColor) {
        super.init(frame: .zero)

        accessibilityIdentifier = UIStackView.tl.axID.hairline

        NSLayoutConstraint.activate([
            self.dimension(along: axis).constraint(equalToConstant: thickness),
        ])

        setContentHuggingPriority(.required, for: axis)
        setContentCompressionResistancePriority(.required, for: axis)

        backgroundColor = color
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ZDTLStackableHairline: ZDTLStackable

extension ZDTLStackableHairline: ZDTLStackable {

    public func configure(stackView: UIStackView) {
        if let view = hairlineBeforeView {
            insertHairline(stackView: stackView) { stack, hairline in
                stack.tl.insertArrangedSubview(hairline, beforeArrangedSubview: view)
            }
        }
        if let view = hairlineAfterView {
            insertHairline(stackView: stackView) { stack, hairline in
                stack.tl.insertArrangedSubview(hairline, afterArrangedSubview: view)
            }
        }
        if case .next = type {
            insertHairline(stackView: stackView) { stack, hairline in
                stack.addArrangedSubview(hairline)
            }
        }
    }

    private func insertHairline(stackView: UIStackView, insert: (UIStackView, UIView) -> Void) {
        let hairline = makeHairline(stackView: stackView)
        let outsetHairline = outsetIfNecessary(
            view: hairline,
            outsetAncestor: outsetAncestor,
            inset: inset,
            stackView: stackView)
            .makeStackableView(for: stackView)
        insert(stackView, outsetHairline)
        applyOutsetConstraint(view: hairline, outsetAncestor: outsetAncestor, stackView: stackView)
    }

    private func makeHairline(stackView: UIStackView) -> UIView {
        let hairline = stackView.tl.hairlineProvider?(stackView)
            ?? UIStackView.tl.hairlineProvider?(stackView)
            ?? ZDTLStackableHairlineView(
                stackAxis: stackView.axis,
                thickness: thicknessOverride
                    ?? stackView.tl.hairlineThickness
                    ?? UIStackView.tl.hairlineThickness
                    ?? UIStackView.Default.hairlineThickness,
                color: colorOverride
                    ?? stackView.tl.hairlineColor
                    ?? UIStackView.tl.hairlineColor
                    ?? UIStackView.Default.hairlineColor
        )

        hairline.tl.bindVisible(toAllVisible: allViews)
        return hairline
    }

    private var allViews: [UIView] {
        switch type {
        case .next: return []
        case .after(let view): return [view].compactMap { $0 }
        case .between(let v0, let v1): return [v0, v1].compactMap { $0 }
        case .before(let view): return [view].compactMap { $0 }
        case .around(let view): return [view].compactMap { $0 }
        }
    }

    private var hairlineAfterView: UIView? {
        switch type {
        case .next: return nil
        case .after(let view): return view
        case .between(let v0, .some): return v0
        case .between: return nil
        case .before: return nil
        case .around(let view): return view
        }
    }

    private var hairlineBeforeView: UIView? {
        switch type {
        case .next: return nil
        case .after: return nil
        case .between: return nil
        case .before(let view): return view
        case .around(let view): return view
        }
    }
}

// MARK: - Hairline provider type

public typealias ZDTLStackableHairlineProvider = (UIStackView) -> UIView

// MARK: - Associated properties for UIStackView hairline config

extension UIStackView {
    @MainActor
    fileprivate struct AssociatedKeys {
        static var hairlineColor: Void?
        static var hairlineThickness: Void?
        static var hairlineProvider: Void?
    }

    @MainActor
    fileprivate struct Default {
        static let hairlineColor = UIColor.lightGray
        static let hairlineThickness = CGFloat(1.0)
    }
}

public extension ZDTinyLayoutNamespace where Base: UIStackView {

    var hairlineColor: UIColor? {
        get { return objc_getAssociatedObject(base, &UIStackView.AssociatedKeys.hairlineColor) as? UIColor }
        set { objc_setAssociatedObject(base, &UIStackView.AssociatedKeys.hairlineColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var hairlineThickness: CGFloat? {
        get { return objc_getAssociatedObject(base, &UIStackView.AssociatedKeys.hairlineThickness) as? CGFloat }
        set { objc_setAssociatedObject(base, &UIStackView.AssociatedKeys.hairlineThickness, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var hairlineProvider: ZDTLStackableHairlineProvider? {
        get { return objc_getAssociatedObject(base, &UIStackView.AssociatedKeys.hairlineProvider) as? ZDTLStackableHairlineProvider }
        set { objc_setAssociatedObject(base, &UIStackView.AssociatedKeys.hairlineProvider, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    static var hairlineColor: UIColor? {
        get { return objc_getAssociatedObject(self, &UIStackView.AssociatedKeys.hairlineColor) as? UIColor }
        set { objc_setAssociatedObject(self, &UIStackView.AssociatedKeys.hairlineColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    static var hairlineThickness: CGFloat? {
        get { return objc_getAssociatedObject(self, &UIStackView.AssociatedKeys.hairlineThickness) as? CGFloat }
        set { objc_setAssociatedObject(self, &UIStackView.AssociatedKeys.hairlineThickness, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    static var hairlineProvider: ZDTLStackableHairlineProvider? {
        get { return objc_getAssociatedObject(self, &UIStackView.AssociatedKeys.hairlineProvider) as? ZDTLStackableHairlineProvider }
        set { objc_setAssociatedObject(self, &UIStackView.AssociatedKeys.hairlineProvider, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

#endif
