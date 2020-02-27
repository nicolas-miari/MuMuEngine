//
//  Runtime+GameController.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/25.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation
import GameController

// MARK: - Player Constants

enum Player: Int {
    case player1
    case player2
    case player3
    case player4
}

// MARK: - Key Constants

enum KeyInput: Int {
    case a = 0
    case x = 7
    case b = 11
    case y = 16

    case enter = 36
    case space = 49
    case escape = 53

    case arrowLeft = 123
    case arrowRight = 124
    case arrowDown = 125
    case arrowUp = 126

    init?(keyCode: Int) {
        self.init(rawValue: keyCode)
    }

    /*
     https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/EventArchitecture/EventArchitecture.html#//apple_ref/doc/uid/10000060i-CH3-SW10
     */
}

// MARK: - Controller Input Constants

enum ControllerAxis {
    case x
    case y
}

enum ControllerButton {
    case a
    case b
    case x
    case y
}

// MARK: - Unified Player Input Handling

/**
 Holds the user's input for a given player between frames. Abstracts the actual input mechanism: physical controllers,
 virtual controls on screen (iOS), keyboard (macOS) so the game logic can work on this unified model.
 */
struct PlayerControllerState {
    /**
     Value is `-1` when the "left" button is pressed or analog stick is tilted fully to the left, `+1` when the "right"
     button is pressed or the analog stick is tilted fully to the right, and `0` is neither button is pressed or the
     stick is in the neutral position. For keyboard input, the "left" key alone results in `-1`, the "right" key in `+1`,
     and neither key in `0`. Presseing both keys results in undefined behaviour.
     */
    var xAxis: Float = 0

    /**
     Value is `-1` when the "down" button is pressed or analog stick is tilted fully to the bottom, `+1` when the "up"
     button is pressed or the analog stick is tilted fully to the top, and `0` is neither button is pressed or the stick
     is in the neutral position. For keyboard input, the "up" arrow key alone results in `+1`, the "down" arrow key in
     `-1`, and neither key in `0`. Presseing both keys results in undefined behaviour.
     */
    var yAxis: Float = 0

    /**
     Value is `true` when the button is depressed, `false` when released.
     */
    var buttonX: Bool

    /**
     Value is `true` when the button is depressed, `false` when released.
     */
    var buttonY: Bool

    /**
     Value is `true` when the button is depressed, `false` when released.
     */
    var buttonA: Bool

    /**
     Value is `true` when the button is depressed, `false` when released.
     */
    var buttonB: Bool

    init() {
        self.xAxis = 0.0
        self.yAxis = 0.0
        self.buttonX = false
        self.buttonY = false
        self.buttonA = false
        self.buttonB = false
    }
}

extension Runtime {

    // MARK: Physical Controllers

    /**
     Configures micropad (Dpad, A button, X button).
     */
    func setupValueChangedHandlers(for micropad: GCMicroGamepad, for player: Player ) {
        micropad.buttonA.valueChangedHandler = { (_, _, pressed) -> Void in
            Runtime.shared.setButton(.a, pressed: pressed, for: player)
        }
        micropad.buttonX.valueChangedHandler = { (_, _, pressed) -> Void in
            Runtime.shared.setButton(.x, pressed: pressed, for: player)
        }
        micropad.dpad.xAxis.valueChangedHandler = {(_, value) -> Void in
            Runtime.shared.setPadAxis(.x, to: value, for: player)
        }
        micropad.dpad.yAxis.valueChangedHandler = {(_, value) -> Void in
            Runtime.shared.setPadAxis(.y, to: value, for: player)
        }
    }

    /**
     Configures standard gamepad (Dpad, A button, B button, X button, Y button).
     */
    func setupValueChangedHandlers(for pad: GCExtendedGamepad, for player: Player ) {
        pad.buttonA.valueChangedHandler = { (_, _, pressed) -> Void in
            Runtime.shared.setButton(.a, pressed: pressed, for: player)
        }
        pad.buttonB.valueChangedHandler = { (_, _, pressed) -> Void in
            Runtime.shared.setButton(.a, pressed: pressed, for: player)
        }
        pad.buttonX.valueChangedHandler = { (_, _, pressed) -> Void in
            Runtime.shared.setButton(.x, pressed: pressed, for: player)
        }
        pad.buttonY.valueChangedHandler = { (_, _, pressed) -> Void in
            Runtime.shared.setButton(.x, pressed: pressed, for: player)
        }
        pad.dpad.xAxis.valueChangedHandler = {(_, value) -> Void in
            Runtime.shared.setPadAxis(.x, to: value, for: player)
        }
        pad.dpad.yAxis.valueChangedHandler = {(_, value) -> Void in
            Runtime.shared.setPadAxis(.y, to: value, for: player)
        }
    }

    // MARK: Keyboard Mapped
    
    /**
     Keyboard input is always player 1 (index 0)
     */
    func handleKey(down pressed: Bool, code: Int) {
        guard let input = KeyInput(keyCode: code), playerControllerStates.count > 0 else {
            return
        }
        switch input {
        case .a, .space:
            setButton(.a, pressed: pressed, for: .player1)
        case .b, .enter:
            setButton(.b, pressed: pressed, for: .player1)
        case .x:
            setButton(.x, pressed: pressed, for: .player1)
        case .y:
            setButton(.y, pressed: pressed, for: .player1)
        case .arrowLeft:
            setPadAxis(.x, to: pressed ? -1 : 0, for: .player1)
        case .arrowRight:
            setPadAxis(.x, to: pressed ? +1 : 0, for: .player1)
        case .arrowUp:
            setPadAxis(.y, to: pressed ? +1 : 0, for: .player1)
        case .arrowDown:
            setPadAxis(.y, to: pressed ? -1 : 0, for: .player1)
        case .escape:
            break
        }
    }
}
