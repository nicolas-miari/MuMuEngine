//
//  SystemAlert.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/18.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import UIKit

func systemAlert(title: String, message: String) {
    DispatchQueue.main.async {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        guard let window = UIApplication.shared.keyWindow else {
            fatalError("App Has No Key Window!")
        }
        guard let viewController = window.rootViewController else {
            fatalError("App Has No Root View Controller!")
        }
        viewController.present(alert, animated: true, completion: nil)
    }
}
