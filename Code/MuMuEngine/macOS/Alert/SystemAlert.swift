//
//  SystemAlert.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/18.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Cocoa

func systemAlert(title: String, message: String) {
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}
