//
//  Container.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/08/21.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Adds heterogeneity support for the Codable protocols.

 The game resources are nested, heterogeneous JSON files. Out of the box it is not possible to automagically
 decode such heterogeneous dictionaries using the Codable protocol alone. To overcome this limitation, at
 every level of the JSON each component adopts a common structure as follows:

     {
         type: "SomeType",
         payload: {
            // ...
         }
     }

 ...where the contents (and structure) of the dictionary `payload` vary depending on the actual type of component.

 At runtime, when parsing the JSON, the block above is treated as a `Container` instance's worth of
 JSON and decoded accordingly. The string value `type` is used to select a Codable-conforming concrete type
 that was previously registered.

 Based on: https://medium.com/makingtuenti/indeterminate-types-with-codable-in-swift-5a1af0aa9f3d
 */
struct Container: Codable {
    /**
     A string used to identify the concrete type of the value stored at `payload`
     */
    let type: String

    /**
     The contained object (actual Swift type depends on the value of `type`).
     */
    let payload: Any

    // MARK: - Manual Initialization

    init(type: String, payload: Codable) {
        self.type = type
        self.payload = payload
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        print("Type: \(self.type)")
        guard let decode = Container.decoders[type] else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "Invalid Payload Type: \(type)")
            throw DecodingError.dataCorrupted(context)
        }
        self.payload = try decode(container)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)

        guard let encode = Container.encoders[type] else {
            let context = EncodingError.Context(codingPath: [], debugDescription: "Invalid Payload Type: \(type)")
            throw EncodingError.invalidValue(self, context)
        }
        try encode(payload, &container)
    }

    // MARK: - Type Registration Support

    private typealias PayloadDecoder = (KeyedDecodingContainer<CodingKeys>) throws -> Any
    private typealias PayloadEncoder = (Any, inout KeyedEncodingContainer<CodingKeys>) throws -> Void

    private static var decoders: [String: PayloadDecoder] = [:]
    private static var encoders: [String: PayloadEncoder] = [:]

    static func register<A: Codable>(_ type: A.Type, for typeName: String) {
        decoders[typeName] = { container in
            do {
               return try container.decode(A.self, forKey: .payload)
            } catch {
                print("Type Name: \(typeName)")
                throw error
            }
        }
        encoders[typeName] = { payload, container in
            try container.encode(payload as! A, forKey: .payload)
        }
    }

    static func register<A: Codable&NamedType>(_ type: A.Type) {
        register(type, for: type.name)
    }
}

// MARK: - Supporting Protocols

public protocol NamedType {
    static var name: String { get }

    var typeName: String { get }
}

extension NamedType {
    var typeName: String {
        return type(of: self).name
    }
}
