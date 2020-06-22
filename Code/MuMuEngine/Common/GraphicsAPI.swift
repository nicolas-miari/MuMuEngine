//
//  GraphicsAPI.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/30.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import CoreGraphics
import Foundation

/**
 Defines the interface that any concrete API classs should implement.

 The engine at large abstracts the API's specifics away by dealing exclusively
 with this interface. This decoupling allows (among other things) for an
 eventual transition into another API with the least code modification.
 */
protocol GraphicsAPI: AnyObject {
    /**
     The name of the API, used for displaying in the debug console or in the
     localized descriptions of thrown errors (never shown to the game players).
     */
    var name: String { get }

    /**
     The view to which the graphics content is rendered (provided by the
     operating system). The actual type is platform-dependant.

     Consider making it an **associated type**.
     */
    var view: View { get }

    /**
     */
    var backingScaleFactor: CGFloat { get }

    /**
     A block that is executed before each redraw, useful for synchronizing frame
     updates.
     */
    var vSyncHandler: (() -> Void)? { get set }

    /**
     Preloads the specified resources asynchronously from adequately named files
     assumed to be present in the bundle.
     */
    func preloadSceneResources(from manifest: SceneManifest, bundle: Bundle, completion: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) -> Void

    /**
     */
    func preloadSceneResources(from manifest: SceneManifest, bundle: Bundle) throws -> Promise<Void>

    /**
     Returns a mesh resource containing all necessary information to draw the
     specified sprite using the API's rendering capabilities (the actual type is
     API-specific). The atlas must be already loaded before calling this method.

     - throws: If either the texture altas `atlasName` is not loaded and cached,
     or if it does not contain an entry named `name`.
     */
    func spriteComponent(name: String, inAtlas atlasName: String) throws -> TexturedMeshComponent

    /**
     Returns an array of **fresh copies** of the components contained in the
     specified **blueprint** (i.e., a reusable set of components that can be
     copied into one or more nodes, to avoid duplication within the scene data
     files). The blueprint must be already loaded before calling this method.

     - throws: If a blueprint by the specified name has not yet been loaded and
     cached.
     */
    func componentsFromBlueprint(name: String) throws -> [Component]

    /**
     Returns an **animation template**: an object describing a list of sprites
     and their corresponding order/duration for display in orchestrated, quick
     succession (flipbook animation). The inmutable template can then be used to
     create **animation sessions** (i.e., individual "runs" of the animation)
     during one state of a state machine. The animation template must have been
     loaded from file and cached before calling this method.

     - throws: If an animation by the specified name has not been yer loaded and
     cached.
     */
    func animation(name: String) throws -> Animation

    /**
     Renders a node and all its descendants.
     */
    func render(_ node: Node)

    /**
     Renders a transition between two nodes.
     */
    func render(_ transition: Transition)
}

// MARK: - Supporting Protocols

/**
 */
protocol TexturedMeshComponent {

    var name: String { get }

    var ownerName: String { get }

    var isFullyOpaque: Bool { get }

    var bounds: CGRect { get }
}

class EmptyGraphicsApi: GraphicsAPI {

    let name: String = "Empty"

    let view: View = View()

    var vSyncHandler: (() -> Void)?

    let backingScaleFactor: CGFloat = 1

    func preloadSceneResources(from manifest: SceneManifest, bundle: Bundle, completion: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) {
        failure(EmptyGraphicsApiError.unimplemented)
    }

    func preloadSceneResources(from manifest: SceneManifest, bundle: Bundle) throws -> Promise<Void> {
        throw EmptyGraphicsApiError.unimplemented
    }

    func spriteComponent(name: String, inAtlas atlasName: String) throws -> TexturedMeshComponent {
        throw EmptyGraphicsApiError.unimplemented
    }

    func componentsFromBlueprint(name: String) throws -> [Component] {
        throw EmptyGraphicsApiError.unimplemented
    }

    func animation(name: String) throws -> Animation {
        throw EmptyGraphicsApiError.unimplemented
    }

    func render(_ node: Node) {
    }

    func render(_ transition: Transition) {
    }
}

enum EmptyGraphicsApiError: Error {
    case unimplemented
}
