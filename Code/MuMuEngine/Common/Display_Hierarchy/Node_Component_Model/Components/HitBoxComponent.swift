//
//  HitBoxComponent.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/08/22.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation
import CoreGraphics

class HitBoxComponent: Component {

    static var name: String = "HitBox"

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case rect
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rect = try container.decodeIfPresent(CGRect.self, forKey: .rect) ?? .null
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if rect != .null {
            try container.encode(rect, forKey: .rect)
        }
    }

    // MARK: -

    var rect: CGRect

    init(rect: CGRect) {
        self.rect = rect
    }

    func hitTest(_ point: CGPoint) -> Bool {
        return rect.contains(point)
    }

    func copy() -> Component {
        return HitBoxComponent(rect: self.rect)
    }
}
