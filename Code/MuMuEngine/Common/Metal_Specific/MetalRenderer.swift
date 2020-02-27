//
//  NewRenderer.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/02.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Metal
import MetalKit
import simd

// MARK: -

struct Constants {
    var modelViewProjectionMatrix = float4x4()
    var tintColor = SIMD4<Float>(1, 1, 1, 1)
}

// MARK: -

fileprivate let maximumInflightBuffers: Int = 3
fileprivate let maxRenderPass: Int = 2
fileprivate var hue: Float = 0

// MARK: -

/**
 Subclass to override the rendering of individual nodes/scenes, and apply
 special effects. Or use delegation...

 - todo: Finish implementing, and test.
 */
open class CombiningMetalRenderer: NSObject, CombiningRenderer {
    // Persistent Metal Objects (common)

    private let targetView: MTKView
    private let commandQueue: MTLCommandQueue
    private var colorTextures: [MTLTexture]
    private let renderPassDescriptors: [MTLRenderPassDescriptor]
    private let resolveRenderPassDescriptor: MTLRenderPassDescriptor
    private let sampler: MTLSamplerState

    // Persistent Metal Objects (rendering opaque nodes)
    private let opaqueRenderPipeline: MTLRenderPipelineState
    private let opaqueDepthStencilState: MTLDepthStencilState

    // Persistent Metal Objects (rendering translucent nodes)
    private let blendingRenderPipeline: MTLRenderPipelineState
    private let blendingDepthStencilState: MTLDepthStencilState

    // Other resources
    private var constants = Constants()
    private var projectionMatrix: float4x4
    private let fullscreenVertexBuffer: MTLBuffer
    private let fullscreenIndexBuffer: MTLBuffer
    private var fullscreenModelMatrix: float4x4
    private let nodeClearColor: MTLClearColor
    private let transitionClearColor: MTLClearColor

    // Triple-Buffering Synchronization Support

    private let semaphore: DispatchSemaphore

    // MARK: - Initialization

    public init(targetView: MTKView) throws {
        guard let device = targetView.device else {
            throw RuntimeError.failedToInitializeGraphicsDriver(customMessage: "Failed to acquire view's Metal device.")
        }
        guard let commandQueue = device.makeCommandQueue() else {
            throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage: "Failed to create Metal command queue.")
        }

        self.semaphore = DispatchSemaphore(value: maximumInflightBuffers)

        self.commandQueue = commandQueue
        self.targetView = targetView

        let sharedDepthTexture = try createDepthAttachmentTexture(for: targetView)

        self.colorTextures = try Array(repeating: createColorAttachmentTexture(for: targetView), count: maxRenderPass)

        let clearColor = MTLClearColor(red: 0.3, green: 0.3, blue: 1, alpha: 1)
    
        self.renderPassDescriptors = colorTextures.map({(texture) -> MTLRenderPassDescriptor in
            let rpd = MTLRenderPassDescriptor()
            rpd.colorAttachments[0].texture = texture
            rpd.colorAttachments[0].loadAction = .load
            rpd.colorAttachments[0].storeAction = .store
            rpd.colorAttachments[0].clearColor = clearColor
            rpd.depthAttachment.texture = sharedDepthTexture
            return rpd
        })

        // Gets view's drawable attached before rendering the resolve pass each frame
        self.resolveRenderPassDescriptor = MTLRenderPassDescriptor()

        self.opaqueRenderPipeline = try createRenderPipelineState(for: targetView, blendingEnabled: false)
        self.opaqueDepthStencilState = try createOpaquePassDepthStencilState(from: device)

        self.blendingRenderPipeline = try createRenderPipelineState(for: targetView, blendingEnabled: true)
        self.blendingDepthStencilState = try createBlendingPassDepthStencilState(from: device)

        self.sampler = try createSamplerState(from: device)

        let width = Float( targetView.bounds.width)
        let height = Float(targetView.bounds.height)

        let projectionDescriptor = OrthographicProjectionDescriptor(
            left: -1*width,
            right: +1*width,
            bottom: -1*height,
            top: +1*height,
            near: 0,
            far: 2
        )
        self.projectionMatrix =  float4x4.orthographicProjection(projectionDescriptor)

        constants.modelViewProjectionMatrix = projectionMatrix
        constants.tintColor = SIMD4(x: 1, y: 1, z: 1, w: 1)

        self.fullscreenVertexBuffer = try createQuadVertexBuffer(from: device)
        self.fullscreenIndexBuffer = try createQuadIndexBuffer(from: device)
        self.fullscreenModelMatrix = float4x4(diagonal: SIMD4(arrayLiteral: 2*width, 2*height, 1, 1))

        self.nodeClearColor = clearColor
        self.transitionClearColor = MTLClearColor.opaqueWhite
    }

    // TEST
    public func viewDidResize() {
        let width = Float(targetView.bounds.width)
        let height = Float(targetView.bounds.height)

        let projectionDescriptor = OrthographicProjectionDescriptor(
            left: -1*width,
            right: +1*width,
            bottom: -1*height,
            top: +1*height,
            near: 0,
            far: 2
        )
        self.projectionMatrix =  float4x4.orthographicProjection(projectionDescriptor)
        self.fullscreenModelMatrix = float4x4(diagonal: SIMD4(arrayLiteral: 2*width, 2*height, 1, 1))
    }

    // MARK: - Renderer

    func blend(sourceNode: Node, destNode: Node, effect: Transition.Effect, progress: Float) {
        switch effect {
        case .sequentialFade:
            if progress <= 0.5 {
                // First half
                let opacity = 1.0 - (progress / 0.5)
                let eased = ease(opacity, easing: .easeInOut)
                render(node: sourceNode, atOpacity: eased)
            } else {
                // Second half
                let opacity = 2*(progress - 0.5)
                let eased = ease(opacity, easing: .easeInOut)
                render(node: destNode, atOpacity: eased)
            }
        case .crossDissolve:
            // Unimplemented
            break
        }
    }

    public func render(_ node: Node) {
        render(node: node, atOpacity: 1)
    }

    // MARK: - Building Blocks

    private func render(node: Node, atOpacity opacity: Float) {
        // <BEGIN triple buffer synchronization and checks boilerplate>
        _ = semaphore.wait(timeout: .distantFuture)
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        defer {
            commandBuffer.commit() // (executed on any return past this point)
        }
        commandBuffer.addCompletedHandler { [unowned self](_) in
            self.semaphore.signal()
        }
        commandBuffer.enqueue()
        // <END triple buffer synchronization and checks boilerplate>

        renderPassDescriptors[0].colorAttachments[0].clearColor = MTLClearColor(color: node.clearColor)
        renderPassDescriptors[0].colorAttachments[0].loadAction = .clear

        guard let nodeEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptors[0]) else {
            return
        }
        draw(node, using: nodeEncoder)
        nodeEncoder.endEncoding()

        //
        guard let drawable = targetView.currentDrawable, targetView.currentRenderPassDescriptor != nil else {
            return
        }

        // let width = drawable.texture.width
        // let height = drawable.texture.height
        
        resolveRenderPassDescriptor.colorAttachments[0].texture = drawable.texture
        resolveRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        resolveRenderPassDescriptor.colorAttachments[0].clearColor = transitionClearColor
        resolveRenderPassDescriptor.depthAttachment.texture = renderPassDescriptors[0].depthAttachment.texture
        resolveRenderPassDescriptor.depthAttachment.loadAction = .clear

        guard let resolveEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: resolveRenderPassDescriptor) else {
            return
        }

        resolveEncoder.pushDebugGroup("Blend Node At Opacity: \(opacity)")
        resolveEncoder.label = "Blend Node At Opacity Encoder"

        resolveEncoder.setDepthStencilState(blendingDepthStencilState)
        resolveEncoder.setRenderPipelineState(blendingRenderPipeline)

        resolveEncoder.setFrontFacing(.counterClockwise)
        resolveEncoder.setCullMode(.none)
        resolveEncoder.setFragmentSamplerState(sampler, index: 0)
        resolveEncoder.setVertexBuffer(fullscreenVertexBuffer, offset: 0, index: 0)
        resolveEncoder.setFragmentTexture(renderPassDescriptors[0].colorAttachments[0].texture!, index: 0)

        self.constants.modelViewProjectionMatrix = self.projectionMatrix * fullscreenModelMatrix
        self.constants.tintColor = SIMD4([1, 1, 1, opacity])
        resolveEncoder.setVertexBytes(&self.constants, length: MemoryLayout<Constants>.size, index: 1)
        resolveEncoder.setFragmentBytes(&self.constants, length: MemoryLayout<Constants>.size, index: 1)

        resolveEncoder.drawIndexedPrimitives(
            type: MTLPrimitiveType.triangleStrip,
            indexCount: 6,
            indexType: .uint32,
            indexBuffer: fullscreenIndexBuffer,
            indexBufferOffset: 0)

        resolveEncoder.popDebugGroup()
    
        resolveEncoder.endEncoding()

        // Done
        commandBuffer.present(drawable)
    }

    // MARK: -

    private func draw(_ node: Node, using renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.pushDebugGroup("Render Node")
        renderEncoder.label = "Single Node Encoder"

        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.none)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)

        let renderSet = RenderSet(from: node)

        let drawSingleMesh: ((Node) -> Void) = {(node) in
            let mesh = node.meshComponent as! MetalTexturedMesh

            renderEncoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(mesh.texture, index: 0)

            let alignment = float4x4.translation(x: Float(mesh.alignmentOffset.x), y: Float(mesh.alignmentOffset.y), z: 0)
            let model =  float4x4.translation(x: 0, y: 0, z: node.z) * node.localTransform
            self.constants.modelViewProjectionMatrix = self.projectionMatrix * alignment * model
            renderEncoder.setVertexBytes(&self.constants, length: MemoryLayout<Constants>.size, index: 1)
            renderEncoder.setFragmentBytes(&self.constants, length: MemoryLayout<Constants>.size, index: 1)

            renderEncoder.drawIndexedPrimitives(
                type: MTLPrimitiveType.triangleStrip,
                indexCount: 6,
                indexType: .uint32,
                indexBuffer: mesh.indexBuffer,
                indexBufferOffset: 4*(mesh.indexRange.lowerBound)
            )
        }

        // [A] Opaques first, front to back:

        renderEncoder.pushDebugGroup("Opaque Children")

        renderEncoder.setDepthStencilState(opaqueDepthStencilState)
        renderEncoder.setRenderPipelineState(opaqueRenderPipeline)
        renderSet.opaque.forEach { (node) in
            drawSingleMesh(node)
        }
        renderEncoder.popDebugGroup() // "Opaque Children"

        // [B] Non-opaques last, back to front:

        renderEncoder.pushDebugGroup("Translucent Children")

        renderEncoder.setDepthStencilState(blendingDepthStencilState)
        renderEncoder.setRenderPipelineState(blendingRenderPipeline)
        renderSet.nonOpaque.forEach { (node) in
            drawSingleMesh(node)
        }
        renderEncoder.popDebugGroup() // "Translucent Children"
        renderEncoder.popDebugGroup() // "Render Node"
    }

    private func updateColor() -> MTLClearColor {
        hue += 0.01
        if hue >= 1.0 {
            hue -= 1.0
        }

        #if os(macOS)
        let color = NSColor(calibratedHue: CGFloat(hue), saturation: 1, brightness: 1, alpha: 1)
        let metalColor = MTLClearColor(
            red: Double(color.redComponent),
            green: Double(color.greenComponent),
            blue: Double(color.blueComponent),
            alpha: 1)
        #elseif os(iOS)
        let color = UIColor(hue: CGFloat(hue), saturation: 1, brightness: 1, alpha: 1)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let metalColor = MTLClearColor(red: Double(red), green: Double(green), blue: Double(blue), alpha: 1)
        #endif

        return metalColor
    }
}

// MARK: - Metal Resource Creation Support

fileprivate func createDepthAttachmentTexture(for view: MTKView) throws -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .depth32Float,
        width: Int(view.drawableSize.width),
        height: Int(view.drawableSize.height),
        mipmapped: false)
    descriptor.usage = .renderTarget
    descriptor.storageMode = .private
    descriptor.sampleCount = view.sampleCount

    guard let depthTexture = view.device?.makeTexture(descriptor: descriptor) else {
        throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage: "Failed to create depth texture.")
    }
    return depthTexture
}

fileprivate func createColorAttachmentTexture(for view: MTKView) throws -> MTLTexture {
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.pixelFormat = view.colorPixelFormat
    textureDescriptor.sampleCount = 1
    textureDescriptor.width = Int(view.drawableSize.width)
    textureDescriptor.height = Int(view.drawableSize.height)
    textureDescriptor.depth = 1
    textureDescriptor.textureType = MTLTextureType.type2D
    textureDescriptor.usage = [.renderTarget, .shaderRead]
    textureDescriptor.resourceOptions = .storageModePrivate // ???

    guard let colorTexture = view.device?.makeTexture(descriptor: textureDescriptor) else {
        throw NSError()
    }
    return colorTexture
}

fileprivate func createOpaquePassDepthStencilState(from device: MTLDevice) throws -> MTLDepthStencilState {
    let descriptor = MTLDepthStencilDescriptor()

    // Write z of rendered fragment to the depth buffer:
    descriptor.isDepthWriteEnabled = true

    // Pass depth test only if nearer to the camera than last rendered fragment:
    descriptor.depthCompareFunction = .less

    guard let state = device.makeDepthStencilState(descriptor: descriptor) else {
        throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage: "Failed to create depth^stencil state.")
    }
    return state
}

fileprivate func createBlendingPassDepthStencilState(from device: MTLDevice) throws -> MTLDepthStencilState {
    let descriptor = MTLDepthStencilDescriptor()

    // Skip writing z of rendered fragment to the depth buffer:
    descriptor.isDepthWriteEnabled = false

    // Pass depth test only if nearer to the camera than last rendered fragment:
    descriptor.depthCompareFunction = .less

    guard let state = device.makeDepthStencilState(descriptor: descriptor) else {
        throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage: "Failed to create depth^stencil state.")
    }
    return state
}

/**
 - todo: Create a separate pipeline for rendering fully opaque objects?
 */
fileprivate func createRenderPipelineState(for view: MTKView, blendingEnabled: Bool) throws -> MTLRenderPipelineState {
    guard let device = view.device else {
        throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage: "Failed to acquire Metal device.")
    }
    let bundle = Bundle(for: CombiningMetalRenderer.self)
    let library = try device.makeDefaultLibrary(bundle: bundle)

    let vertexFunction = library.makeFunction(name: "sprite_vertex_transform")
    let fragmentFunction = library.makeFunction(name: "sprite_fragment_textured")

    let descriptor = MTLRenderPipelineDescriptor()

    descriptor.sampleCount = view.sampleCount
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
    descriptor.depthAttachmentPixelFormat = .depth32Float

    descriptor.colorAttachments[0].isBlendingEnabled = blendingEnabled

    if blendingEnabled {
        // 'Standard' blending operations factors for non-premultiplied sprites:
        //
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add

        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha

        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }

    return try device.makeRenderPipelineState(descriptor: descriptor)
}

fileprivate func createSamplerState(from device: MTLDevice) throws -> MTLSamplerState {
    let descriptor = MTLSamplerDescriptor()
    descriptor.sAddressMode = .clampToEdge
    descriptor.tAddressMode = .clampToEdge
    descriptor.normalizedCoordinates = true
    descriptor.minFilter = .nearest
    descriptor.magFilter = .nearest

    guard let sampler = device.makeSamplerState(descriptor: descriptor) else {
        throw NSError()
    }
    return sampler
}

fileprivate func createQuadVertexBuffer(from device: MTLDevice) throws -> MTLBuffer {
    // Create unit quad. When rendering, apply model transform to scale to
    // full-screen size

    let xCoords: [Float] = [-0.5, -0.5, 0.5,  0.5]
    let yCoords: [Float] = [ 0.5, -0.5, 0.5, -0.5]
    let sCoords: [Float] = [ 0.0,  0.0, 1.0,  1.0]
    let tCoords: [Float] = [ 0.0,  1.0, 0.0,  1.0]

    let vertices: [Vertex] = (0 ..< 4).map({ (index) -> Vertex in
        let pos = SIMD4([xCoords[index], yCoords[index], 0, 1])
        let tex = SIMD2([sCoords[index], tCoords[index]])
        return Vertex(position: pos, textureCoordinate: tex)
    })

    let vertexBufferSize = vertices.count * MemoryLayout<Vertex>.stride

    guard let buffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: []) else {
        throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage:  "Failed to Create Metal Vertex Buffer.")
    }
    return buffer
}

fileprivate func createQuadIndexBuffer(from device: MTLDevice) throws -> MTLBuffer {
    let indices: [UInt32] = [0, 1, 2, 2, 1, 3]

    let indexBufferSize = indices.count * MemoryLayout<UInt32>.stride

    guard let buffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: []) else {
        throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage:  "Failed to Create Metal Index Buffer.")
    }
    return buffer
}
