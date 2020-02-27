//
//  MainView.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/12.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import UIKit

class MainView: UIView {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let first = touches.first else { return }
        let location = first.location(in: self)

        Runtime.shared.touchBegan(at: convertToRuntimeCoordinates(location))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let first = touches.first else { return }
        let location = first.location(in: self)

        Runtime.shared.touchMoved(to: convertToRuntimeCoordinates(location))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let first = touches.first else { return }
        let location = first.location(in: self)

        Runtime.shared.touchEnded(at: convertToRuntimeCoordinates(location))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let first = touches.first else { return }
        let location = first.location(in: self)

        Runtime.shared.touchEnded(at: convertToRuntimeCoordinates(location))
    }

    private func convertToRuntimeCoordinates(_ location: CGPoint) -> CGPoint {
        return CGPoint(x: location.x - (bounds.width / 2), y: location.y - bounds.height / 2)
    }
}
