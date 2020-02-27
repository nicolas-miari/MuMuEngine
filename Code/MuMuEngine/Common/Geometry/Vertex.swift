//
//  Vertex.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/31.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import simd

/**
 Represents a texture-mapped 3D vertex with position in homogeneous coordinates.
 */
public struct Vertex {

    public let position: SIMD4<Float>
    public let textureCoordinate: SIMD2<Float>

    public init(position: SIMD4<Float>, textureCoordinate: SIMD2<Float>) {
        self.position = position
        self.textureCoordinate = textureCoordinate
    }
}
