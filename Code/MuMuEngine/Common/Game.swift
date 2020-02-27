//
//  Game.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/26.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

class Game {

    let progress: Progress

    init() {
        self.progress = Progress()
    }
}

class Progress {

    var score: Int = 0
    var unlockedAchievements: [Achievement] = []
    var stage: Int = 0
}

class Achievement {
    enum Status {
        case locked(hidden: Bool)
        case unlocked
    }

    let name: String
    let description: String
    var status: Status

    init(name: String, description: String, status: Status) {
        self.name = name
        self.description = description
        self.status = status
    }
}

enum GameSaveStyle {
    case slot
    
}
