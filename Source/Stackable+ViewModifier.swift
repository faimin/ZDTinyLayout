//
//  Stackable+ViewModifier.swift
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

// MARK: - UIStackView modifiers

#if !os(macOS)
public extension ZDTinyLayoutNamespace where Base: UIStackView {
    @discardableResult
    func axis(_ axis: NSLayoutConstraint.Axis) -> Self {
        base.axis = axis
        return self
    }

    @discardableResult
    func distribution(_ distribution: UIStackView.Distribution) -> Self {
        base.distribution = distribution
        return self
    }

    @discardableResult
    func alignment(_ alignment: UIStackView.Alignment) -> Self {
        base.alignment = alignment
        return self
    }

    @discardableResult
    func spacing(_ spacing: CGFloat) -> Self {
        base.spacing = spacing
        return self
    }
}
#endif

// MARK: - View modifiers

public extension ZDTinyLayoutNamespace where Base: VisualLayoutView {
    @discardableResult
    func width(_ w: CGFloat) -> Self {
        base.translatesAutoresizingMaskIntoConstraints = false
        base.widthAnchor.constraint(equalToConstant: w).isActive = true
        return self
    }

    @discardableResult
    func height(_ h: CGFloat) -> Self {
        base.translatesAutoresizingMaskIntoConstraints = false
        base.heightAnchor.constraint(equalToConstant: h).isActive = true
        return self
    }

    @discardableResult
    func width(_ w: CGFloat) -> Base {
        let _: Self = width(w)
        return base
    }

    @discardableResult
    func height(_ h: CGFloat) -> Base {
        let _: Self = height(h)
        return base
    }

    @discardableResult
    func size(_ s: CGSize) -> Self {
        let _: Self = width(s.width)
        let _: Self = height(s.height)
        return self
    }

    @discardableResult
    func size(_ s: CGSize) -> Base {
        let _: Self = size(s)
        return base
    }

    @discardableResult
    func size(_ wh: CGFloat) -> Self {
        let _: Self = width(wh)
        let _: Self = height(wh)
        return self
    }

    @discardableResult
    func size(_ wh: CGFloat) -> Base {
        let _: Self = size(wh)
        return base
    }
}
