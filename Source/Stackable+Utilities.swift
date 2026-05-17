//
//  Stackable+Utilities.swift
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
extension ZDTinyLayoutNamespace where Base: UIStackView {

    /// Removes all arranged subviews from the stack view.
    public func removeAllArrangedSubviews() {
        base.arrangedSubviews.forEach {
            base.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    /// Locates `other` in `.arrangedSubviews` and inserts `view` before it.
    /// If `other` cannot be found, `view` is added at the next available index.
    public func insertArrangedSubview(_ view: UIView, beforeArrangedSubview other: UIView) {
        if let idx = base.arrangedSubviews.firstIndex(where: { other.isDescendant(of: $0) }) {
            base.insertArrangedSubview(view, at: idx)
        } else {
            base.addArrangedSubview(view)
        }
    }

    /// Locates `other` in `.arrangedSubviews` and inserts `view` after it.
    /// If `other` cannot be found, `view` is added at the next available index.
    public func insertArrangedSubview(_ view: UIView, afterArrangedSubview other: UIView) {
        if let idx = base.arrangedSubviews.firstIndex(where: { other.isDescendant(of: $0) })?.advanced(by: 1) {
            base.insertArrangedSubview(view, at: idx)
        } else {
            base.addArrangedSubview(view)
        }
    }
}
#endif
