//
//  Engine.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2020/04/10.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

class Engine {

    private(set) static var shared = Engine()

    static func start(configuration: GameConfiguration? = nil) throws {
        // Replace dummy instance:
        let conf = try configuration ?? GameConfiguration.loadDefault()
        self.shared = try Engine(configuration: conf)
    }

    // MARK: -

    let graphicsAPI: GraphicsAPI

    let timeSource: TimeSource

    var view: View {
        return graphicsAPI.view
    }

    var viewSize: CGSize {
        return graphicsAPI.view.bounds.size
    }

    init(configuration: GameConfiguration) throws {
        self.graphicsAPI = try configuration.createGraphicsApi()
        self.timeSource = TimeSource() // make injectable for testing
    }

    private init() {
        self.graphicsAPI = EmptyGraphicsApi()
        self.timeSource = TimeSource()
    }

    // MARK: Operation

    func loadScene(name: String, bundle: Bundle = .main, completion: (() -> Void)) {

    }

    // MARK: - Resource Loading Support

    fileprivate func loadScene(
        name: String,
        bundle: Bundle = .main,
        completion: @escaping ((Scene) -> Void),
        failure: @escaping ((Error) -> Void) = defaultFailureHandler
    ) {
        
    }

    fileprivate func loadSceneManifest(
        name: String,
        bundle: Bundle = .main,
        completion: @escaping ((SceneManifest) -> Void),
        failure: @escaping ((Error) -> Void) = defaultFailureHandler
    ) {
        guard let path = bundle.path(forResource: name, ofType: sceneManifestFileExtension) else {
            let error = RuntimeError.fileNotFound(fileName: name, type: .sceneManifest, bundleIdentifier: bundle.bundleIdentifier)
            return failure(error)
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let manifest = try JSONDecoder().decode(SceneManifest.self, from: data)
            completion(manifest)
        } catch {
            failure(error)
        }
    }

    fileprivate func loadSceneManifest(name: String, bundle: Bundle = .main) -> Promise<SceneManifest> {
        let promise = Promise<SceneManifest>(in: .background) { (resolve, reject) in
            guard let path = bundle.path(forResource: name, ofType: sceneManifestFileExtension) else {
                throw RuntimeError.fileNotFound(fileName: name, type: .sceneManifest, bundleIdentifier: bundle.bundleIdentifier)
            }
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let manifest = try JSONDecoder().decode(SceneManifest.self, from: data)
                resolve(manifest)
            } catch {
                reject(error)
            }
        }
        return promise
    }
}


fileprivate let defaultFailureHandler: ((Error) -> Void) = { (error) in
    systemAlert(title: "Error", message: error.localizedDescription)
}


fileprivate func registerCustomCoders() {
    // Register event types for encoding/decoding:
    Container.register(PointInputEvent.self)
    Container.register(AnimationCompleteEvent.self)
    Container.register(MessageReceivedEvent.self)

    // Register action types for encoding/decoding:
    Container.register(StateTransitionAction.self)
    Container.register(SceneTransitionAction.self)
    Container.register(SendMessageAction.self)
    Container.register(RemoveNodeAction.self)

    // Register node Component types for encoding/decoding:
    Container.register(StateMachineComponent.self)
    Container.register(HitBoxComponent.self)
}

// MARK: - Support

fileprivate extension String {
    static let configurationFileName = "GameConfiguration"
    static let configurationFileExtension = "json"

    static let sceneDataFileExtension = "scenedata"
    static let sceneManifestFileExtension = "scenemanifest"
}
