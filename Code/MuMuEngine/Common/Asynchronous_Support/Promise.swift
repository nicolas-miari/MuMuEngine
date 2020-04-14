//
//  Promise.swift
//  PromisePlayground
//
//  Created by Nicolás Miari on 2020/04/12.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Adapted form: https://github.com/malcommac/Hydra/blob/master/Sources/Hydra/Promise.swift
 Also read: https://medium.com/@danielemargutti/hydra-promises-swift-c6319f6a6209 by the author.
 */
public class Promise<Value> {

    // MARK: - PUBLIC INTERFACE

    // MARK: Common Block Signatures

    public typealias ResolveHandler = ((Value) -> ())
    public typealias RejectHandler = ((Error) -> ())
    public typealias Body = ((@escaping ResolveHandler, @escaping RejectHandler) throws -> Void)

    // MARK: Properties

    public var name: String?

    public var result: Value? {
        return stateQueue.sync {
            return self.state.value
        }
    }

    public var error: Error? {
        return stateQueue.sync {
            return self.state.error
        }
    }

    public var isPending: Bool {
        return stateQueue.sync {
            return self.state.isPending
        }
    }

    // MARK: Initialization

    public init() {
        self.state = .pending
        self.bodyCalled = true
    }

    public init(resolvedTo value: Value) {
        self.state = .resolved(value)
        self.bodyCalled = true
    }

    public init(rejected error: Error) {
        self.state = .rejected(error)
        self.bodyCalled = true
    }

    public init(in context: Context = .background, body: @escaping Body) {
        self.state = .pending
        self.context = context
        self.body = body
    }

    deinit {
        stateQueue.sync {
            self.observers.removeAll()
        }
    }

    // MARK: Operation

    public func resolve(_ value: Value) {
        set(state: .resolved(value))
    }

    public func reject(_ error: Error) {
        set(state: .rejected(error))
    }

    // MARK: - INTERNAL SUPPORT

    internal var state: State = .pending
    internal let stateQueue = DispatchQueue(label: "com.nicolasmiari.promise")

    private var body: Body?
    internal var bodyCalled: Bool = false

    private var isBodyExecuted: Bool {
        return stateQueue.sync {
            return self.bodyCalled
        }
    }

    private(set) var context: Context = .background

    private var observers: [Observer] = []

    private func set(state newState: State) {
        self.stateQueue.sync {
            guard self.state.isPending else {
                return
            }
            self.state = newState
            self.observers.forEach { (observer) in
                observer.call(newState)
            }
            self.observers.removeAll()
        }
    }

    internal func add(in context: Context = .background, onResolve: @escaping ResolveHandler, onReject: @escaping RejectHandler){
        /*
         Wrap each state's handler together with the (shared) context in an
         appropriate Observer case, and add them to the list:
         */
        let onResolveObserver = Observer.onResolve(context, onResolve)
        let onRejectObserver = Observer.onReject(context, onReject)

        /*
         (if self.state is already settled, the observer's handlers are executed
         immediately and not stored).
         */
        self.add(observers: [onResolveObserver, onRejectObserver])
    }

    internal func add(observers newObservers: [Observer]) {
        newObservers.forEach {
            self.observers.append($0)
        }
        if self.state.isPending {
            return
        }
        self.observers.forEach {
            $0.call(self.state)
        }
        self.observers.removeAll()
    }

    internal func runBody() {
        self.stateQueue.sync {
            guard state.isPending && !bodyCalled else {
                return
            }
            self.bodyCalled = true

            context.queue.async {
                do {
                    try self.body?( { value in
                        self.set(state: .resolved(value))
                    }, { error in
                        self.set(state: .rejected(error))
                    })
                } catch {
                    self.set(state: .rejected(error))
                }
            }
        }
    }

    internal func resetState() {
        self.stateQueue.sync {
            self.bodyCalled = false
            self.state = .pending
        }
    }
}
