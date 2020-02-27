//
//  Platform.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/30.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import Foundation

#if os(macOS)
    import Cocoa
    typealias View = NSView

    var screenSize: CGSize {
        return NSScreen.main?.frame.size ?? .zero
    }

#elseif os(iOS)
    import UIKit
    typealias View = UIView

    var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
#endif
