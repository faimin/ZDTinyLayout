//
//  ZDTLAlignmentView.swift
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

// MARK: - ZDTLStackableAlignment

/// Options to specify how a view adjusts its content when its size is different than its intrinsic value.
public struct ZDTLStackableAlignment: OptionSet, Sendable {
    public let rawValue: Int
    public static let leading          = ZDTLStackableAlignment(rawValue: 1 << 0)
    public static let left             = ZDTLStackableAlignment(rawValue: 1 << 1)
    public static let centerX          = ZDTLStackableAlignment(rawValue: 1 << 2)
    public static let right            = ZDTLStackableAlignment(rawValue: 1 << 3)
    public static let trailing         = ZDTLStackableAlignment(rawValue: 1 << 4)
    public static let fillHorizontal   = ZDTLStackableAlignment(rawValue: 1 << 5)
    public static let flexHorizontal   = ZDTLStackableAlignment(rawValue: 1 << 6)

    public static let top              = ZDTLStackableAlignment(rawValue: 1 << 7)
    public static let centerY          = ZDTLStackableAlignment(rawValue: 1 << 8)
    public static let bottom           = ZDTLStackableAlignment(rawValue: 1 << 9)
    public static let fillVertical     = ZDTLStackableAlignment(rawValue: 1 << 10)
    public static let flexVertical     = ZDTLStackableAlignment(rawValue: 1 << 11)

    public static let center: ZDTLStackableAlignment = [.centerX, .centerY]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    fileprivate static let Horizontal: ZDTLStackableAlignment = [.leading, .left, .centerX, .right, .trailing, .fillHorizontal, .flexHorizontal]
    fileprivate static let Vertical: ZDTLStackableAlignment = [.top, .centerY, .bottom, .fillVertical, .flexVertical]
}

#if !os(macOS)

// MARK: - ZDTLAlignmentView

/// View wrapper that lets you specify internal alignment.
internal final class ZDTLAlignmentView: UIView {

    required init(_ wrapped: UIView, alignment: ZDTLStackableAlignment, inset: UIEdgeInsets = .zero) {
        super.init(frame: .zero)
        layoutMargins = inset

        addSubview(wrapped)

        var alignment = alignment
        if alignment.isDisjoint(with: ZDTLStackableAlignment.Horizontal) {
            alignment.formUnion(.fillHorizontal)
        }
        if alignment.isDisjoint(with: ZDTLStackableAlignment.Vertical) {
            alignment.formUnion(.fillVertical)
        }

        if alignment.contains(.leading) { wrapped.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true }
        if alignment.contains(.left) { wrapped.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor).isActive = true }
        if alignment.contains(.centerX) { wrapped.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true }
        if alignment.contains(.right) { wrapped.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor).isActive = true }
        if alignment.contains(.trailing) { wrapped.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true }
        if alignment.contains(.fillHorizontal) {
            wrapped.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
            wrapped.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        }

        if alignment.contains(.top) { wrapped.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true }
        if alignment.contains(.centerY) { wrapped.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor).isActive = true }
        if alignment.contains(.bottom) { wrapped.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true }
        if alignment.contains(.fillVertical) {
            wrapped.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
            wrapped.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        }

        translatesAutoresizingMaskIntoConstraints = false
        wrapped.translatesAutoresizingMaskIntoConstraints = false

        if !alignment.contains(.flexHorizontal) {
            NSLayoutConstraint.activate([
                wrapped.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
                wrapped.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            ])
        }
        if !alignment.contains(.flexVertical) {
            NSLayoutConstraint.activate([
                wrapped.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                wrapped.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
            ])
        }

        self.tl.bindVisible(to: wrapped)
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
