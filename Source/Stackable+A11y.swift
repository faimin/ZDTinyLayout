//
//  Stackable+A11y.swift
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

public enum StackableAccessibilityID {
    public static let space = "com.rightpoint.stackable.space"
    public static let hairline = "com.rightpoint.stackable.hairline"

    public typealias debug = DebugAccessibilityID
}

public enum DebugAccessibilityID {
    public static let outline = "com.rightpoint.stackable.debug.outline"
    public static let space = "com.rightpoint.stackable.debug.space"
    public static let margin = "com.rightpoint.stackable.debug.margin"
}

#if !os(macOS)
public extension ZDTinyLayoutNamespace where Base: UIStackView {
    typealias axID = StackableAccessibilityID
}
#endif
