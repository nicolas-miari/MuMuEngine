//
//  Runtime+Touch.swift
//  MuMuEngine-iOS
//
//  Created by Nicolás Miari on 2020/06/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

extension Runtime {

    func touchBegan(at point: CGPoint) {
           let target = currentScene.rootNode.hitTest(point: point)

           target?.handlePointInput(.touchDown)

           self.lastNodeHit = target
       }

       func touchMoved(to point: CGPoint) {
           let target = currentScene.rootNode.hitTest(point: point)

           if target != lastNodeHit {
               lastNodeHit?.handlePointInput(.dragExit)
               target?.handlePointInput(.dragEnter)
           }

           self.lastNodeHit = target
       }

       func touchEnded(at point: CGPoint) {
           let target = currentScene.rootNode.hitTest(point: point)

           if target != lastNodeHit {
               lastNodeHit?.handlePointInput(.touchUpOutside)
           } else {
               lastNodeHit?.handlePointInput(.touchUpInside)
           }
           lastNodeHit = nil
       }


}
