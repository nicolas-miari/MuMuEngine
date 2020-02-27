//
//  StateMachineComponent.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/16.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 - todo: Add unit tests for uncovered code paths.
 */
class StateMachineComponent: Component {

    static let name: String = "StateMachine"

    let states: [String: State]

    let initalState: String

    var currentState: State?

    weak var owner: Node!

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case states
        case initialState
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            self.states = try container.decode([String: State].self, forKey: .states)
        } catch {
            throw error
        }
        self.initalState = try container.decode(String.self, forKey: .initialState)

        guard let currentState = states[initalState] else {
            throw RuntimeError.componentIsCorrupted(nodeName: "")
        }
        self.currentState = currentState
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(states, forKey: .states)
        try container.encode(initalState, forKey: .initialState)
    }

    // MARK: - Initialization

    init(copying machine: StateMachineComponent) throws {
        
        // Make fresh copies of the states (they keep internal state, duh!)
        var copiedStates = [String: State]()
        for (key, value) in machine.states {
            copiedStates[key] = try State(copying: value)
        }
        self.states = copiedStates
        self.initalState = machine.initalState
        self.currentState = copiedStates[machine.initalState]
    }

    // MARK: - Configuration

    func setOwner(_ owner: Node) {
        self.owner = owner
    }

    // MARK: - Component

    func update(dt: TimeInterval) {
        guard let currentState = currentState else {
            return
        }

        let oldLoopCount = currentState.animationLoopsCompleted
        currentState.update(dt: dt)
        let newLoopCount = currentState.animationLoopsCompleted

        owner.meshComponent = currentState.renderable?.mesh as? TexturedMeshComponent

        if newLoopCount != oldLoopCount {
            // State animation has just completed a loop.

            guard let completeHandlers = currentState.eventHandlersByType[AnimationCompleteEvent.name] else {
                return
            }
            let filtered = completeHandlers.filter { (eventHandler) -> Bool in
                return (eventHandler.event as? AnimationCompleteEvent)?.count == newLoopCount
            }
            let actions = filtered.map { $0.action }

            performActions(actions)
        }
    }

    func performActions(_ actions: [Action]) {

        actions.forEach { (action) in
            switch action {
            case let stateTransition as StateTransitionAction:
                guard let newState = states[stateTransition.destination] else {
                    break
                }
                self.currentState = newState

            case let sceneTransition as SceneTransitionAction:
                let sceneName = sceneTransition.destination
                let effect = sceneTransition.effect ?? Runtime.shared.defaultTransitionEffect
                let duration = sceneTransition.duration ?? Runtime.shared.defaultTransitionDuration

                Runtime.shared.loadScene(name: sceneName, onCompletion: .runAfterTransition(effect: effect, duration: duration), failure: { (error) in
                    systemAlert(title: "Error", message: error.localizedDescription)
                })

            case is RemoveNodeAction:
                owner.removeFromParent()

            default:
                break
            }
        }
    }

    func handlePointInput(_ input: PointInput) {
        guard let currentState = currentState else {
            return
        }
        guard let inputHandlers = currentState.eventHandlersByType[PointInputEvent.name] else {
            return
        }
        let actions = inputHandlers.filter { (handler) -> Bool in
            return (handler.event as? PointInputEvent)?.pointInput == input
        }.map { (handler) -> Action in
            return handler.action
        }

        performActions(actions)
    }

    func copy() throws -> Component {
        return try StateMachineComponent(copying: self)
    }
}
