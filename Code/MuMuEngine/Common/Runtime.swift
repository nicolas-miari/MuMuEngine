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

    let graphics: GraphicsAPI

    let timeSource: TimeSource

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

    // MARK: - Initialization

    /**
     - parameter api: For dependency injection in unit tests. On normal
     execution, leave empty and the default value of `nil` signals instantiating
     the API specified in the configuration file.
     */
    private init(api: GraphicsAPI, timeSource: TimeSource) {
        self.graphics = api
        self.timeSource = timeSource
        playerControllerStates[.player1] = PlayerControllerState()
    }

    private init() {
        self.graphics = EmptyGraphicsApi()
        self.timeSource = EmptyTimesource()
    }

    static func start(options: GameConfiguration, ready: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) throws {

        let api = try options.createGraphicsApi()
        let timeSource = options.createTimeSource()

        self.shared = Runtime(api: api, timeSource: timeSource)

        shared.registerCustomCoders()

        // Attempt loading inital scene

    }

    /*
    static func start(options: [BootstrapOptionKey: Any]? = nil, readyHandler: (() -> Void)? = nil, failureHandler: @escaping ((Error) -> Void) = defaultFailureHandler) throws {
        let bootstrap = try Bootstrap(options: options)

        // Allocate singleton
        self.shared = Runtime(api: bootstrap.graphicsAPI)

        //
        shared.registerCustomCoders()

        // Attempt loading initial scene:
        let bundle = options?[.bundle] as? Bundle ?? .main
        shared.loadScene(name: bootstrap.initialSceneName, bundle: bundle,  completion: { () -> Runtime.LoadSceneResponse in
            // Success; run scene and notify observer:
            readyHandler?()
            return .runImmediately

        }, failure: {(error) in
            DispatchQueue.main.async {
                failureHandler(error)
            }
        })
    }*/

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
    }

    /**
     Loads the scene with the specified name from the resource bundle asynchronously. On completion, the passed
     closure is executed. Return the appropriate value to signal to the runtime how to proceed with regards to
     the just loaded scene.
     */
    func loadScene(name: String, bundle: Bundle = .main, completion: @escaping (() -> LoadSceneResponse), failure: @escaping ((Error) -> Void) = defaultFailureHandler) {
        loadScene(name: name, bundle: bundle, completion: { (scene) in
            switch completion() {
            case .runImmediately:
                self.run(scene)

            case .runAfterTransition(let effect, let duration):
                self.transition(to: scene, effect: effect, duration: duration)
            }
        }, failure: failure)
    }

    /**
     Loads the scene with the specified name from the resource bundle asynchronously. On completion, the specified
     action is performed.
     */
    func loadScene(name: String, bundle: Bundle = .main, onCompletion: LoadSceneResponse, failure: @escaping ((Error) -> Void) = defaultFailureHandler) {
        loadScene(name: name, completion: { () -> Runtime.LoadSceneResponse in
            return onCompletion
        }, failure: failure)
    }

    /**
     */
    func runScene(name: String, bundle: Bundle? = nil, loadCompletion: (() -> Void)? = nil, failure: @escaping ((Error) -> Void) = defaultFailureHandler) throws {
        // Instantiate the scene with the given name from the bundled resources.

        loadScene(name: name, bundle: (bundle ?? .main),  completion: { (_) in
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

    // MARK: - Controller Input

    func setPadAxis(_ controllerAxis: ControllerAxis, to value: Float, for player: Player) {
        switch controllerAxis {
        case .x:
            playerControllerStates[player]?.xAxis = value
        case .y:
            playerControllerStates[player]?.yAxis = value
        }
    }

    func setButton(_ controllerButton: ControllerButton, pressed: Bool, for player: Player) {
        switch controllerButton {
        case .a:
            playerControllerStates[player]?.buttonA = pressed
        case .b:
            playerControllerStates[player]?.buttonB = pressed
        case .x:
            playerControllerStates[player]?.buttonX = pressed
        case .y:
            playerControllerStates[player]?.buttonY = pressed
        }
    }

    // MARK: -

    private func loadScene(name: String, bundle: Bundle = .main, completion: @escaping ((Scene) -> Void), failure: @escaping ((Error) -> Void) = defaultFailureHandler) {
        loadSceneManifest(name: name, bundle: bundle, completion: { [unowned self](manifest) in
            self.graphics.preloadSceneResources(from: manifest, bundle: bundle, completion: { [unowned self] in

                // Load Scene Data Proper
                guard let path = bundle.path(forResource: name, ofType: sceneDataFileExtension) else {
                    let error = RuntimeError.fileNotFound(fileName: name, type: .sceneData, bundleIdentifier: bundle.bundleIdentifier)
                    return failure(error)
                }
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    let scene = try JSONDecoder().decode(Scene.self, from: data)

                    completion(scene)
                    self.onLoadScene(scene)
                } catch {
                    failure(error) // todo: Add a corrupted json scene to cover this path
                }
            }, failure: { (error) in
                failure(error)
            })
        }, failure: { (error) in
            failure(error)
        })
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

    private func loadSceneManifest(name: String, bundle: Bundle = .main, completion: @escaping ((SceneManifest) -> Void), failure: @escaping ((Error) -> Void) = defaultFailureHandler) {
        guard let path = bundle.path(forResource: name, ofType: sceneManifestFileExtension) else {
            let error = RuntimeError.fileNotFound(fileName: name, type: .sceneManifest, bundleIdentifier: bundle.bundleIdentifier)
            return failure(error)
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let manifest = try JSONDecoder().decode(SceneManifest.self, from: data)

            completion(manifest)
        } catch {
            failure(error) // todo: Add a corrupted json scene manifest to cover this path
        }
    }

    private func registerCustomCoders() {
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
}

let sceneDataFileExtension = "scenedata"
let sceneManifestFileExtension = "scenemanifest"
