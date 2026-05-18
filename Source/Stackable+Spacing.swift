//
//  Stackable+Spacing.swift
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

// MARK: - StackableSpaceItem

/// The public type representing a space. Opaque to consumer and cannot be manipulated further.
public struct StackableSpaceItem {
    internal let type: SpaceType

    internal enum SpaceType {
        case smartSpace(CGFloat)
        case constantSpace(CGFloat)
        case spaceBefore(_ view: UIView?, CGFloat)
        case spaceAfter(_ view: UIView?, CGFloat)
        case spaceBetween(_ view1: UIView?, _ view2: UIView?, CGFloat)
        case spaceAfterGroup([UIView], CGFloat)
        case flexibleSpace(StackableFlexibleSpace)
    }
}

/// Defines the different types of spaces with flexible bounds.
public enum StackableFlexibleSpace {
    case atLeast(CGFloat)
    case range(ClosedRange<CGFloat>)
    case atMost(CGFloat)
}

// MARK: - tl namespace: Space factory methods

public extension ZDTinyLayoutNamespace where Base: UIStackView {

    static func space(_ space: CGFloat) -> StackableSpaceItem {
        return .init(type: .smartSpace(space))
    }

    static func space(after view: UIView?, _ space: CGFloat) -> StackableSpaceItem {
        return .init(type: .spaceAfter(view, space))
    }

    static func space(before view: UIView?, _ space: CGFloat) -> StackableSpaceItem {
        return .init(type: .spaceBefore(view, space))
    }

    static func spaceBetween(_ view1: UIView?, _ view2: UIView?, _ space: CGFloat) -> StackableSpaceItem {
        return .init(type: .spaceBetween(view1, view2, space))
    }

    static func spaces(between views: [UIView], _ space: CGFloat) -> [StackableSpaceItem] {
        let pairs = zip(views, views.dropFirst())
        return pairs.map { UIStackView.tl.spaceBetween($0.0, $0.1, space) }
    }

    static func space(afterGroup group: [UIView], _ space: CGFloat) -> StackableSpaceItem {
        return .init(type: .spaceAfterGroup(group, space))
    }

    static func constantSpace(_ space: CGFloat) -> StackableSpaceItem {
        return .init(type: .constantSpace(space))
    }

    static func flexibleSpace(_ flexibleSpace: StackableFlexibleSpace = .atLeast(0)) -> StackableSpaceItem {
        return .init(type: .flexibleSpace(flexibleSpace))
    }

    static var flexibleSpace: StackableSpaceItem {
        return UIStackView.tl.flexibleSpace()
    }
}

// MARK: - StackableSpace

internal protocol StackableSpace: Stackable {
    func spaceType(for stackView: UIStackView) -> StackableSpaceItem.SpaceType
}

extension StackableSpace {
    @MainActor
    public func configure(stackView: UIStackView) {
        let type = spaceType(for: stackView)
        let item = StackableSpaceItem(type: type)
        item.configure(stackView: stackView)
    }
}

// MARK: - Fixed Space Conformance

extension CGFloat: StackableSpace {
    func spaceType(for stackView: UIStackView) -> StackableSpaceItem.SpaceType {
        return .smartSpace(self)
    }
}

extension Int: StackableSpace {
    func spaceType(for stackView: UIStackView) -> StackableSpaceItem.SpaceType {
        return CGFloat(self).spaceType(for: stackView)
    }
}

extension Float: StackableSpace {
    func spaceType(for stackView: UIStackView) -> StackableSpaceItem.SpaceType {
        CGFloat(self).spaceType(for: stackView)
    }
}

extension Double: StackableSpace {
    func spaceType(for stackView: UIStackView) -> StackableSpaceItem.SpaceType {
        CGFloat(self).spaceType(for: stackView)
    }
}

// MARK: - Flexible Space Conformance

extension ClosedRange: StackableSpace {
    func spaceType(for stackView: UIStackView) -> StackableSpaceItem.SpaceType {
        switch (lowerBound, upperBound) {
        case let (lower, upper) as (CGFloat, CGFloat):
            return .flexibleSpace(.range(lower...upper))
        case let (lower, upper) as (Int, Int):
            return .flexibleSpace(.range(CGFloat(lower)...CGFloat(upper)))
        case let (lower, upper) as (Float, Float):
            return .flexibleSpace(.range(CGFloat(lower)...CGFloat(upper)))
        case let (lower, upper) as (Double, Double):
            return .flexibleSpace(.range(CGFloat(lower)...CGFloat(upper)))
        default:
            preconditionFailure("unsupported range bound: \(Bound.self)")
        }
    }
}

extension PartialRangeFrom: StackableSpace {
    func spaceType(for stackView: UIStackView) -> StackableSpaceItem.SpaceType {
        switch lowerBound {
        case let lower as CGFloat:
            return .flexibleSpace(.atLeast(lower))
        case let lower as Int:
            return .flexibleSpace(.atLeast(CGFloat(lower)))
        case let lower as Float:
            return .flexibleSpace(.atLeast(CGFloat(lower)))
        case let lower as Double:
            return .flexibleSpace(.atLeast(CGFloat(lower)))
        default:
            preconditionFailure("unsupported range bound: \(Bound.self)")
        }
    }
}

extension PartialRangeThrough: StackableSpace {
    func spaceType(for stackView: UIStackView) -> StackableSpaceItem.SpaceType {
        switch upperBound {
        case let upper as CGFloat:
            return .flexibleSpace(.atMost(upper))
        case let upper as Int:
            return .flexibleSpace(.atMost(CGFloat(upper)))
        case let upper as Float:
            return .flexibleSpace(.atMost(CGFloat(upper)))
        case let upper as Double:
            return .flexibleSpace(.atMost(CGFloat(upper)))
        default:
            preconditionFailure("unsupported range bound: \(Bound.self)")
        }
    }
}

// MARK: - StackableSpaceItem: Stackable

extension StackableSpaceItem: Stackable {

    public func configure(stackView: UIStackView) {
        switch type {

        case let .smartSpace(space):
            let newType: StackableSpaceItem.SpaceType
            if let view = stackView.arrangedSubviews.last {
                newType = .spaceAfter(view, space)
            } else {
                newType = .constantSpace(space)
            }
            StackableSpaceItem(type: newType).configure(stackView: stackView)

        case let .constantSpace(space):
            let spacer = StackableSpacer()
            spacer.setContentHuggingPriority(.required, for: stackView.axis)
            NSLayoutConstraint.activate([
                spacer.dimension(along: stackView.axis).constraint(equalToConstant: space),
            ])
            stackView.addArrangedSubview(spacer)

        case let .spaceBefore(view, space):
            guard let view = view else { return }
            let spacer = StackableSpacer()
            spacer.setContentHuggingPriority(.required, for: stackView.axis)
            NSLayoutConstraint.activate([
                spacer.dimension(along: stackView.axis).constraint(equalToConstant: space),
            ])
            stackView.tl.insertArrangedSubview(spacer, beforeArrangedSubview: view)
            spacer.tl.bindVisible(to: view)

        case let .spaceAfter(view, space):
            guard let view = view else { return }
            let spacer = StackableSpacer()
            spacer.setContentHuggingPriority(.required, for: stackView.axis)
            NSLayoutConstraint.activate([
                spacer.dimension(along: stackView.axis).constraint(equalToConstant: space),
            ])
            stackView.tl.insertArrangedSubview(spacer, afterArrangedSubview: view)
            spacer.tl.bindVisible(to: view)

        case let .spaceBetween(view1, view2, space):
            guard let view1 = view1, let view2 = view2 else { return }
            let spacer = StackableSpacer()
            spacer.setContentHuggingPriority(.required, for: stackView.axis)
            NSLayoutConstraint.activate([
                spacer.dimension(along: stackView.axis).constraint(equalToConstant: space),
            ])
            stackView.tl.insertArrangedSubview(spacer, afterArrangedSubview: view1)
            spacer.tl.bindVisible(toAllVisible: [view1, view2])

        case let .spaceAfterGroup(views, space):
            let spacer = StackableSpacer()
            spacer.setContentHuggingPriority(.required, for: stackView.axis)
            NSLayoutConstraint.activate([
                spacer.dimension(along: stackView.axis).constraint(equalToConstant: space),
            ])
            if let view = views.last {
                stackView.tl.insertArrangedSubview(spacer, afterArrangedSubview: view)
            }
            spacer.tl.bindVisible(toAnyVisible: views)

        case let .flexibleSpace(.atLeast(space)):
            let spacer = StackableSpacer()
            spacer.setContentHuggingPriority(.defaultLow, for: stackView.axis)
            NSLayoutConstraint.activate([
                spacer.dimension(along: stackView.axis).constraint(greaterThanOrEqualToConstant: space),
            ])
            stackView.addArrangedSubview(spacer)

        case let .flexibleSpace(.range(range)):
            let spacer = StackableSpacer()
            spacer.setContentHuggingPriority(.defaultLow, for: stackView.axis)
            let anchor = spacer.dimension(along: stackView.axis)
            NSLayoutConstraint.activate([
                anchor.constraint(lessThanOrEqualToConstant: range.upperBound),
                anchor.constraint(greaterThanOrEqualToConstant: range.lowerBound),
            ])
            stackView.addArrangedSubview(spacer)

        case let .flexibleSpace(.atMost(space)):
            let spacer = StackableSpacer()
            spacer.setContentHuggingPriority(.defaultLow, for: stackView.axis)
            NSLayoutConstraint.activate([
                spacer.dimension(along: stackView.axis).constraint(lessThanOrEqualToConstant: space),
            ])
            stackView.addArrangedSubview(spacer)
        }
    }
}

/// A simple, transparent view representing spacing.
internal class StackableSpacer: UIView {

    init() {
        super.init(frame: .zero)
        accessibilityIdentifier = UIStackView.tl.axID.space
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
