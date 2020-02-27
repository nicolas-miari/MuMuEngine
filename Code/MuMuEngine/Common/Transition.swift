//
//  Transition.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/02.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Stores information about one node transition in progress.

 - todo: Clean up.
 */
class Transition {
    enum Effect: String, Codable {
        case sequentialFade
        case crossDissolve
    }

    let source: Node
    let dest: Node

    let effect: Effect

    let totalDuration: TimeInterval

    private(set) var ellapsedTime: TimeInterval

    /**
     Progresses from 0.0 at the beginning of the transition to 1.0 when it is
     completed.
     */
    var progress: Double {
        return (ellapsedTime / totalDuration)
    }

    var isCompleted: Bool {
        return (ellapsedTime >= totalDuration)
    }

    init(source: Node, dest: Node, duration: TimeInterval, effect: Effect = .sequentialFade) {
        self.source = source
        self.dest = dest
        self.totalDuration = duration
        self.effect = effect
        self.ellapsedTime = 0.0
    }

    /**
     Advances transition progression and also propagates the time update to both
     source and des nodes.
     */
    func update(dt: TimeInterval) {
        ellapsedTime += dt
        source.update(dt: dt)
        dest.update(dt: dt)
    }
}

protocol NodeTransition {

    init(source: Node, dest: Node, duration: TimeInterval)

    func update(dt: TimeInterval)
}

struct SequentialFade: NodeTransition {

    init(source: Node, dest: Node, duration: TimeInterval) {

    }

    func update(dt: TimeInterval) {

    }
}
