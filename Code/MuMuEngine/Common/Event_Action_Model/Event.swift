//
//  NewEventActionModel.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/23.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

// MARK: - Common Protocol

/**
 Extends NamedType so that types adopting it can be conveniently encoded as
 JSON.
 */
protocol Event: Codable, NamedType { }

// MARK: - Event: Animation Complete

/**
 Used to signal the completion of a specific animation attached to some node's
 state.
 */
struct AnimationCompleteEvent: Event {

    static let name: String = "animationComplete"

    let count: Int
}

// MARK: - Event: Message Received

/**
 Used for sending events between various objects/entities at runtime.
 */
struct MessageReceivedEvent: Event {

    static let name: String = "messageReceived"

    let content: String
}

// MARK: - Event: Point Input

/**
 Input that can be ascribed a specific location (or point) on screen.

 This abstractly encompasses both **mouse** input (clicks) on macOS, and
  **touch** input (taps) on iOS.
 */
struct PointInputEvent: Event {

    static let name: String = "pointInput"

    let pointInput: PointInput

    private enum CodingKeys: String, CodingKey {
        case pointInput = "input"
    }

    init(pointInput: PointInput) {
        self.pointInput = pointInput
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let rawValue = try container.decode(String.self, forKey: .pointInput)

        guard let input = PointInput(rawValue: rawValue) else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "Invalid input action: \(rawValue)")
            throw DecodingError.dataCorrupted(context)
        }
        self.pointInput = input
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pointInput.rawValue, forKey: .pointInput)
    }
}
