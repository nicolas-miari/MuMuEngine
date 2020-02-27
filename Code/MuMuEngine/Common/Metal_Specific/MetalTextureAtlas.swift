//
//  MetalTextureAtlas.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/11.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Metal
import CoreGraphics

class MetalTextureAtlas: TextureAtlas {

    let name: String

    let texture: MTLTexture

    let vertexBuffer: MTLBuffer

    let indexBuffer: MTLBuffer

    let indexBufferRangesByName: [String: Range<Int>]

    let fullOpacityFlagsByName: [String: Bool]

    let boundsByName: [String: CGRect]

    // MARK: - Initialization

    init(name: String, texture: MTLTexture, vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer, entries: [TextureAtlasEntry]) {
        self.name = name
        self.texture = texture
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer

        let spriteNames = entries.map { $0.name }
        let opacityFlags = entries.map { $0.opaque }
        let boundRects = entries.map { CGRect(origin: .zero, size: $0.nativeSize) }

        let ranges = spriteNames.enumerated().map { (index, _) -> Range<Int> in
            let start = 6 * index
            let end = start + 6
            return (start ..< end)
        }
        let zippedRanges = zip(spriteNames, ranges)
        self.indexBufferRangesByName = Dictionary(uniqueKeysWithValues: zippedRanges)

        let zippedFlags = zip(spriteNames, opacityFlags)
        self.fullOpacityFlagsByName = Dictionary(uniqueKeysWithValues: zippedFlags)

        let zippedBoundRects = zip(spriteNames, boundRects)
        self.boundsByName = Dictionary(uniqueKeysWithValues: zippedBoundRects)
    }

    func spriteComponent(name: String) -> TexturedMeshComponent? {
        guard let range = indexBufferRangesByName[name], let opaque = fullOpacityFlagsByName[name], let bounds = boundsByName[name] else {
            return nil
        }
        let sprite = MetalTexturedMesh(texture: texture, vertexBuffer: vertexBuffer, indexBuffer: indexBuffer, indexRange: range, fullyOpaque: opaque)
        sprite.name = name
        sprite.bounds = bounds

        sprite.alignmentOffset = CGPoint(
            x: Int(bounds.width).isOdd ? 0.5 : 0.0,
            y: Int(bounds.height).isOdd ? 0.5 : 0.0)

        // TODO: Decide reference count back

        return sprite
    }
}

extension Int {
    var isOdd: Bool {
        return ((self % 2) == 1)
    }
}
