//
//  Promise+Catch.swift
//  PromisePlayground
//
//  Created by Nicolás Miari on 2020/04/12.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
Adapted form: https://github.com/malcommac/Hydra/blob/master/Sources/Hydra/Promise%2BCatch.swift
*/
public extension Promise {

    @discardableResult func `catch`(in context: Context = .main, body: @escaping ((Error) throws -> Void)) -> Promise<Void> {
        let nextPromise = Promise<Void>(in: context) { (resolve, reject) in
            let onResolveObserver = Observer.onResolve(context) { (_) in
                resolve(())
            }
            let onRejectObserver = Observer.onReject(context) { (error) in
                do {
                    try body(error)
                } catch {
                    reject(error)
                }
                resolve(())
            }

            self.add(observers: [onResolveObserver, onRejectObserver])
        }
        nextPromise.runBody()
        self.runBody()

        return nextPromise
    }
}
