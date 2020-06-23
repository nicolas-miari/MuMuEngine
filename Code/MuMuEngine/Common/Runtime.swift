//
//  Runtime.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/30.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import CoreGraphics
import Foundation
import GameKit

/**
 External access point to the engine, orchestrates basically everything.
 */
public final class Runtime {

    /**
     Even though proper initialization of the runtime environment (load resource
     files, initialaize graphics API, etc.) is very much failable, the global
     reference to the runtime object is explicitly made a non-optional property,
     in order to avoid the repeated overhead of optional unwrapping.

     However, the initial value set immediately afyter launch is a
     non-functional instance, and attmepting to use it will result in an error.
     Call the method `start()` once before using the shared instance.
     */
    private(set) public static var shared = Runtime()

    // Runtime Properties

    /**
     An object that abstracts the graphics library used to load visual resources
     and render game content. Currently, Apple's Metal is used under the wraps.
     */
    let graphics: GraphicsAPI

    /**
     An object that abstracts the system timer, used to perform frame updates.
     */
    let timeSource: TimeSource

    /**
     The bundle from which all game resources are loaded. normally the app's
     main bundle, but a different bundle can be injected on instantiation for
     e.g. unit testing.
     */
    let bundle: Bundle

    var view: View {
        return graphics.view
    }

    var viewSize: CGSize {
        return view.bounds.size
    }

    var scaleFactor: CGFloat {
        return 2 // TODO: Use actual value! Also consider moving to graphics API
    }

    // TODO: Make configurable from init file
    let defaultTransitionEffect: Transition.Effect = .sequentialFade

    // TODO: Make configurable from init file
    let defaultTransitionDuration: TimeInterval = 1

    static let defaultFailureHandler: ((Error) -> Void) = { (error) in
        systemAlert(title: "Error", message: error.localizedDescription)
    }

    private var gameControllers: [GCController] = []

    var playerControllerStates: [Player: PlayerControllerState] = [:]

    // MARK: - Initialization (Private)

    private init(bundle: Bundle, api: GraphicsAPI, timeSource: TimeSource) {
        self.bundle = bundle
        self.graphics = api
        self.timeSource = timeSource
        playerControllerStates[.player1] = PlayerControllerState()
    }

    private init() {
        self.bundle = .main
        self.graphics = EmptyGraphicsApi()
        self.timeSource = EmptyTimesource()
    }

    // MARK: - Bootstrapping (App Launch)

    /**
     Bootstraps the engine runtime (creates shared instance) and loads initial
     app scene.
     */
    static func start(options: GameConfiguration? = nil, bundle: Bundle = .main, ready: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) throws {

        let configuration = try options ?? GameConfiguration.loadDefault()

        let api = try configuration.createGraphicsApi()
        let timeSource = configuration.createTimeSource()
        self.shared = Runtime(bundle: bundle, api: api, timeSource: timeSource)

        shared.registerCustomCoders()

        shared.loadScene(name: configuration.initialSceneName, onCompletion: .runImmediately)
    }

    // MARK: - Hit Testing

    internal var lastNodeHit: Node?

    func hitTest(at point: CGPoint) {
        guard currentTransition == nil else {
            return
        }
        guard let target = currentScene.rootNode.hitTest(point: point) else {
            return // Miss
        }
        target.instrinsicVisibility = !target.instrinsicVisibility // ?
    }

    // MARK: - Scene Management

    private(set) public var currentScene: Scene!
    private(set) public var nextScene: Scene!
    private(set) var currentTransition: Transition?

    enum LoadSceneResponse {
        /// The scene is run as soon as loading completes.
        case runImmediately

        ///
        case runAfterTransition(effect: Transition.Effect, duration: TimeInterval)

        ///
        case customAction(handler: ((Scene) -> Void))
    }

    /**
     Loads the scene with the specified name from the resource bundle asynchronously. On completion, the specified
     action is performed.
     */
    func loadScene(name: String, onCompletion: LoadSceneResponse, failure: @escaping ((Error) -> Void) = defaultFailureHandler) {
        loadScene(name: name, completion: { [unowned self](scene) in
            switch onCompletion {
            case .runImmediately:
                self.run(scene)

            case .runAfterTransition(let effect, let duration):
                self.transition(to: scene, effect: effect, duration: duration)

            case .customAction(let handler):
                handler(scene)
            }
        }, failure: failure)
    }

    /**
     */
    func runScene(name: String, bundle: Bundle? = nil, loadCompletion: (() -> Void)? = nil, failure: @escaping ((Error) -> Void) = defaultFailureHandler) throws {
        // Instantiate the scene with the given name from the bundled resources.

        loadScene(name: name,  completion: { (_) in
            loadCompletion?()

        }, failure: failure)
    }

    /**
     This method should be called only on startup, with the initial scene as an argument; anything else should ideally
     be handled smoothly using transitions.
     */
    func run(_ scene: Scene) {
        self.currentScene = scene

        graphics.vSyncHandler = { [unowned self] in
            self.handleSceneUpdate()
        }
    }

    func handleSceneUpdate() {
        let dt = timeSource.update()

        currentScene.rootNode.update(dt: dt)
        graphics.render(currentScene.rootNode)
    }

    func handleTransitionUpdate() {
        guard let transition = currentTransition else {
            return
        }

        let dt = timeSource.update()
        transition.update(dt: dt)

        if transition.isCompleted {
            if let nextScene = nextScene {
                // We finished a transition between scenes. Seat the next scene as current:
                self.currentScene = nextScene
                self.nextScene = nil
            } else {
                // We finished a transition between nodes within the same scene.
                // Update scene's root node and continue displaying the scene:
                self.currentScene.rootNode = transition.dest
            }

            // In either case, delete the transition so we render
            // currentScene.rootNode from the next frame:
            self.currentTransition = nil

            graphics.render(currentScene.rootNode)

            graphics.vSyncHandler = { [unowned self] in
                self.handleSceneUpdate()
            }
        } else {
            // Transition is ongoing...

            graphics.render(transition)
        }
    }

    func transition(to scene: Scene, effect: Transition.Effect = .sequentialFade, duration: TimeInterval) {
        guard currentTransition == nil else {
            return // Already in progress, ignore (log?)
        }

        let transition = Transition(source: currentScene.rootNode, dest: scene.rootNode, duration: duration, effect: effect)
        self.nextScene = scene
        self.currentTransition = transition

        graphics.vSyncHandler = { [unowned self] in
            self.handleTransitionUpdate()
        }
    }

    // MARK: -

    private func loadScene(name: String, completion: @escaping ((Scene) -> Void), failure: @escaping ((Error) -> Void) = defaultFailureHandler) {

        loadSceneManifest(name: name).then { [unowned self](manifest) -> (Promise<Void>) in

            return self.preloadSceneResources(from: manifest)

        }.then { (_) -> (Promise<Scene>) in

            return self.loadSceneContents(name: name)

        }.then { (scene) -> (Void) in

            completion(scene)

        }.catch { (error) in
            failure(error)
        }
    }

    private func onLoadScene(_ scene: Scene) {
        /*
         If the scene has a node with a player character controller component,
         discover game controllers.
         */
        self.gameControllers = GCController.controllers()

        for (index, controller) in gameControllers.enumerated() {
            controller.controllerPausedHandler = { (_) in
                self.togglePauseGame()
            }
            guard let player = Player(rawValue: index) else {
                continue
            }

            if let gamepad = controller.extendedGamepad {
                self.setupValueChangedHandlers(for: gamepad, for: player)

            } else if let microGamepad = controller.microGamepad {
                self.setupValueChangedHandlers(for: microGamepad, for: player)
            }
        }
    }

    private func togglePauseGame() {
        // TODO: implement
    }

    private func loadSceneManifest(name: String) -> Promise<SceneManifest> {
        let promise = Promise<SceneManifest>(in: .background) { [unowned self](resolve, reject) in
            guard let path = self.bundle.path(forResource: name, ofType: .sceneManifestFileExtension) else {
                throw RuntimeError.fileNotFound(fileName: name, type: .sceneManifest, bundleIdentifier: self.bundle.bundleIdentifier)
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

    private func preloadSceneResources(from manifest: SceneManifest) -> Promise<Void> {
        return graphics.preloadSceneResources(from: manifest, bundle: self.bundle)
    }

    private func loadSceneContents(name: String) -> Promise<Scene> {
        let promise = Promise<Scene>(in: .background) { [unowned self](resolve, reject) in
            guard let path = self.bundle.path(forResource: name, ofType: .sceneDataFileExtension) else {
                throw RuntimeError.fileNotFound(fileName: name, type: .sceneData, bundleIdentifier: self.bundle.bundleIdentifier)
            }
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let scene = try JSONDecoder().decode(Scene.self, from: data)
                resolve(scene)
            } catch {
                reject(error)
            }
        }
        return promise
    }

    private func registerCustomCoders() {
        // Event types:
        Container.register(PointInputEvent.self)
        Container.register(AnimationCompleteEvent.self)
        Container.register(MessageReceivedEvent.self)

        // Action types:
        Container.register(StateTransitionAction.self)
        Container.register(SceneTransitionAction.self)
        Container.register(SendMessageAction.self)
        Container.register(RemoveNodeAction.self)

        // Component types:
        Container.register(StateMachineComponent.self)
        Container.register(HitBoxComponent.self)
    }
}

// MARK: - Supporting Extensions

private extension String {

    static let sceneDataFileExtension = "scenedata"
    static let sceneManifestFileExtension = "scenemanifest"
}
