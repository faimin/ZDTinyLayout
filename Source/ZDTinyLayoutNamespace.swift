//
//  ZDTinyLayoutNamespace.swift
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
public struct ZDTinyLayoutNamespace<Base> {
	internal let base: Base
	internal init(base: Base) {
		self.base = base
	}
}

/// Marker protocol for `tl` namespace support.
public protocol ZDTinyLayoutNamespaceCompatible: AnyObject {}

extension NSObject: ZDTinyLayoutNamespaceCompatible {}

public extension ZDTinyLayoutNamespaceCompatible {
	/// Namespace for Visual Layout DSL APIs.
	var tl: ZDTinyLayoutNamespace<Self> {
		ZDTinyLayoutNamespace(base: self)
	}
    
    /// Namespace type for constraint batch APIs.
    static var tl: ZDTinyLayoutNamespace<Self>.Type {
        ZDTinyLayoutNamespace<Self>.self
    }
}
