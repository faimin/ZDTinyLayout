//
//  ZDTLAttachable.swift
//  ZDTinyLayout
//
//  Adapted from Stackable (https://github.com/rightpoint/Stackable)
//  Copyright 2020 Rightpoint and other contributors
//

import Foundation

/// `Attachable` forces some object to hold a strong reference to another object.
/// Useful for attaching KVO observations to views so that observations die alongside the view.
@MainActor
protocol Attachable {
    func attach(to child: AnyObject)
    func detatch(from child: AnyObject)
}

@MainActor private var strongKey: Void?
@MainActor private var weakKey: Void?

extension Attachable where Self: NSObject {

    func attach(to child: AnyObject) {
        addStrongReference(from: child, to: self)
        addWeakReference(from: self, to: child)
    }

    func detatch(from child: AnyObject) {
        strongReferences(from: child)?.remove(self)
        weakReferences(from: self)?.remove(child)
    }

    var attached: [AnyObject] {
        return (weakReferences(from: self) as NSHashTable<AnyObject>?)?.allObjects ?? []
    }

    private func strongReferences(from object: AnyObject) -> NSMutableArray? {
        return objc_getAssociatedObject(object, &strongKey) as? NSMutableArray
    }

    private func weakReferences(from object: AnyObject) -> NSHashTable<AnyObject>? {
        return objc_getAssociatedObject(object, &weakKey) as? NSHashTable<AnyObject>
    }

    private func addStrongReference(from source: AnyObject, to destination: AnyObject) {
        let attached = strongReferences(from: source) ?? {
            let array = NSMutableArray()
            objc_setAssociatedObject(source, &strongKey, array, .OBJC_ASSOCIATION_RETAIN)
            return array
        }()
        attached.add(destination)
    }

    private func addWeakReference(from source: AnyObject, to destination: AnyObject) {
        let attached = weakReferences(from: source) ?? {
            let table = NSHashTable<AnyObject>.weakObjects()
            objc_setAssociatedObject(source, &weakKey, table, .OBJC_ASSOCIATION_RETAIN)
            return table
        }()
        attached.add(destination)
    }
}
