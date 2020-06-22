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

 The game resources are nested, heterogeneous JSON files: the various nested
 dictionaries should be decoded to various different types. Out of the box it is
 not possible to automagically decode these dictionaries using the Codable
 protocols alone. To overcome this limitation, at every level of the JSON, each
 component represented as a dictionary adopts a common structure:

     {
         type: "SomeType",
         payload: {
            // ...
         }
     }

 ...where the contents (and structure) of the dictionary `payload` vary
 depending on the actual type of component (specificed by the `type` field).

 At runtime, when parsing the JSON, the block above is treated as a `Container`
 instance's worth of JSON and decoded accordingly. During decoding, the string
 value `type` is used to select a Codable-conforming concrete type that was
 previously registered.

 Based on: https://medium.com/makingtuenti/indeterminate-types-with-codable-in-swift-5a1af0aa9f3d
 */
struct Container: Codable {
    /**
     A string used to identify the concrete Swift type that should be used to
     decode the JSON content stored under the `payload` key.
     */
    let typeName: String

    /**
     An object decoded from the contents of the JSON dictionary found under the
     key `payload`. The actual type is determined by the value of `typeName`.
     */
    let payload: Any

    // MARK: - Manual Initialization

    init(type: String, payload: Codable) {
        self.typeName = type
        self.payload = payload
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case typeName = "type"
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.typeName = try container.decode(String.self, forKey: .typeName)
        guard let decode = Container.decoders[typeName] else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "Invalid Payload Type: \(typeName)")
            throw DecodingError.dataCorrupted(context)
        }
        self.payload = try decode(container)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(typeName, forKey: .typeName)

        guard let encode = Container.encoders[typeName] else {
            let context = EncodingError.Context(codingPath: [], debugDescription: "Invalid Payload Type: \(typeName)")
            throw EncodingError.invalidValue(self, context)
        }
        try encode(payload, &container)
    }

    // MARK: - Type Registration Support

    private typealias PayloadDecoder = (KeyedDecodingContainer<CodingKeys>) throws -> Any
    private typealias PayloadEncoder = (Any, inout KeyedEncodingContainer<CodingKeys>) throws -> Void

    private static var decoders: [String: PayloadDecoder] = [:]
    private static var encoders: [String: PayloadEncoder] = [:]

    /**
     Registers the type `A` and the string `typeName` as a pair, so whenever a
     JSON subdictionary is found that contains the value `typeName` under the
     key "type", the (dictionary) contents under the key `payload` are decoded
     into an instance of type `A` (the class JSONDEcoder needs to know the type
     of the object being decoded, it obviously can't be inferred from the JSON
     itself).
     Similarly, when an object of type `A` needs to be serialized to JSON, a
     dictioary is produced with the value `typeName` under the key "type", and
     the object's JSON representation under the key `payload`, so that its type
     can be inferred in the future when decoded.

     - Parameters
       - type: The swift type that is being registered for encoding/decoding.
       - typeName: A string that uniquely identifies `type` (it is recommended
       to use the source-code representation of `type`, e.g. "String" for
     `Foundation.String`).
     */
    static func register<A: Codable>(_ type: A.Type, for typeName: String) {
        decoders[typeName] = { container in
            //do {
               return try container.decode(A.self, forKey: .payload)
            //} catch {
            //    throw error // Uncomment for debugging (or catch DecodingError's specifically)
            //}
        }
        encoders[typeName] = { payload, container in
            try container.encode(payload as! A, forKey: .payload)
        }
    }

    /**
     Shortcut for `register(_:typeName:)` to be used with types that conform to
     the protocol `NamedType` (and therefore can be inspected for a viable
     string representation of their type name).
     */
    static func register<A: Codable&NamedType>(_ type: A.Type) {
        register(type, for: type.name)
    }
}

// MARK: - Supporting Protocols

public protocol NamedType {
    /**
     For use when quering the type about its name.
     */
    static var name: String { get }

    /**
     For use when querying **instances** of the type about their type's name.
     */
    var typeName: String { get }
}

// MARK: Default implementations

extension NamedType {
    var typeName: String {
        return type(of: self).name
    }
}
