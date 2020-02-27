//
//  Codable+Extensions.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/15.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/*
 Not used for now. Commented out for the sake of code coverage.
 Consider deleting.

 Taken from: https://medium.com/@scotthoyt/swift-4-bridging-codable-json-and-string-any-1b76b9df2b2e
 */

/*
extension JSONEncoder {
    func encodeJSONObject<T: Encodable>(_ value: T, options opt: JSONSerialization.ReadingOptions = []) throws -> Any {
        let data = try encode(value)
        return try JSONSerialization.jsonObject(with: data, options: opt)
    }
}

extension JSONDecoder {
    func decode<T: Decodable>(_ type: T.Type, withJSONObject object: Any, options opt: JSONSerialization.WritingOptions = []) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object, options: opt)
        return try decode(T.self, from: data)
    }
}
 */
