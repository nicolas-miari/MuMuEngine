//
//  Renderer.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/31.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 The renderer for a **game editor canvas** (editing area) only needs to draw
 basic textured geometry, without the need of composition, transitions or other
 multi-pass special effects.
 */
public protocol BasicRenderer {
    /**
     Renders the passed node into the main view.
     */
    func render(_ node: Node)
}

/**
 The renderer for the exported game needs to be able to draw the gradual
 transition between app scenes using various visual effects (fade,
 cross-dissolve, etc.).
 */
internal protocol CombiningRenderer: BasicRenderer {

    /**
     Renders the transition between `sourceNode` and `destNode` using the
     specified visual effect, at the specified percentage of time progress.

     - parameter sourceNode: The node rendered before and at the beginning of the
       transition.
     - parameter destNode: The node rendered at the end of the transition, and
       thereafter.
     - parameter effect: The visual effect used to transition between `sourceNode` and
       `destNode`.
     - parameter progress: A floating-point value representing how much the
       transition has progressed (0.0 representing the beginning, and 1.0 the
       completion) in order to determine how to render it during the current
       frame. For example, if `effect` is "cross dissolve" and progress is
       `0.25`, `sourceNode` will be rendered at 75% opacity, and `destNode` will
       be rendered at 25% opacity on top. Typically, in order to _animate_ a
       transition, you will increase the progress value progressively each
       frame, and call this method with the same nodes and effect, until
       `progress` reaches `1.0`.
     */
    func blend(sourceNode: Node, destNode: Node, effect: Transition.Effect, progress: Float)
}
