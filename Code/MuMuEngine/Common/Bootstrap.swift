//
//  Bootstrap.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/02.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#endif

enum BootstrapOptionKey: String {
    /**
     Specified the bundle from which to query file names (to support the injection of the test bundle
     during unit testing).
     */
    case bundle

    /**
     */
    case fileName

    /**
     Causes the bootstrap to ignore any window size specified in the configuration file and use the
     passed value instead. Used on the iOS platform, where the app is always full-screen and the screen
     size is device-dependant (i.e., unknown until launch). On macOS, the app window size must be specified
     in the configuration file.
     */
    case forceViewSize

    /**
     */
    case scaleFactor
}

/**
 */
extension String {
    static let initialSceneName: String = "InitialSceneName"
    static let windowSize: String = "WindowSize"
    static let apiName: String = "GraphicsAPI"
}

/**
 Structure containing all the information necessary to configure the game runtime on startup.
 On instantiation, all properties are read (by default) from the bundled GameInfo.plist file.
 */
struct Bootstrap {

    private enum API: String {
        case metal = "Metal"
    }

    let initialSceneName: String

    let viewSize: CGSize

    let graphicsAPI: GraphicsAPI

    init(options: [BootstrapOptionKey: Any]? = nil) throws {

        let fileName = options?[.fileName] as? String
        let bundle = options?[.bundle] as? Bundle

        let dictionary = try loadConfigurationDictionary(name: fileName, bundle: bundle)

        guard let initialSceneName = dictionary["InitialSceneName"] as? String else {
            throw RuntimeError.configurationKeyMissing(key: .initialSceneName, fileName: fileName)
        }
        self.initialSceneName = initialSceneName

        if let viewSize = options?[.forceViewSize] as? CGSize {
            // Use custom view size (override)
            self.viewSize = viewSize
        } else {
            // Use window size in configuration file (default)
            guard let viewSizeString = dictionary["WindowSize"] as? String else {
                throw RuntimeError.configurationKeyMissing(key: .windowSize, fileName: fileName)
            }
            self.viewSize = NSCoder.cgSize(for: viewSizeString)
        }

        guard let apiName = dictionary["GraphicsAPI"] as? String else {
            throw RuntimeError.configurationKeyMissing(key: .apiName, fileName: fileName)
        }
        guard let api = API(rawValue: apiName) else {
            throw RuntimeError.unsupportedGraphicsAPI(apiName: apiName, fileName: fileName)
        }
        guard let scaleFactor = options?[.scaleFactor] as? CGFloat else {
            throw RuntimeError.scaleFactorUnspecified
        }

        switch api {
        case .metal:
            self.graphicsAPI = try MetalGraphicsAPI(viewSize: viewSize, scaleFactor: scaleFactor)
            // (...add more cases if needed...)
        }
    }
}

// MARK: -

private func loadConfigurationDictionary(name: String? = nil, bundle: Bundle? = nil) throws -> [String: Any] {
    let resolvedBundle = bundle ?? Bundle.main
    let resolvedFileName = name ?? .defaultConfigFileName

    guard let path = resolvedBundle.path(forResource: resolvedFileName, ofType: "plist") else {
        throw RuntimeError.fileNotFound(fileName: resolvedFileName, type: .gameConfiguration, bundleIdentifier: resolvedBundle.bundleIdentifier ?? "")
    }
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)

    let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)

    guard let dictionary = object as? [String: Any] else {
        throw RuntimeError.configurationFileCorrupted(fileName: name)
    }
    return dictionary
}

extension String {
    static let defaultConfigFileName = "GameInfo"
}
