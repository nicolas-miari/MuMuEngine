//
//  System.swift
//  MuMuEngine-macOS
//
//  Created by Nicolás Miari on 2020/04/10.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//
#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

/**
 Provides an interface for querying platform and hardware-specific attributes
 necessary to bootstrap and run the engine.
 */
class System {

    static var viewPointSize: CGSize? {
        #if os(iOS) || os(tvOS)
        return UIScreen.main.bounds.size
        #elseif os(macOS)
        // macOS apps have a predetermined, fixed window size set in the game
        // configuration file.
        return nil
        #else
        fatalError("Unsupported Platform")
        #endif
    }

    static var viewNativeSize: CGSize? {
        #if os(iOS) || os(tvOS)
        return UIScreen.main.nativeBounds.size
        #elseif os(macOS)
        // macOS apps have a predetermined, fixed window size set in the game
        // configuration file.
        return nil
        #else
        fatalError("Unsupported Platform")
        #endif
    }

    static var viewNativeScale: CGFloat {
        #if os(iOS) || os(tvOS)
        return UIScreen.main.nativeScale
        #elseif os(macOS)
        return NSScreen.main?.backingScaleFactor ?? 1
        #else
        fatalError("Unsupported Platform")
        #endif
    }
}

