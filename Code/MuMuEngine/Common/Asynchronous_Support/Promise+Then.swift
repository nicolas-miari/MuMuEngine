//
//  Promise+Then.swift
//  PromisePlayground
//
//  Created by Nicolás Miari on 2020/04/12.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
Adapted form: https://github.com/malcommac/Hydra/blob/master/Sources/Hydra/Promise%2BThen.swift
*/
public extension Promise {

    /**
     This `then` variant allows to catch the resolved value of the promise and
     execute a block of code without returning anything.

     The passed body can also reject the next promise by throwing.

     Returned object is a promise which is able to dispatch both error or
     resolved value of the promise.

     - Parameters:
       - context: The context in which the body is executed (if not specified,
       `main` is used).
       - body: The code block to execute.
     - Returns: A chainable promise.
     */
    @discardableResult
    func then(in context: Context = .main, _ body: @escaping ((Value) throws -> Void)) -> Promise<Value> {
        /**
         At first glance, it took me a while to grasp howe chaining works (it's
         hard to "think in polrtals"); below is the best explanation I could
         come up with:

         The argument `body` contains the code inside the `.then {}` block on
         the calling side, to be executed in response to the the source
         promise's resolution.

         We achieve this by creating a **new promise** which executes _not_
         `body` itself, but instead registers **observers** for the source
         promise, and executes the code in `body` in response.

         Next, we execute the body of the _new_ promise, which results in the
         observers being registered, and finally run the body of the _source_
         premise, which results in the observers being notified (and thus -on
         success- `body` being finally executed, as expected).

         The returned next premise can too be chained onto (it resolves when
         `body` is finally executed, to the same value as soiurce promise in
         this case).
         */
        let nextPromise = Promise<Value>(in: context) { (resolve, reject) in
            let onResolveObserver = Observer.onResolve(context) { (value) in
                do {
                    /*
                     The source promise was resolved; attempt to execute the
                     requested body (passing the resolved value along):
                     */
                    try body(value)

                    /*
                     The try succeeded; resolve next promise too, with the same
                     value as source:
                     */
                    resolve(value)
                } catch {
                    /*
                     The try failed; reject next promise with the thrown error:
                     */
                    reject(error)
                }
            }

            /*
             Respond to the source promise rejecting by rejecting the next
             promise as well, with the very same error:
             */
            let onRejectObserver = Observer.onReject(context, reject)

            self.add(observers: [onResolveObserver, onRejectObserver])
        }
        /*
         Execute the body of nextPromise so we can register the observers to
         this promise and get back value/error once its resolved/rejected.
         */
        nextPromise.runBody()

        /*
         Run own body (only once). If this promise is the main one, it simply
         executes the core of the promise functions (?)
         */
        self.runBody()

        return nextPromise
    }

    /**
     This `then` allows to execute a block which return a value; this value is
     used to get a chainable Promise already resolved with that value.

     The executed body can also reject the whole chain by throwing.

     - Parameters:
       - context: The context in which the body is executed (if not specified,
     `main` is used).
       - body: The block to execute.
     - Returns: A chainable promise.
    */
    @discardableResult
    func then<N>(in context: Context = .main, _ body: @escaping ( (Value) throws -> N) ) -> Promise<N> {
        return self.then(in: context, { value in
            do {
                /*
                 Get the value from body (or throws) and create a resolved
                 Promise with that which is returned as output of the then as
                 chainable promise.
                 */
                let transformedValue = try body(value)
                return Promise<N>(resolvedTo: transformedValue)

            } catch let error {
                /*
                 If body throws, a promise in the rejected state (with the
                 catched error) is generated:
                 */
                return Promise<N>(rejected: error)
            }
        })
    }


    /**
     This `then` allows to execute a block of code which can transform the
     result of the promise in another promise.

     It's also possible to use it in order to send the output of a promise an
     input of another one and use it: `asyncFunc1().then(asyncFunc2).then...`

     Executed body can also reject the whole chain by throwing.

     - Parameters:
       - context: The context in which the body is executed (if not specified,
       `main` is used).
       - body: The body to execute.
     - Returns: A chainable promise.
     */
    @discardableResult
    func then<N>(in context: Context = .main, _ body: @escaping ( (Value) throws -> (Promise<N>) )) -> Promise<N> {
        let nextPromise = Promise<N>(in: context) { resolve, reject in
            /*
             Observe the resolve of the self promise
             */
            let onResolveObserver = Observer.onResolve(context, { value in
                do {
                    /*
                     Pass the value to the body and get back a new promise with
                     another value
                     */
                    let chainedPromise = try body(value)

                    /*
                     Execute the promise's body and get the result of it
                     */
                    let pResolve = Promise<N>.Observer.onResolve(context, resolve)
                    let pReject = Promise<N>.Observer.onReject(context, reject)
                    chainedPromise.add(observers: [pResolve, pReject])
                    chainedPromise.runBody()

                } catch let error {
                    reject(error)
                }
            })

            /*
             Observe the reject of the self promise
             */
            let onReject = Observer.onReject(context, reject)
            self.add(observers: [onResolveObserver, onReject])
        }
        nextPromise.runBody()
        self.runBody()
        return nextPromise
    }
}
