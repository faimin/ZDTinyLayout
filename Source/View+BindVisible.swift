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
import Combine

// MARK: - Bind Visible (private)

extension AnyCancellable: Attachable {}

private extension View {

    func bindVisible(to view: View) {
        let isHiddenObservation = view.publisher(for: \.isHidden, options: [.initial])
            .sink { [weak self] isHidden in
                MainActor.assumeIsolated {
                    self?.isHidden = isHidden
                }
            }
        isHiddenObservation.attach(to: self)
    }

    func bindVisible(toAllVisible views: [View]) {
        views.forEach { view in
            let isHiddenObservation = view.publisher(for: \.isHidden, options: [.initial])
                .sink { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.isHidden = views.contains { $0.isHidden }
                    }
                }
            isHiddenObservation.attach(to: self)
        }
    }

    func bindVisible(toAnyVisible views: [View]) {
        views.forEach { view in
            let isHiddenObservation = view.publisher(for: \.isHidden, options: [.initial])
                .sink { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.isHidden = views.allSatisfy { $0.isHidden }
                    }
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
