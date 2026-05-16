//
//  ZDTLStackable+Views.swift
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

// MARK: - ZDTLStackableView Conformance

#if !os(macOS)
extension UIView: ZDTLStackableView {
    public func makeStackableView(for stackView: UIStackView) -> UIView {
        return self
    }
}

extension UIViewController: ZDTLStackableView {
    public func makeStackableView(for stackView: UIStackView) -> UIView {
        return view
    }
}

extension NSAttributedString: ZDTLStackableView {
    public func makeStackableView(for stackView: UIStackView) -> UIView {
        let label = UILabel()
        label.setContentHuggingPriority(.required, for: stackView.axis)
        label.attributedText = self
        label.numberOfLines = 0
        return label
    }
}

extension String: ZDTLStackableView {
    public func makeStackableView(for stackView: UIStackView) -> UIView {
        return NSAttributedString(string: self).makeStackableView(for: stackView)
    }
}

extension UIImage: ZDTLStackableView {
    public func makeStackableView(for stackView: UIStackView) -> UIView {
        let imageView = UIImageView(image: self)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
}

extension UILayoutGuide: ZDTLStackableView {
    public func makeStackableView(for stackView: UIStackView) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addLayoutGuide(self)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        return view
    }
}

#endif
