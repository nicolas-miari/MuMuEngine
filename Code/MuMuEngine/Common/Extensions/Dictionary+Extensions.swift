//
//  Dictionary+Extensions.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/31.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import Foundation

extension Dictionary {
    /**
     Similar to the `mapValues()` method introduced in Swift 4, but allows for a
     failable mappin gof the values (i.e., return `nil` from the closure) much
     like `compactMap()` does with e.g. arrays.

     Source code taken from the proposal:
     https://github.com/apple/swift-evolution/blob/master/proposals/0218-introduce-compact-map-values.md

     (should be added to the library soon...?)

     - todo: remove once confirmed it has been introduced to the standard library (Swift 5?)
     */
    /*
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
        return try self.reduce(into: [Key: T](), { (result, x) in
            if let value = try transform(x.value) {
                result[x.key] = value
            }
        })
    }*/
}
