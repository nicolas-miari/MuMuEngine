//
//  Easing.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/12.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Based on: https://github.com/warrenm/AHEasing/blob/master/AHEasing/easing.c
 */

enum EasingType {
    case none
    case easeIn
    case easeOut
    case easeInOut
}

enum EasingDegree {
    case quadratic
    case cubic
    case quartic
}

func ease(_ p: Float, easing: EasingType) -> Float {
    switch easing {
    case .none:
        return p

    case .easeIn:
        // (quadratic)
        return (p * p)

    case .easeOut:
        // (quadratic)
        return -(p * (p - 2))

    case .easeInOut:
        // (quadratic)
        if p < 0.5 {
            return 2 * p * p
        } else {
            return ((-2 * p * p) + (4 * p) - 1)
        }
    }

    // TODO: Implement cubic, quartic, etc.
}
