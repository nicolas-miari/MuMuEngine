//
//  Context.swift
//  PromisePlayground
//
//  Created by Nicolás Miari on 2020/04/13.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Adapted from: https://github.com/malcommac/Hydra/blob/master/Sources/Hydra/Context.swift
 */
public enum Context {
    case main
    case userInteractive
    case userInitiated
    case utility
    case background
    case custom(queue: DispatchQueue)

    public var queue: DispatchQueue {
        switch self {
        case .main:
            return .main

        case .userInteractive:
            return .global(qos: .userInteractive)

        case .userInitiated:
            return .global(qos: .userInitiated)

        case .utility:
            return .global(qos: .utility)

        case .background:
            return .global(qos: .background)

        case .custom(let queue):
            return queue
        }
    }
}
