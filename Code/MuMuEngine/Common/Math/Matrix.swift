//
//  Matrix.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/30.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import Foundation
import simd

/**
 Encapsulates all 6 planes needed to specify an orthographic projection matrix.
 */
public struct OrthographicProjectionDescriptor {
    public var left: Float
    public var right: Float
    public var bottom: Float
    public var top: Float
    public var near: Float
    public var far: Float

    public init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.near = near
        self.far = far
    }
}

public extension float4x4 {
    static func orthographicProjection(_ descriptor: OrthographicProjectionDescriptor) -> float4x4 {
        let row0: SIMD4<Float> = SIMD4(2/(descriptor.right - descriptor.left), 0, 0, 0)
        let row1: SIMD4<Float> = SIMD4(0, 2/(descriptor.top - descriptor.bottom), 0, 0)
        let row2: SIMD4<Float> = SIMD4(0, 0, 1/(descriptor.far - descriptor.near), 0)
        let row3: SIMD4<Float> = SIMD4(
            (descriptor.left + descriptor.right) / (descriptor.left - descriptor.right),
            (descriptor.top + descriptor.bottom) / (descriptor.bottom - descriptor.top),
            descriptor.near / (descriptor.near - descriptor.far),
            1
        )
        return float4x4(rows: [row0, row1, row2, row3])
    }

    /**
     - note: Unused.
     */
    static func perspectiveProjectionRightHand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> float4x4 {
        let ys = 1 / tanf(fovy * 0.5)
        let xs = ys / aspectRatio
        let zs = farZ / (nearZ - farZ)

        return float4x4(
            columns: (
                vector_float4(xs, 0, 0, 0),
                vector_float4( 0, ys, 0, 0),
                vector_float4( 0, 0, zs, -1),
                vector_float4( 0, 0, zs * nearZ, 0)
            )
        )
    }

    static func rotation(radians: Float, axis: SIMD3<Float>) -> float4x4 {
        let unitAxis = normalize(axis)
        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
        return float4x4(
            columns: (
                SIMD4(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                SIMD4(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0),
                SIMD4(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0),
                SIMD4(0, 0, 0, 1)
            )
        )
    }

    static func translation(x: Float, y: Float, z: Float) -> float4x4 {
        return matrix_float4x4.init(
            columns: (
                SIMD4(1, 0, 0, 0),
                SIMD4(0, 1, 0, 0),
                SIMD4(0, 0, 1, 0),
                SIMD4(x, y, z, 1)
            )
        )
    }

    static func translation(_ vector: SIMD3<Float>) -> float4x4 {
        return matrix_float4x4.init(
            columns: (
                SIMD4(1, 0, 0, 0),
                SIMD4(0, 1, 0, 0),
                SIMD4(0, 0, 1, 0),
                SIMD4(vector.x, vector.y, vector.z, 1)
            )
        )
    }


}

/**
 */
func radiansFromDegrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

extension Float {
    var degreesToRadians: Float {
        return (self / 180) * .pi
    }
}

/**
 The vector type `float4` conforms to `Codable` since Swift 5. We still need to
 implement conformance for the matrix type `float4x4`.
 */
extension float4x4: Codable {

    enum CodingKeys: String, CodingKey {
        case columns
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let columns = try container.decode([SIMD4<Float>].self, forKey: .columns)
        self = float4x4(columns)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let columns = [self.columns.0, self.columns.1, self.columns.2, self.columns.3]
        try container.encode(columns, forKey: .columns)
    }
}

extension float4x4 {
    static var identity: float4x4 {
        return float4x4(1)
    }
}
