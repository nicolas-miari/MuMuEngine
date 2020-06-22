//
//  MetalGraphicsAPI.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/30.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import Metal
import MetalKit

/**
 Encapsulates all Metal-specific details so that the rest of the framework code
 remains API-agnostic.

 - todo: Add coverage for failure code paths (RED).
 */
class MetalGraphicsAPI: NSObject, GraphicsAPI {

    // MARK: - Exposed Properties

    let name: String

    let metalview: MTKView

    var view: View {
        return metalview
    }

    var vSyncHandler: (() -> Void)?

    var backingScaleFactor: CGFloat {
        return scaleFactor
    }

    let renderer: CombiningRenderer

    // MARK: - Private Properties

    private let device: MTLDevice
    private let textureLoader: MTKTextureLoader
    private var testTexture: MTLTexture?
    private let scaleFactor: CGFloat

    // MARK: Cached Resources

    private var atlasCache: [String: MetalTextureAtlas]
    private var tileSetCache: [String: MetalTileSet]
    private var animationCache: [String: Animation]
    private var blueprintCache: [String: Blueprint]

    // MARK: - Initialization

    public init(viewSize: CGSize, scaleFactor: CGFloat) throws {
        let device = try createSystemDefaultMetalDevice()

        self.name = "Metal"
        self.device = device
        self.scaleFactor = scaleFactor

        let metalView = MTKView(frame: CGRect(origin: .zero, size: viewSize), device: device)
        metalView.colorPixelFormat = .bgra8Unorm_srgb // Not sure if needed...
        metalView.preferredFramesPerSecond = 60
        metalView.isPaused = false // (should be default anyway)
        metalView.enableSetNeedsDisplay = false // (should be default anyway)

        self.metalview = metalView
        self.textureLoader = MTKTextureLoader(device: device)
        self.renderer = try CombiningMetalRenderer(targetView: metalView)

        self.atlasCache = [:]
        self.animationCache = [:]
        self.blueprintCache = [:]
        self.tileSetCache = [:]

        super.init()
        metalView.delegate = self
    }

    // MARK: - GraphicsAPI

    public func preloadSceneResources(from manifest: SceneManifest, bundle: Bundle, completion: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) -> Void {
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.loadAtlases(names: manifest.textureAtlasNames, bundle: bundle)
                try self?.loadAnimations(names: manifest.animationNames, bundle: bundle)
                try self?.loadBlueprints(names: manifest.blueprintNames, bundle: bundle)

                completion()
            } catch {
                failure(error)
            }
        }
    }

    public func preloadSceneResources(from manifest: SceneManifest, bundle: Bundle) throws -> Promise<Void> {
        let promise = Promise<Void>(in: .background) { [weak self](resolve, reject) in
            do {
                try self?.loadAtlases(names: manifest.textureAtlasNames, bundle: bundle)
                try self?.loadAnimations(names: manifest.animationNames, bundle: bundle)
                try self?.loadBlueprints(names: manifest.blueprintNames, bundle: bundle)

                resolve(())
            } catch {
                reject(error)
            }
        }
        return promise
    }

    func spriteComponent(name: String, inAtlas atlasName: String) throws -> TexturedMeshComponent {
        guard let atlas = atlasCache[atlasName] else {
            throw RuntimeError.textureAtlasNotLoaded(atlasName: atlasName)
        }
        guard let sprite = atlas.spriteComponent(name: name) else {
            throw RuntimeError.spriteNotFoundInAtlas(spriteName: name, atlasName: atlasName)
        }
        return sprite
    }

    func componentsFromBlueprint(name: String) throws -> [Component] {
        guard let blueprint = blueprintCache[name] else {
            throw RuntimeError.blueprintNotLoaded(blueprintName: name)
        }
        let components = blueprint.components.compactMap { $0.payload as? Component }
        /*
         Components are reference types that store internal, persistent state;
         Return deep, fresh copies each time:
         */
        let copies = try components.map({ (component) -> Component in
            return try component.copy()
        })
        return copies
    }

    func animation(name: String) throws -> Animation {
        guard let animation = animationCache[name] else {
            throw RuntimeError.animationNotLoaded(animationName: name)
        }
        return animation
    }

    public func render(_ node: Node) {
        renderer.render(node)
    }

    public func render(_ transition: Transition) {
        renderer.blend(sourceNode: transition.source, destNode: transition.dest, effect: transition.effect, progress: Float(transition.progress))
    }

    // MARK: - Resource Loading Support

    // MARK: Animations

    private func loadAnimations(names: [String], bundle: Bundle = .main) throws {
        // (skip duplicates)
        let newNames = names.filter { !(animationCache.keys.contains($0)) }

        let paths = try newNames.map({ (name) -> String in
            guard let path = bundle.path(forResource: name, ofType: "animationdata") else {
                throw RuntimeError.fileNotFound(fileName: name, type: .animationData, bundleIdentifier: bundle.bundleIdentifier)
            }
            return path
        })

        let animations: [Animation] = try paths.map({ (path) -> Animation in
            let data = try Data(contentsOf: URL(fileURLWithPath: path))

            let animation = try JSONDecoder().decode(Animation.self, from: data)

            try animation.assembleRuntimeResources()
            return animation
        })

        let zippedNames = zip(newNames, animations)
        for (name, animation) in zippedNames {
            if animationCache[name] != nil {
                Swift.print("WARNING: Replacing animation '\(name)'")
            }
            animationCache[name] = animation
            animation.setName(name)
        }
    }

    // MARK: Blueprints

    private func loadBlueprints(names: [String], bundle: Bundle = .main) throws {
        // (skip duplicates)
        let newNames = names.filter { !(blueprintCache.keys.contains($0)) }

        let paths = try newNames.map({ (name) -> String in
            guard let path = bundle.path(forResource: name, ofType: "blueprint") else {
                throw RuntimeError.fileNotFound(fileName: name, type: .blueprintData, bundleIdentifier: bundle.bundleIdentifier)
            }
            return path
        })

        let blueprints: [Blueprint] = try paths.map({ (path) -> Blueprint in
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let blueprint = try JSONDecoder().decode(Blueprint.self, from: data)
            return blueprint
        })

        let zippedNames = zip(newNames, blueprints)
        for (name, blueprint) in zippedNames {
            if blueprintCache[name] != nil {
                Swift.print("WARNING: Replacing blueprint '\(name)'")
            }
            blueprintCache[name] = blueprint
        }
    }

    // MARK: Texture Atlases (Spritesheets)

    public func loadAtlases(names: [String], bundle: Bundle = .main) throws {
        // (skip duplicates)
        let newNames = names.filter { !(atlasCache.keys.contains($0)) }
        let descriptorsByName = try loadAtlasDescriptors(names: newNames, bundle: bundle)
        let textureInfosByName = try loadTextures(names: newNames, bundle: bundle)

        let namesAndAtlases = try newNames.map({ (name) -> (String, MetalTextureAtlas) in
            guard let descriptor = descriptorsByName[name] else {
                throw RuntimeError.failedToLoadTextureAtlasDescriptor(name: name)
            }
            guard let textureInfo = textureInfosByName[name] else {
                throw RuntimeError.failedToLoadTextureAtlasTexture(name: name)
            }
            let vertexBuffer = try self.generateAtlasVertexBuffer(textureSize: textureInfo.pointSize, entries: descriptor.sprites)
            let indexbuffer = try self.generateAtlasIndexBuffer(subimageCount: descriptor.sprites.count)

            let atlas = MetalTextureAtlas(name: name, texture: textureInfo.texture, vertexBuffer: vertexBuffer, indexBuffer: indexbuffer, entries: descriptor.sprites)
            return (name, atlas)
        })

        let newAtlasesByName = Dictionary(uniqueKeysWithValues: namesAndAtlases)

        self.atlasCache.merge(newAtlasesByName, uniquingKeysWith: { (_, new) -> MetalTextureAtlas in
            return new // -> pick the NEW value (overwrite)
        })
    }

    private func loadAtlasDescriptors(names: [String], bundle: Bundle = .main) throws -> [String: TextureAtlasMetadata] {
        let paths = try names.map({ (name) -> String in
            guard let path = bundle.path(forResource: name, ofType: "json") else {
                throw RuntimeError.fileNotFound(fileName: name, type: .atlasMetadata, bundleIdentifier: bundle.bundleIdentifier)
            }
            return path
        })

        let atlasDescriptors = try paths.map { (path) -> TextureAtlasMetadata in
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let metadata = try JSONDecoder().decode(TextureAtlasMetadata.self, from: data)
            return metadata
        }

        let zippedNames = zip(names, atlasDescriptors)
        let dict = Dictionary(uniqueKeysWithValues: zippedNames)

        return dict
    }

    // MARK: Tile Sets

    public func loadTileSets(names: [String], bundle: Bundle = .main) throws {
        // (skip duplicates)
        let newNames = names.filter { !(tileSetCache.keys.contains($0)) }
        let descriptorsByName = try loadTileSetDescriptors(names: newNames, bundle: bundle)
        let textureInfosByName = try loadTextures(names: newNames, bundle: bundle)

        let namesAndTileSets = try newNames.map({ (name) -> (String, MetalTileSet) in
            guard let descriptor = descriptorsByName[name] else {
                throw RuntimeError.failedToLoadTextureAtlasDescriptor(name: name)
            }
            guard let textureInfo = textureInfosByName[name] else {
                throw RuntimeError.failedToLoadTextureAtlasTexture(name: name)
            }
            let tileSet = MetalTileSet(name: name, textureInfo: textureInfo, tileSize: descriptor.tileSize)
            return (name, tileSet)
        })

        let newTileSetsByName = Dictionary(uniqueKeysWithValues: namesAndTileSets)

        self.tileSetCache.merge(newTileSetsByName, uniquingKeysWith: { (_, new) -> MetalTileSet in
            return new // -> pick the NEW value (overwrite)
        })
    }

    private func loadTileSetDescriptors(names: [String], bundle: Bundle = .main) throws -> [String: TileSetMetadata] {
        let paths = try names.map({ (name) -> String in
            guard let path = bundle.path(forResource: name, ofType: "tilesetdata") else {
                throw RuntimeError.fileNotFound(fileName: name, type: .atlasMetadata, bundleIdentifier: bundle.bundleIdentifier)
            }
            return path
        })

        let tileSetDescriptors = try paths.map { (path) -> TileSetMetadata in
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let metadata = try JSONDecoder().decode(TileSetMetadata.self, from: data)
            return metadata
        }

        let zippedNames = zip(names, tileSetDescriptors)
        let dict = Dictionary(uniqueKeysWithValues: zippedNames)

        return dict
    }


    // MARK: Textures

    public func loadTextures(names: [String], bundle: Bundle = .main) throws -> [String: MetalTextureInfo] {
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
            .SRGB: NSNumber(value: true)
        ]
        let scale = scaleFactor

        let metalTextures = try names.map { (name) -> MTLTexture in
            return try textureLoader.newTexture(name: name, scaleFactor: scale, bundle: bundle, options: options)
        }
        let namesAndMetalTextures = zip(names, metalTextures)

        // Package into convenience structure that also contains point size and name:
        let namesAndEngineTextures: [(String, MetalTextureInfo)] = namesAndMetalTextures.map { (name, metalTexture) -> (String, MetalTextureInfo) in
            let pointsize = CGSize(
                width: CGFloat(metalTexture.width) / scale,
                height: CGFloat(metalTexture.height) / scale
            )
            let textureInfo = MetalTextureInfo(name: name, pointSize: pointsize, texture: metalTexture)
            return (name, textureInfo)
        }
        let dictionary = namesAndEngineTextures.reduce(into: [:]) { $0[$1.0] = $1.1 }

        return dictionary
    }

    // MARK: - Resource Loading Support

    private func generateAtlasVertexBuffer(textureSize: CGSize, entries: [TextureAtlasEntry]) throws -> MTLBuffer {
        let scale = Float(Runtime.shared.scaleFactor)

        let vertexData = entries.map { (entry) -> [Vertex] in

            let rect = entry.rect
            let nativeSize = entry.nativeSize

            let left = -0.5*Float(nativeSize.width) * scale
            let right = +0.5*Float(nativeSize.width) * scale
            let top = +0.5*Float(nativeSize.height) * scale
            let bottom = -0.5*Float(nativeSize.height) * scale

            let sMin = Float(rect.origin.x / textureSize.width)
            let sMax = Float((rect.origin.x + rect.size.width) / textureSize.width)
            let tMin = Float(rect.origin.y / textureSize.height)
            let tMax = Float((rect.origin.y + rect.size.height) / textureSize.height)

            //                  v0     v1     v2    v3
            let xPositions   = [left, left, right, right]
            let yPositions   = [top, bottom, top, bottom]

            let sCoordinates: [Float] = {
                if entry.rotated {
                    return [sMin, sMax, sMin, sMax]
                } else {
                    return [sMin, sMin, sMax, sMax]
                }
            }()

            let tCoordinates: [Float] = {
                if entry.rotated {
                    return [tMin, tMin, tMax, tMax]
                } else {
                    return [tMax, tMin, tMax, tMin]
                }
            }()

            let vertices: [Vertex] = (0 ..< 4).map({ (index) -> Vertex in
                let position: SIMD4<Float> = SIMD4([xPositions[index], yPositions[index], 0, 1])
                let texCoord: SIMD2<Float> = SIMD2([sCoordinates[index], tCoordinates[index]])
                return Vertex(position: position, textureCoordinate: texCoord)
            })

            return vertices
        }.flatMap{ $0 }

        let vertexBufferSize = vertexData.count * MemoryLayout<Vertex>.stride

        guard let buffer = device.makeBuffer(bytes: vertexData, length: vertexBufferSize, options: []) else {
            throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage:  "Failed to Create Metal Vertex Buffer.")
        }
        return buffer
    }

    private func generateAtlasIndexBuffer(subimageCount: Int) throws -> MTLBuffer {
        var indexData = [UInt32]()

        for subimageIndex in 0 ..< subimageCount {

            // Index to the first vertex of the quad:
            let offset = UInt32(4 * subimageIndex)

            // First triangle: Top left, bottom left, top right (CCW)
            indexData.append(offset + 0)
            indexData.append(offset + 1)
            indexData.append(offset + 2)

            // Second triangle: top right, bottom left, bottom right (CCW)
            indexData.append(offset + 2)
            indexData.append(offset + 1)
            indexData.append(offset + 3)
        }
        let indexBufferSize = indexData.count * MemoryLayout<UInt32>.stride

        guard let buffer = device.makeBuffer(bytes: indexData, length: indexBufferSize, options: []) else {
            throw RuntimeError.failedToInitializeGraphicsDriverResource(customMessage:  "Failed to Create Metal Index Buffer.")
        }
        return buffer
    }
}

class MetalTextureInfo {
    let name: String
    let pointSize: CGSize
    let texture: MTLTexture

    init(name: String, pointSize: CGSize, texture: MTLTexture) {
        self.name = name
        self.pointSize = pointSize
        self.texture = texture
    }
}

// MARK: - MTKViewDelegate

extension MetalGraphicsAPI: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // (Unsupported)
    }

    func draw(in view: MTKView) {
        vSyncHandler?()
    }
}
