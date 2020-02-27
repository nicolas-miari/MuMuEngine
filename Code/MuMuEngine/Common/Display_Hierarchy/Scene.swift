//
//  Scene.swift
//  TestbedApp(macOS)
//
//  Created by Nicolás Miari on 2019/04/01.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

public class Scene: Codable, Equatable {

    public static func == (lhs: Scene, rhs: Scene) -> Bool {
        return lhs === rhs
    }

    public var name: String

    let clearColor: Color

    public var rootNode: Node

    public var nextRootNode: Node?

    /**
     - todo: Decide where to define the default value for the duration, so it
     can be mostly omitted for brevity _and_ consistency.
     */
    func transitionRoot(to nextRoot: Node, effect: Transition.Effect, duration: TimeInterval = 1.0) {
        self.nextRootNode = nextRoot

    }

    public init() {
        self.name = "Empty"
        self.clearColor = Color(red: 1, green: 0, blue: 1, alpha: 1)
        self.rootNode = Node()
        rootNode.name = "Root"
        rootNode.setAsRootNode(of: self)
    }

    // MARK: -

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try values.decode(String.self, forKey: .name)
        self.clearColor = try values.decode(Color.self, forKey: .clearColor)
        self.rootNode = try values.decode(Node.self, forKey: .rootNode)
        rootNode.setAsRootNode(of: self)
        rootNode.clearColor = clearColor
    }
}

/**
 Contains a list of all resource dependencies that sould be loaded before the
 associated scene can be successfully instantiated.
 */
struct SceneManifest: Codable {

    let textureAtlasNames: [String]

    let animationNames: [String]

    let blueprintNames: [String]

    init(atlasNames: [String] = [], animationNames: [String] = [], blueprintNames: [String] = []) {
        self.textureAtlasNames = atlasNames
        self.animationNames = animationNames
        self.blueprintNames = blueprintNames
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            self.textureAtlasNames = (try container.decodeIfPresent([String].self, forKey: .textureAtlasNames)) ?? []
            self.animationNames = (try container.decodeIfPresent([String].self, forKey: .animationNames)) ?? []
            self.blueprintNames = (try container.decodeIfPresent([String].self, forKey: .blueprintNames)) ?? []
        } catch {
            throw error
        }
    }
}

