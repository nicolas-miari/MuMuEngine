//
//  EventHandler.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/24.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Master object of the event-action model.

 Each node in a scene contains zero or more event handlers. When a specific event is triggered, all event handlers that
 'listen' to that event are notified, and they perform their associated actions.
 */
struct EventHandler: Codable {

    /**
     The event listened to by the event handler.
     */
    let event: Event

    /**
     The action performed by the handler when the event listened to occurs.
     */
    let action: Action

    // Member-wise Initialzation
    
    init(event: Event, action: Action) {
        self.event = event
        self.action = action
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case event
        case action
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let eventContainer = try container.decode(Container.self, forKey: .event)
        self.event = eventContainer.payload as! Event

        let actionContainer = try container.decode(Container.self, forKey: .action)
        self.action = actionContainer.payload as! Action
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let eventContainer = Container(type: type(of: event).name , payload: event)
        try container.encode(eventContainer, forKey: .event)

        let actionContainer = Container(type: type(of: action).name, payload: action)
        try container.encode(actionContainer, forKey: .action)
    }
}
