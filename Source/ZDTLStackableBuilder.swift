//
//  ZDTLStackableBuilder.swift
//  ZDTinyLayout
//
//  Adapted from Stackable (https://github.com/rightpoint/Stackable)
//  Copyright 2020 Rightpoint and other contributors
//

#if !os(macOS)

/// Result builder for `ZDTLStackable` items used by `UIStackView.tl.add { ... }`.
@resultBuilder
public struct ZDTLStackableBuilder {
    public typealias V = any ZDTLStackable

    public static func buildBlock(_ components: [V]...) -> [V] {
        components.flatMap { $0 }
    }

    public static func buildArray(_ components: [[V]]) -> [V] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [V]?) -> [V] {
        component ?? []
    }

    public static func buildEither(first component: [V]) -> [V] {
        component
    }

    public static func buildEither(second component: [V]) -> [V] {
        component
    }

    public static func buildExpression(_ expression: V) -> [V] {
        [expression]
    }

    public static func buildExpression(_ expression: V?) -> [V] {
        guard let expression = expression else { return [] }
        return [expression]
    }

    public static func buildLimitedAvailability(_ component: [V]) -> [V] {
        component
    }
}

#endif
