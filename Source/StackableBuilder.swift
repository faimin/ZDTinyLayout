//
//  StackableBuilder.swift
//  ZDTinyLayout
//
//  Adapted from Stackable (https://github.com/rightpoint/Stackable)
//  Copyright 2020 Rightpoint and other contributors
//

#if !os(macOS)

/// Result builder for `Stackable` items used by `UIStackView.tl.add { ... }`.
@resultBuilder
public struct StackableBuilder {
    // MARK: Nested Types
    
    public typealias Expression = any Stackable
    public typealias Component = [Expression]

    // MARK: Static Functions

    public static func buildExpression(_ expression: Expression) -> Component {
        [expression]
    }
    
    /*
    public static func buildExpression(_ expression: Expression?) -> Component {
        guard let expression else {
            return []
        }
        return [expression]
    }
     */

    /// if
    public static func buildOptional(_ component: Component?) -> Component {
        guard let component = component else {
            return []
        }
        return component
    }

    /// if-else / switch
    public static func buildEither(first component: Component) -> Component {
        component
    }

    /// if-else / switch
    public static func buildEither(second component: Component) -> Component {
        component
    }

    /// #if avaliable
    public static func buildLimitedAvailability(_ component: Component) -> Component {
        component
    }

    /// for-in
    public static func buildArray(_ components: [Component]) -> Component {
        components.flatMap { $0 }
    }

    /// 在`if`方法块中属于部分结果，也会执行buildBlock
    public static func buildBlock(_ components: Component...) -> Component {
        components.flatMap { $0 }
    }

    public static func buildPartialBlock(first: Component) -> Component {
        first
    }

    public static func buildPartialBlock(
        accumulated: Component,
        next: Component
    ) -> Component {
        accumulated + next
    }

}

#endif
