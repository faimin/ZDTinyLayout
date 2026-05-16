//
//  ZDTLView+BindVisible.swift
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

// MARK: - Bind Visible (private)

extension NSKeyValueObservation: Attachable {}

private extension VisualLayoutView {

    func bindVisible(to view: VisualLayoutView) {
        let isHiddenObservation = view.observe(\.isHidden, options: .initial) { [weak self] view, _ in
            self?.isHidden = view.isHidden
        }
        isHiddenObservation.attach(to: self)
    }

    func bindVisible(toAllVisible views: [VisualLayoutView]) {
        views.forEach { view in
            let isHiddenObservation = view.observe(\.isHidden, options: .initial) { [weak self] _, _ in
                self?.isHidden = views.contains { $0.isHidden }
            }
            isHiddenObservation.attach(to: self)
        }
    }

    func bindVisible(toAnyVisible views: [VisualLayoutView]) {
        views.forEach { view in
            let isHiddenObservation = view.observe(\.isHidden, options: .initial) { [weak self] _, _ in
                self?.isHidden = views.allSatisfy { $0.isHidden }
            }
            isHiddenObservation.attach(to: self)
        }
    }
}

// MARK: - tl namespace: Bind Visible

public extension ZDTinyLayoutNamespace where Base: VisualLayoutView {

    func bindVisible(to view: VisualLayoutView) {
        base.bindVisible(to: view)
    }

    func bindVisible(toAllVisible views: [VisualLayoutView]) {
        base.bindVisible(toAllVisible: views)
    }

    func bindVisible(toAnyVisible views: [VisualLayoutView]) {
        base.bindVisible(toAnyVisible: views)
    }
}
