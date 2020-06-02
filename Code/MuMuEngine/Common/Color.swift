//
//  Color.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/18.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Platform-agnostic color type.
 */
public struct Color: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}
