//
//  MetalTexturedMesh.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/11.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Metal
import CoreGraphics

class MetalTexturedMesh: TexturedMeshComponent {

    var name: String = ""

    // MARK: - Component

    func isCompatible(with component: Component) -> Bool {
        return !(component is MetalTexturedMesh)
    }

    // MARK: - TexturedMeshComponent

    var ownerName: String = ""
    let isFullyOpaque: Bool
    var bounds: CGRect = .null

    /**
     How much the mesh needs to be translated to be rendered point-aligned.
     Because the default anchor point is the center, if a mesh has an odd width
     or height, it's local transform will have to be shifted 0.5 in that
     direction in order to be rendered at point boudnaries.

     Calulated once on creation and stored; used every time the mesh is passed
     to the vertex shader.
     */
    var alignmentOffset: CGPoint = .zero

    // MARK: - Custom Properties

    let texture: MTLTexture
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexRange: Range<Int>


    init(texture: MTLTexture, vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer, indexRange: Range<Int>, fullyOpaque: Bool) {
        self.texture = texture
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        self.indexRange = indexRange
        self.isFullyOpaque = fullyOpaque
    }
}
