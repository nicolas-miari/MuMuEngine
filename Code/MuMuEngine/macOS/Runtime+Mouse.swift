//
//  Runtime+Mouse.swift
//  MuMuEngine-macOS
//
//  Created by Nicolás Miari on 2020/06/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

extension Runtime {

    func mouseMoved(to point: CGPoint) {
        guard let target = currentScene.rootNode.hitTest(point: point) else {
            return // Miss
        }
        if target != lastNodeHit {
            // Notify exit:
            lastNodeHit?.handlePointInput(.mouseExit)

            // Notify enter:
            target.handlePointInput(.mouseEnter)

            // Update node:
            self.lastNodeHit = target
        }
    }

    func mouseDown(at point: CGPoint) {
        guard let target = currentScene.rootNode.hitTest(point: point) else {
            return // Miss
        }
        self.lastNodeHit = target
        target.handlePointInput(.buttonDown)
    }

    func mouseUp(at point: CGPoint) {
        guard let target = currentScene.rootNode.hitTest(point: point) else {
            return // Miss
        }
        self.lastNodeHit = target

        target.handlePointInput(.buttonUp)
    }

    func mouseDragged(to point: CGPoint) {
        let target = currentScene.rootNode.hitTest(point: point)

        if target != lastNodeHit {
            lastNodeHit?.handlePointInput(.dragExit)
            target?.handlePointInput(.dragEnter)

            self.lastNodeHit = target
        }
    }

}
