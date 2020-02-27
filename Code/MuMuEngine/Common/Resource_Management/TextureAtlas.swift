//
//  TextureAtlas.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/31.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import CoreGraphics

/**
 The actual class is graphics API-specific.
 */
protocol TextureAtlas: AnyObject {
    func spriteComponent(name: String) -> TexturedMeshComponent?
}

// TODO: Share code with AtlasEditor codebase to ensure compatibility/avoid duplication?

struct TextureAtlasEntry: Codable {
    let name: String
    let rotated: Bool
    let rect: CGRect
    let opaque: Bool

    var nativeSize: CGSize {
        if rotated {
            return CGSize(width: rect.height, height: rect.width)
        }
        return rect.size
    }
}

struct TextureAtlasMetadata: Codable {
    let sprites: [TextureAtlasEntry]
}

struct TileMapLayer {
    
}

