//
//  StackUI.swift
//  ZDTinyLayout
//
//  Adapted from Stackable (https://github.com/rightpoint/Stackable)
//  Copyright 2020 Rightpoint and other contributors
//

#if os(macOS)
import Cocoa
#else
import UIKit

/// Convenience builders for creating and populating stack views with a SwiftUI-like syntax.
@MainActor
public struct StackUI {

    @discardableResult
    public static func VStack(
        distribution: UIStackView.Distribution = .fill,
        alignment: UIStackView.Alignment = .fill,
        spacing: CGFloat = 0,
        @StackableBuilder _ stackablesBlock: () -> [any Stackable]
    ) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = distribution
        stackView.alignment = alignment
        stackView.spacing = spacing

        stackView.tl.add(stackablesBlock())

        return stackView
    }

    @discardableResult
    public static func HStack(
        distribution: UIStackView.Distribution = .fill,
        alignment: UIStackView.Alignment = .fill,
        spacing: CGFloat = 0,
        @StackableBuilder _ stackablesBlock: () -> [any Stackable]
    ) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = distribution
        stackView.alignment = alignment
        stackView.spacing = spacing

        stackView.tl.add(stackablesBlock())

        return stackView
    }

    @discardableResult
    public static func Spacer(
        minWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil
    ) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)

        view.translatesAutoresizingMaskIntoConstraints = false

        if let minWidth, minWidth > 0.0 {
            view.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
        }
        if let minHeight, minHeight > 0.0 {
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
        }

        return view
    }
}
#endif
