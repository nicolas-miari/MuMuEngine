//
//  Component.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/03.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation
import CoreGraphics
import simd

public protocol Component: AnyObject, Codable, NamedType {

    /**
     A default implementation is provided that returns the value of the property `typeName` (required by the
     inherited `NamedType` protocol).
     */
    var name: String { get }

    /**
     A default implementation is provided that returns `false` only if both `component` and the receiver have
     the same `name`.
     */
    func isCompatible(with component: Component) -> Bool

    /**
     A default implementation is provided that does nothing.
     */
    func update(dt: TimeInterval)

    /**
     A default implementation is provided that produces a copy by successively enocoding and decoding the receiver.
     */
    func copy() throws -> Component
}

// MARK: - Default Implementations

extension Component {

    var name: String {
        return typeName
    }

    func isCompatible(with component: Component) -> Bool {
        // Default implementation always for up to one component of each type
        return (self.name != component.name)
    }

    func update(dt: TimeInterval) {
        // Default implementation does nothing.
    }

    func copy() throws -> Self {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
