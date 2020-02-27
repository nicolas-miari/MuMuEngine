//
//  Blueprint.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/16.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 A blueprint is a preset list of components that can be instantiated as a whole into one or more nodes,
 to avoid duplication and to save space in the scene data file (each node whithin the data file has only
 a reference to the blueprint by name, instead of repeating the same list of components over and over).
 */
class Blueprint: Codable {

    /**
     The list of components that make up the blueprint: a node instantiated using the blueprint will
     get a fresh copy of each one of these components.
     */
    let components: [Container]

    init(components: [Container] = []) {
        self.components = components
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case components
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.components = try container.decode([Container].self, forKey: .components)
        // Swift.print("Successfully decoded Blueprint")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(components, forKey: .components)
    }
}
