//
//  StackableTests.swift
//  ZDTinyLayoutTests
//
//  Adapted from Stackable (https://github.com/rightpoint/Stackable)
//  Copyright 2020 Rightpoint and other contributors
//

#if !os(macOS)
import Testing
import UIKit

@testable import ZDTinyLayout

// MARK: - Hairline Tests

@MainActor
struct HairlineTests {

    @Test("Global hairline color config applies to stack views without local overrides")
    func globalHairlineColor() {
        UIStackView.tl.hairlineColor = .blue
        let stack = UIStackView()
        stack.tl.add([
            UIStackView.tl.hairline,
        ])
        let hairline = stack.arrangedSubviews.first as? StackableHairlineView
        #expect(hairline?.backgroundColor == .blue)
        UIStackView.tl.hairlineColor = nil
    }

    @Test("Per-instance hairline color overrides global config")
    func instanceHairlineColor() {
        UIStackView.tl.hairlineColor = .blue
        let stack = UIStackView()
        UIStackView.tl.hairlineColor = .brown
        stack.tl.add([
            UIStackView.tl.hairline,
        ])
        let hairline = stack.arrangedSubviews.first as? StackableHairlineView
        #expect(hairline?.backgroundColor == .brown)
        UIStackView.tl.hairlineColor = nil
    }

    @Test("Per-hairline color beats instance and global config")
    func perHairlineColor() {
        UIStackView.tl.hairlineColor = .blue
        let stack = UIStackView()
        UIStackView.tl.hairlineColor = .brown
        stack.tl.add([
            UIStackView.tl.hairline,
            UIStackView.tl.hairline
                .color(.yellow),
        ])
        let first = stack.arrangedSubviews.first as? StackableHairlineView
        #expect(first?.backgroundColor == .brown)

        let last = stack.arrangedSubviews.last as? StackableHairlineView
        #expect(last?.backgroundColor == .yellow)
        UIStackView.tl.hairlineColor = nil
    }

    @Test("Per-hairline thickness overrides defaults")
    func hairlineThickness() {
        let stack = UIStackView()
        stack.tl.add([
            UIStackView.tl.hairline
                .thickness(3),
        ])
        let hairline = stack.arrangedSubviews.first
        #expect(hairline != nil)
        let thicknessConstraint = hairline?.constraints.first { $0.firstAttribute == .height || $0.firstAttribute == .width }
        #expect(thicknessConstraint?.constant == 3)
    }
}

// MARK: - Add Tests

@MainActor
struct AddTests {

    @Test("Adding string creates a label in the stack view")
    func addString() {
        let stack = UIStackView()
        stack.tl.add("Hello World")
        #expect(stack.arrangedSubviews.count == 1)
        #expect(stack.arrangedSubviews.first is UILabel)
    }

    @Test("Adding numeric literal creates spacing")
    func addSpacing() {
        let stack = UIStackView()
        stack.tl.add(20)
        #expect(stack.arrangedSubviews.count == 1)
    }

    @Test("Adding view directly works")
    func addView() {
        let stack = UIStackView()
        let view = UIView()
        stack.tl.add(view)
        #expect(stack.arrangedSubviews.first === view)
    }

    @Test("Adding array of items works")
    func addArray() {
        let stack = UIStackView()
        stack.tl.add([
            "Hello",
            10,
            UIView(),
            UIStackView.tl.hairline,
        ])
        #expect(stack.arrangedSubviews.count == 4)
    }

    @Test("Result builder add syntax works")
    func addBuilder() {
        let stack = UIStackView()
        stack.tl.add {
            "Hello"
            10
            UIView()
            UIStackView.tl.flexibleSpace
        }
        #expect(stack.arrangedSubviews.count == 4)
    }

    @Test("Optional stackable skips nil values")
    func addOptional() {
        let stack = UIStackView()
        let nilView: UIView? = nil
        let someView: UIView? = UIView()
        stack.tl.add {
            nilView
            someView
        }
        #expect(stack.arrangedSubviews.count == 1)
    }

    @Test("Conditional builder works")
    func addConditional() {
        let stack = UIStackView()
        let showExtra = true
        stack.tl.add {
            "Base"
            if showExtra {
                "Extra"
            }
        }
        #expect(stack.arrangedSubviews.count == 2)
    }
}

// MARK: - Spacing Tests

@MainActor
struct SpacingTests {

    @Test("Smart space tracks visibility of preceding view")
    func smartSpace() {
        let stack = UIStackView()
        let view = UIView()
        stack.tl.add {
            view
            20
        }
        #expect(stack.arrangedSubviews.count == 2)
    }

    @Test("Constant space always creates a spacer")
    func constantSpace() {
        let stack = UIStackView()
        stack.tl.add(UIStackView.tl.constantSpace(50))
        #expect(stack.arrangedSubviews.count == 1)
    }

    @Test("Flexible space creates low-hugging spacer")
    func flexibleSpace() {
        let stack = UIStackView()
        stack.tl.add(UIStackView.tl.flexibleSpace)
        #expect(stack.arrangedSubviews.count == 1)

        let spacer = stack.arrangedSubviews.first
        #expect(spacer?.contentHuggingPriority(for: stack.axis) == .defaultLow)
    }
}

// MARK: - StackUI Tests

@MainActor
struct StackUITests {

    @Test("VStack creates vertical stack view with items")
    func vStack() {
        let stack = StackUI.VStack(spacing: 8) {
            "Hello"
            10
            UIView()
        }
        #expect(stack.axis == .vertical)
        #expect(stack.spacing == 8)
        #expect(stack.arrangedSubviews.count == 3)
    }

    @Test("HStack creates horizontal stack view with items")
    func hStack() {
        let stack = StackUI.HStack(spacing: 4) {
            UIView()
            "World"
        }
        #expect(stack.axis == .horizontal)
        #expect(stack.spacing == 4)
        #expect(stack.arrangedSubviews.count == 2)
    }

    @Test("Spacer creates a flexible spacer view")
    func spacer() {
        let spacer = StackUI.Spacer(minWidth: 10, minHeight: 20)
        #expect(spacer.contentHuggingPriority(for: .horizontal) == .defaultLow)
        #expect(spacer.contentHuggingPriority(for: .vertical) == .defaultLow)
    }
}

// MARK: - Alignment Tests

@MainActor
struct AlignmentTests {

    @Test("Alignment modifier stores alignment value in StackableViewItem")
    func alignmentStored() {
        let view = UIView()
        let item = view.aligned(.centerX)
        // alignment is internal, verify through behavior: add to stack and check wrapper
        let stack = UIStackView()
        stack.tl.add(item)
        #expect(stack.arrangedSubviews.count == 1)
        // AlignmentView wraps non-trivial alignment
        #expect(stack.arrangedSubviews.first is AlignmentView)
    }

    @Test("Alignment .fillHorizontal results in a constrained subview")
    func alignmentFillHorizontal() {
        let view = UIView()
        let item = view.aligned(.fillHorizontal)
        let stack = UIStackView()
        stack.tl.add(item)
        let wrapper = stack.arrangedSubviews.first as? AlignmentView
        #expect(wrapper != nil)
        guard let wrapper else { return }
        let subview = wrapper.subviews.first
        #expect(subview === view)
        // Constraints exist: leading + trailing to layoutMarginsGuide
        let marginConstraints = wrapper.constraints.filter { $0.firstAttribute == .leading || $0.firstAttribute == .trailing }
        #expect(!marginConstraints.isEmpty)
    }

    @Test("Inset modifier creates insetted subview in stack")
    func insetApplied() {
        let view = UIView()
        let insets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        let item = view.inset(by: insets)
        let stack = UIStackView()
        stack.tl.add(item)
        #expect(stack.arrangedSubviews.count == 1)
        let wrapper = stack.arrangedSubviews.first as? AlignmentView
        #expect(wrapper != nil)
        guard let wrapper else { return }
        #expect(wrapper.layoutMargins.top == insets.top)
        #expect(wrapper.layoutMargins.left == insets.left)
        #expect(wrapper.layoutMargins.bottom == insets.bottom)
        #expect(wrapper.layoutMargins.right == insets.right)
    }

    @Test("Outset modifier sets ancestor reference")
    func outsetStored() {
        let view = UIView()
        let ancestor = UIView()
        let item = view.outset(to: ancestor)
        let stack = UIStackView()
        // Add ancestor and stack to a common hierarchy before adding item
        let container = UIView()
        container.addSubview(ancestor)
        container.addSubview(stack)
        stack.tl.add(item)
        #expect(stack.arrangedSubviews.count == 1)
    }

    @Test("Array alignment transforms produce correct count")
    func arrayAlignment() {
        let views: [UIView] = [UIView(), UIView(), UIView()]
        let items = views.aligned(.centerX)
        #expect(items.count == 3)
    }

    @Test("Array inset transforms produce correct count")
    func arrayInset() {
        let views: [UIView] = [UIView(), UIView()]
        let insets = UIEdgeInsets(top: 5, left: 10, bottom: 15, right: 20)
        let items = views.inset(by: insets)
        #expect(items.count == 2)
        let stack = UIStackView()
        stack.tl.add(items)
        #expect(stack.arrangedSubviews.count == 2)
        stack.arrangedSubviews.forEach { wrapper in
            #expect((wrapper as? AlignmentView)?.layoutMargins == insets)
        }
    }
}

// MARK: - ScrollingStackView Tests

@MainActor
struct ScrollingStackViewTests {

    @Test("ScrollingStackView has a vertical stack view")
    func defaultConfig() {
        let scrollView = ScrollingStackView()
        #expect(scrollView.stackView.axis == .vertical)
    }

    @Test("ScrollingStackView add methods work")
    func addToScrollingStack() {
        let scrollView = ScrollingStackView()
        scrollView.add("Hello")
        #expect(scrollView.stackView.arrangedSubviews.count == 1)
    }
}

// MARK: - Utilities Tests

@MainActor
struct UtilitiesTests {

    @Test("Remove all arranged subviews clears the stack")
    func removeAllArrangedSubviews() {
        let stack = UIStackView()
        stack.tl.add {
            "A"
            "B"
            "C"
        }
        #expect(stack.arrangedSubviews.count == 3)
        stack.tl.removeAllArrangedSubviews()
        #expect(stack.arrangedSubviews.isEmpty)
    }

    @Test("Insert before arranged subview positions correctly")
    func insertBefore() {
        let stack = UIStackView()
        let a = UIView()
        let b = UIView()
        stack.tl.add(a)
        stack.tl.insertArrangedSubview(b, beforeArrangedSubview: a)
        #expect(stack.arrangedSubviews.first === b)
    }

    @Test("Insert after arranged subview positions correctly")
    func insertAfter() {
        let stack = UIStackView()
        let a = UIView()
        let b = UIView()
        stack.tl.add(a)
        stack.tl.insertArrangedSubview(b, afterArrangedSubview: a)
        #expect(stack.arrangedSubviews.last === b)
    }
}

// MARK: - View Modifier Tests

@MainActor
struct ViewModifierTests {

    @Test("Width modifier sets width constraint on view")
    func width() {
        let view = UIView()
        let _: UIView = view.tl.width(100)
        let widthConstraint = view.constraints.first { $0.firstAttribute == .width }
        #expect(widthConstraint?.constant == 100)
    }

    @Test("Height modifier sets height constraint on view")
    func height() {
        let view = UIView()
        let _: UIView = view.tl.height(50)
        let heightConstraint = view.constraints.first { $0.firstAttribute == .height }
        #expect(heightConstraint?.constant == 50)
    }

    @Test("Size modifier sets both width and height")
    func size() {
        let view = UIView()
        let _: UIView = view.tl.size(CGSize(width: 100, height: 200))
        let widthConstraint = view.constraints.first { $0.firstAttribute == .width }
        let heightConstraint = view.constraints.first { $0.firstAttribute == .height }
        #expect(widthConstraint?.constant == 100)
        #expect(heightConstraint?.constant == 200)
    }

    @Test("Chain modifiers on stack view work")
    func chainStackViewModifiers() {
        let stack = UIStackView()
        stack.tl
            .axis(.vertical)
            .spacing(8)
            .distribution(.fillEqually)
        #expect(stack.axis == .vertical)
        #expect(stack.spacing == 8)
        #expect(stack.distribution == .fillEqually)
    }
}

// MARK: - BindVisible Tests

@MainActor
struct BindVisibleTests {

    @Test("Bind visible mirrors isHidden state")
    func bindVisibleToSingleView() {
        let source = UIView()
        let target = UIView()
        source.isHidden = false
        target.tl.bindVisible(to: source)
        // The KVO fires on initial subscription with .initial option
        // target should be visible since source starts visible
        #expect(target.isHidden == false)
    }

    @Test("Bind visible to all requires all views to be visible")
    func bindVisibleToAll() {
        let v1 = UIView()
        let v2 = UIView()
        let target = UIView()
        v1.isHidden = false
        v2.isHidden = false
        target.isHidden = false
        target.tl.bindVisible(toAllVisible: [v1, v2])
        #expect(target.isHidden == false)

        v1.isHidden = true
        #expect(target.isHidden == true)
    }
}

#endif
