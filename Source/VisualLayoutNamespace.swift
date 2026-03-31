//
//  VisualLayoutNamespace.swift
//  ZDTinyLayout
//
//  Created by Zero.D.Saber on 2026/3/31.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

// MARK: - tl namespace

/// Namespace proxy for visual layout APIs.
public struct VisualLayoutNamespace<Base> {
	internal let base: Base
	internal init(base: Base) {
		self.base = base
	}
}

/// Marker protocol for `tl` namespace support.
public protocol VisualLayoutNamespaceCompatible: AnyObject {}

extension VisualLayoutView: VisualLayoutNamespaceCompatible {}

public extension VisualLayoutNamespaceCompatible where Self: VisualLayoutView {
	/// Namespace for Visual Layout DSL APIs.
	var tl: VisualLayoutNamespace<Self> {
		VisualLayoutNamespace(base: self)
	}
}
