//
//  MainViewController.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/30.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale

        // Initialize graphics API and pass it to the runtime, starting it

        do {
            let options: [BootstrapOptionKey: Any] = [
                .forceViewSize: screenSize,
                .scaleFactor: scale
            ]

            try Runtime.start(options: options)

            let graphicsView = Runtime.shared.view

            graphicsView.isUserInteractionEnabled = false
            self.view.addSubview(graphicsView)
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [unowned self] in
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
