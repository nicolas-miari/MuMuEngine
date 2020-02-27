//
//  TileSet.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/10/03.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

public struct TileAttributes: Codable {
    let index: Int
    let attributes: [String: String]
}

public struct TileSetMetadata: Codable {
    public let tileSize: Int
    public let tileAttributes: [TileAttributes]

    public init(tileSize: Int, attributes: [TileAttributes]) {
        self.tileSize = tileSize
        self.tileAttributes = attributes
    }
}

protocol TileSet: AnyObject {
    func tile(at index: Int) -> TexturedMeshComponent?
}
