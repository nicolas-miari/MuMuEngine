//
//  Renderer.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/31.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 The renderer for a game editor canvas only needs to draw basic textured geometry, without
 the need of composition, transitions or other multi-pass special effects.
 */
public protocol BasicRenderer {
    func render(_ node: Node)
}

/**
 The renderer for the exported game needs to be able to draw the gradual transition between
 app scenes using various visual effects (fade, cross-dissolve, etc.).
 */
internal protocol CombiningRenderer: BasicRenderer {
    func blend(sourceNode: Node, destNode: Node, effect: Transition.Effect, progress: Float)
}
