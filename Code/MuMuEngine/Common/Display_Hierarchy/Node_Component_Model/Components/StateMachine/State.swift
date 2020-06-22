//
//  State.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/22.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

// MARK: - State

/**
 Represents a single, discrete state of a state machine.

 A state can optionally have one of a static sprite or an animation associated with it.
 While the parent state machine is in that state, the static sprite or animation is rendered on screen, with the
 transform of the node that owns the state machine applied to it (i.e., at the location of the node).
 */
class State: Codable {

    /**
     An optional object that encapsulates the static sprite or looping animation that is rendered while the
     state machine is in the state represented by the receiver.

     The renderable is transformed according to the node that owns the state machine.
     */
    var renderable: StateRenderable?

    /**
     Keyed by event name, for easy access. Dictionary of arrays, because there may be multiple handlers for each
     event type.
     */
    let eventHandlersByType: [String: [EventHandler]]

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case atlas
        case sprite
        case animation
        case eventHandlers
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let handlers = try container.decodeIfPresent([EventHandler].self, forKey: .eventHandlers) ?? []
            self.eventHandlersByType = Dictionary.init(grouping: handlers, by: { $0.event.typeName })

            let api = Runtime.shared.graphics

            if container.contains(.animation) {
                // RENDERS ANIMATION
                let animationName = try container.decode(String.self, forKey: .animation)
                let animation = try api.animation(name: animationName)
                let session = AnimationSession(source: animation)

                self.renderable = StateAnimation(animationSession: session)

            } else if container.contains(.atlas) && container.contains(.sprite) {
                // RENDERS STATIC SPRITE
                let spriteName = try container.decode(String.self, forKey: .sprite)
                let atlasName = try container.decode(String.self, forKey: .atlas)
                let sprite = try api.spriteComponent(name: spriteName, inAtlas: atlasName)

                self.renderable = StateSprite(mesh: sprite)

            } else {
                // RENDERS NOTHING (INVISIBLE STATE)
                self.renderable = nil
            }
            Swift.print("Successfully decoded State")
        } catch {
            throw error
        }

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let animation = renderable as? StateAnimation {
            let name = animation.animationSession.source.name
            try container.encode(name, forKey: .animation)

        } else if let _ = renderable as? StateSprite {
            // TODO: Implement
        } else {
            // (do nothing)
        }
    }

    // MARK: -

    init(copying state: State) throws {
        self.renderable = state.renderable // TODO: copy/reset animation
        self.eventHandlersByType = state.eventHandlersByType
    }

    // MARK: -

    func update(dt: TimeInterval) {
        renderable?.update(dt: dt)
    }

    var animationLoopsCompleted: Int {
        guard let animation = renderable as? StateAnimation else {
            return 0
        }
        return animation.animationSession.loopsCompleted
    }

    var animationFinished: Bool {
        guard let animation = renderable as? StateAnimation else {
            return false
        }
        return animation.animationSession.isFinished
    }

    func reset() {
        guard let animation = renderable as? StateAnimation else {
            return
        }
        let newSession = AnimationSession(source: animation.animationSession.source, loopMode: animation.animationSession.loopMode)
        self.renderable = StateAnimation(animationSession: newSession)
    }
}

protocol StateRenderable {
    var mesh: Any { get }
    mutating func update(dt: TimeInterval)
}

struct StateSprite: StateRenderable {
    let mesh: Any
    func update(dt: TimeInterval) { }
}

struct StateAnimation: StateRenderable {
    var animationSession: AnimationSession

    var mesh: Any {
        return animationSession.currentFrame.mesh
    }

    mutating func update(dt: TimeInterval) {
        animationSession.update(dt: dt)
    }
}
