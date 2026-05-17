//
//  View+BindVisible.swift
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

private extension View {

    func bindVisible(to view: View) {
        let isHiddenObservation = view.observe(\.isHidden, options: .initial) { [weak self] view, _ in
            self?.isHidden = view.isHidden
        }
        isHiddenObservation.attach(to: self)
    }

    func bindVisible(toAllVisible views: [View]) {
        views.forEach { view in
            let isHiddenObservation = view.observe(\.isHidden, options: .initial) { [weak self] _, _ in
                self?.isHidden = views.contains { $0.isHidden }
            }
            isHiddenObservation.attach(to: self)
        }
    }

    func bindVisible(toAnyVisible views: [View]) {
        views.forEach { view in
            let isHiddenObservation = view.observe(\.isHidden, options: .initial) { [weak self] _, _ in
                self?.isHidden = views.allSatisfy { $0.isHidden }
            }
            isHiddenObservation.attach(to: self)
        }
    }
}

// MARK: - tl namespace: Bind Visible

public extension ZDTinyLayoutNamespace where Base: View {

    func bindVisible(to view: View) {
        base.bindVisible(to: view)
    }

    func bindVisible(toAllVisible views: [View]) {
        base.bindVisible(toAllVisible: views)
    }

    func bindVisible(toAnyVisible views: [View]) {
        base.bindVisible(toAnyVisible: views)
    }
}
