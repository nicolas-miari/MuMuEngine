//
//  MainViewController.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/30.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import Cocoa

/**
 Game is bootstrapped in `viewDidLoad()`.
 */
public class MainViewController: NSViewController {

    override public var preferredContentSize: NSSize {
        set {
            // Ignore
        }
        get {
            return Runtime.shared.viewSize
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    public override func viewWillAppear() {
        super.viewWillAppear()

        guard let scaleFactor = view.window?.backingScaleFactor else {
            fatalError("Window Unavailable")
        }
        do {
            try Runtime.start(options: [.scaleFactor: scaleFactor], failureHandler: {(error) in
                NSAlert(error: error).runModal()
            })

            let graphicsView = Runtime.shared.view
            graphicsView.displayIfNeeded()
            
            self.view.addSubview(graphicsView)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
