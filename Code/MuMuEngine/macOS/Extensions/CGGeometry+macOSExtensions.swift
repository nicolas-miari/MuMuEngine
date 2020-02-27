//
//  CGGeometry+Extensions.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/12.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

extension NSCoder {

    static func cgPoint(for string: String) -> CGPoint {
        return NSPointFromString(string)
    }

    static func cgSize(for string: String) -> CGSize {
        return NSSizeFromString(string)
    }

    static func cgRect(for string: String) -> CGRect {
        return NSRectFromString(string)
    }
}
