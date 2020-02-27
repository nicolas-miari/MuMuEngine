//
//  WindowController.swift
//  TestbedApp(macOS)
//
//  Created by Nicolás Miari on 2019/04/02.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.title = {
            guard let dictionary = Bundle.main.infoDictionary else {
                return "Unknown"
            }
            guard let title = dictionary[kCFBundleNameKey as String] as? String else {
                return "Unknown"
            }
            return title
        }()
    }
}
