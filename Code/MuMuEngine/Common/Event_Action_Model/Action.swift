//
//  Action.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/24.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

protocol Action: Codable, NamedType { }

// MARK: - Concrete Actions

struct SendMessageAction: Action {
    static let name: String = "sendMessage"
    let content: String
}

struct StateTransitionAction: Action {
    static let name: String = "stateTransition"
    let destination: String
}

struct RemoveNodeAction: Action {
    static let name: String = "removeNode"

    // No content: The node that owns the action is removed
}

struct SceneTransitionAction: Action {
    static let name: String = "sceneTransition"

    let destination: String
    let effect: Transition.Effect?
    let duration: TimeInterval?

    // MARK: Member-wise Initialzation

    init(destination: String, effect: Transition.Effect? = nil, duration: TimeInterval? = nil) {
        self.destination = destination
        self.effect = effect
        self.duration = duration
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case destination
        case effect
        case duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.destination = try container.decode(String.self, forKey: .destination)
        self.effect = try container.decodeIfPresent(Transition.Effect.self, forKey: .effect)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(destination, forKey: .destination)
        try container.encodeIfPresent(effect, forKey: .effect)
        try container.encodeIfPresent(duration, forKey: .duration)
    }
}


