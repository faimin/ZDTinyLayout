//
//  Stackable+Alignment.swift
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

#if !os(macOS)

// MARK: - StackableViewItem

/// Carries information about how to build a source view and any manipulations needed
/// before adding it to a stack view.
@MainActor
public struct StackableViewItem {

    internal let makeView: (UIStackView) -> UIView
    internal var alignment: StackableAlignment = []
    internal var inset: UIEdgeInsets = .zero
    internal var outsetAncestor: UIView?
    internal var marginsAncestor: UIView?
}

// MARK: - Public API: Alignment transforms on StackableView

public extension StackableView {

    func aligned(_ alignment: StackableAlignment) -> StackableViewItem {
        if var item = self as? StackableViewItem {
            item.alignment = alignment
            return item
        }
        return StackableViewItem(
            makeView: makeStackableView(for:),
            alignment: alignment
        )
    }

    func inset(by margins: UIEdgeInsets) -> StackableViewItem {
        if var item = self as? StackableViewItem {
            item.inset = margins
            return item
        }
        return StackableViewItem(
            makeView: makeStackableView(for:),
            inset: margins
        )
    }

    func outset(to ancestor: UIView) -> StackableViewItem {
        if var item = self as? StackableViewItem {
            item.outsetAncestor = ancestor
            return item
        }
        return StackableViewItem(
            makeView: makeStackableView(for:),
            outsetAncestor: ancestor
        )
    }

    func margins(alignedWith ancestor: UIView) -> StackableViewItem {
        if var item = self as? StackableViewItem {
            item.marginsAncestor = ancestor
            return item
        }
        return StackableViewItem(
            makeView: makeStackableView(for:),
            marginsAncestor: ancestor
        )
    }
}

@MainActor
public extension Array where Element: StackableView {

    func aligned(_ alignment: StackableAlignment) -> [StackableViewItem] {
        return map { $0.aligned(alignment) }
    }

    func inset(by margins: UIEdgeInsets) -> [StackableViewItem] {
        return map { $0.inset(by: margins) }
    }

    func outset(to ancestor: UIView) -> [StackableViewItem] {
        return map { $0.outset(to: ancestor) }
    }

    func margins(alignedWith ancestor: UIView) -> [StackableViewItem] {
        return map { $0.margins(alignedWith: ancestor) }
    }
}

// MARK: - StackableViewItem: StackableView conformance

extension StackableViewItem: StackableView {

    public func makeStackableView(for stackView: UIStackView) -> UIView {
        let view = makeView(stackView)
        if alignment.isEmpty && inset == .zero {
            return view
        }
        return AlignmentView(view, alignment: alignment, inset: inset)
    }

    public func configure(stackView: UIStackView) {
        let source = makeStackableView(for: stackView)

        let wrapped = outsetIfNecessary(
            view: source,
            outsetAncestor: outsetAncestor,
            inset: .zero,
            stackView: stackView
        ).makeStackableView(for: stackView)

        stackView.addArrangedSubview(wrapped)

        applyOutsetConstraint(view: source, outsetAncestor: outsetAncestor, stackView: stackView)
        applyMarginsObservation(view: source, marginsAncestor: marginsAncestor, stackView: stackView)
    }
}

// MARK: - Internal helpers

internal extension Stackable {

    func outsetIfNecessary(view: UIView, outsetAncestor: UIView?, inset: UIEdgeInsets, stackView: UIStackView) -> StackableView {
        if outsetAncestor == nil, inset == .zero { return view }

        switch stackView.axis {
        case .horizontal:
            var wrapper = view.inset(by: inset)
            if outsetAncestor != nil {
                wrapper = wrapper.aligned(.flexVertical)
            }
            return wrapper

        case .vertical:
            var wrapper = view.inset(by: inset)
            if outsetAncestor != nil {
                wrapper = wrapper.aligned(.flexHorizontal)
            }
            return wrapper

        @unknown default:
            debugPrint("Unsupported stackView axis: \(stackView.axis)")
            return view
        }
    }

    func applyOutsetConstraint(view: UIView, outsetAncestor: UIView?, stackView: UIStackView) {
        guard let ancestor = outsetAncestor else { return }
        switch stackView.axis {
        case .horizontal:
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: ancestor.topAnchor),
                view.bottomAnchor.constraint(equalTo: ancestor.bottomAnchor),
            ])
        case .vertical:
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: ancestor.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: ancestor.trailingAnchor),
            ])
        @unknown default:
            debugPrint("Unsupported stackView axis: \(stackView.axis)")
        }
    }

    func applyMarginsObservation(view: UIView, marginsAncestor: UIView?, stackView: UIStackView) {
        guard let ancestor = marginsAncestor else { return }
        if let alignment = view as? AlignmentView, let subview = alignment.subviews.first {
            applyMarginsObservation(view: subview, marginsAncestor: marginsAncestor, stackView: stackView)
            return
        }

        let observation = ancestor.publisher(for: \.frame, options: [.initial, .new])
            .sink { [weak view, weak stackView, weak ancestor] _ in
                MainActor.assumeIsolated {
                    guard let view = view,
                          let stackView = stackView,
                          let ancestor = ancestor
                    else { return }

                    let bounds = view.bounds
                    let ancestorBounds = view.convert(ancestor.bounds, to: view)

                    switch stackView.axis {
                    case .horizontal:
                        let top = (ancestorBounds.minY - bounds.minY) + ancestor.layoutMargins.top
                        let bottom = (bounds.maxY - ancestorBounds.maxY) + ancestor.layoutMargins.bottom
                        view.layoutMargins.top = top
                        view.layoutMargins.bottom = bottom

                    case .vertical:
                        let left = (ancestorBounds.minX - bounds.minX) + ancestor.layoutMargins.left
                        let right = (bounds.maxX - ancestorBounds.maxX) + ancestor.layoutMargins.right
                        view.layoutMargins.left = left
                        view.layoutMargins.right = right

                    @unknown default:
                        debugPrint("Unsupported stackView axis: \(stackView.axis)")
                    }
                }
            }
        observation.attach(to: view)
    }
}

#endif
