//
//  ZDTLStackableUtilities.swift
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

internal extension UIView {

    /// Get the dimension anchor of a view along the axis of a stack view.
    /// For example, fetches the `heightAnchor` for a `.vertical` axis.
    func dimension(along axis: NSLayoutConstraint.Axis) -> NSLayoutDimension {
        switch axis {
        case .vertical: return heightAnchor
        case .horizontal: return widthAnchor
        @unknown default: fatalError()
        }
    }
}

#endif
