//
//  MTLClearColor+Extensions.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/12.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Metal

public extension MTLClearColor {

    // Other colors: YAGNI
    
    static var opaqueBlack: MTLClearColor {
        return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    }

    static var opaqueWhite: MTLClearColor {
        return MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
    }

    internal init(color: Color) {
        self.init(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }
}

extension MTLClearColor: Equatable {
    public static func == (lhs: MTLClearColor, rhs: MTLClearColor) -> Bool {
        return ((lhs as MTLClearColor).red == (rhs as MTLClearColor).red)
    }
}
