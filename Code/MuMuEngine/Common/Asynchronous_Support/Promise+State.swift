//
//  Promise+State.swift
//  PromisePlayground
//
//  Created by Nicolás Miari on 2020/04/12.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Adapted form: https://github.com/malcommac/Hydra/blob/master/Sources/Hydra/Promise%2BState.swift
 */
extension Promise {

    internal indirect enum State {
        case pending
        case resolved(_: Value)
        case rejected(_: Error)

        var value: Value? {
            guard case .resolved(let value) = self else {
                return nil
            }
            return value
        }

        var error: Error? {
            guard case .rejected(let error) = self else {
                return nil
            }
            return error
        }

        var isPending: Bool {
            guard case .pending = self else {
                return false
            }
            return true
        }
    }
}
