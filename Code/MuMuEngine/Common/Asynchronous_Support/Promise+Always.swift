//
//  Promise+Always.swift
//  PromisePlayground
//
//  Created by Nicolás Miari on 2020/04/12.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
  Adapted form: https://github.com/malcommac/Hydra/blob/master/Sources/Hydra/Promise%2BAlways.swift
 */
public extension Promise {

    /**
     Always run given body at the end of a promise chain regardless of the
     whether the chain resolves or rejects.

     - Parameters:
       - context: A context in which the body is executed (if not specified,
       `background` is used)
       - body: A body to execute.
     - Returns: A promise.
     */
    @discardableResult
    func always(in context: Context = .background, body: @escaping () throws -> Void) -> Promise<Value> {
        let nextPromise = Promise<Value>(in: context) { resolve, reject in
            /*
             Always call body both for reject and resolve:
             */
            let onResolveObserver = Observer.onResolve(context, { value in
                do {
                    try body()
                    resolve(value)
                } catch let err {
                    reject(err)
                }
            })

            let onRejectObserver = Observer.onReject(context, { error in
                do {
                    try body()
                    reject(error)
                } catch let err {
                    reject(err)
                }
            })

            self.add(observers: [onResolveObserver, onRejectObserver])
        }
        nextPromise.runBody()
        self.runBody()

        return nextPromise
    }
}
