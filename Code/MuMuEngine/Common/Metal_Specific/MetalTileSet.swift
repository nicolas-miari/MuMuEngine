//
//  MetalTileSet.swift
//  MuMuEngine-macOS
//
//  Created by Nicolás Miari on 2019/10/02.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Metal
import CoreGraphics

class MetalTileSet: TileSet {

    func tile(at index: Int) -> TexturedMeshComponent? {
        return nil
    }

    let name: String

    let texture: MTLTexture

    let tiles: [Tile]

    // MARK: - Initialization

    init(name: String, textureInfo: MetalTextureInfo, tileSize: Int) {
        self.name = name
        self.texture = textureInfo.texture

        let textureWidth = Float(textureInfo.pointSize.width)
        let textureHeight = Float(textureInfo.pointSize.height)

        // Calculate the texture coordinates for all tiles:
        let tilesWide = Int(floor(textureWidth)) / tileSize
        let tilesHigh = Int(floor(textureHeight)) / tileSize
        let tileCount = tilesWide * tilesHigh

        self.tiles = (0 ..< tileCount).map { (index) -> Tile in
            let x = index % tilesWide // (column)
            let y = index / tilesWide // (row)

            let sMin = Float(x * tileSize) / textureWidth
            let sMax = Float((x + 1) * tileSize) / textureWidth
            let tMin = Float(y * tileSize) / textureHeight
            let tMax = Float((y + 1) * tileSize) / textureHeight

            return Tile(sMin: sMin, sMax: sMax, tMin: tMin, tMax: tMax)
        }
    }
}

/**
 Encapsulates the texture coordinate ranges in both vertical and horizotnal directions for
 one tile of a tile set.
 */
struct Tile {
    /// The left-most value of the **horizontal** texture coordinate (s) for the tile
    let sMin: Float

    /// The right-most value of the **horizontal** texture coordinate (s) for the tile
    let sMax: Float

    /// The top-most value of the **vertical** texture coordinate (t) for the tile
    let tMin: Float

    /// The bottom-most value of the **vertical** texture coordinate (t) for the tile
    let tMax: Float
}

