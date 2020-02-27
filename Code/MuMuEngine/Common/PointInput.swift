//
//  InputAction.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/22.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

enum PointInput: String {

    // MARK: - macOS-specific

    case mouseEnter
    case mouseExit
    case buttonDown
    case buttonUp

    // MARK: - iOS-specific

    case touchDown
    case touchUpInside
    case touchUpOutside

    // MARK: - Common

    case dragEnter
    case dragExit
}
