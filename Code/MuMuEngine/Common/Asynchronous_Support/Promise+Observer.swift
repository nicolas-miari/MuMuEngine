//
//  Promise+Observer.swift
//  PromisePlayground
//
//  Created by Nicolás Miari on 2020/04/12.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Adapted form: https://github.com/malcommac/Hydra/blob/master/Sources/Hydra/Promise%2BObserver.swift
 */
extension Promise {

    indirect enum Observer {

        ///
        case onResolve(_: Context, _: ResolveHandler)

        ///
        case onReject(_: Context, _: RejectHandler)

        /**
         */
        func call(_ state: State) {
            switch (self, state) {
            case (.onResolve(let context, let handler), .resolved(let value)):
                context.queue.async {
                    handler(value)
                }
            case (.onReject(let context, let handler), .rejected(let error)):
                context.queue.async {
                    handler(error)
                }
            default:
                return // (this should never happen)
            }
        }
    }
}
