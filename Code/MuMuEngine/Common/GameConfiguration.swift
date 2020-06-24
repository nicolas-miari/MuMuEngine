//
//  GameConfiguration.swift
//  MuMuEngine-macOS
//
//  Created by Nicolás Miari on 2020/04/10.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation
import CoreGraphics

/**
 Represents the contents of the GameConfiguration.json file.
 */
class GameConfiguration: Codable {

    /**
     The name of the first scene to load from the resources on app launch.
     */
    let initialSceneName: String

    /**
     The (fixed) size of the app's window (macOS only: on iOS, games run full-screen).
     */
    let windowSize: CGSize?

    /**
     Currently, only "Metal" is supported.
     */
    let graphicsApiName: String

    // MARK: -

    static func loadDefault() throws -> GameConfiguration {
        guard let url = Bundle.main.url(forResource: "GameConfiguration", withExtension: "json") else {
            throw GameConfigurationError.defaultResourceFileMissing
        }
        let data = try Data(contentsOf: url)
        let configuration = try JSONDecoder().decode(GameConfiguration.self, from: data)

        return configuration
    }

    func createGraphicsApi() throws -> GraphicsAPI {
        let screenSize: CGSize = try { () throws -> CGSize in
            if let size = System.viewPointSize {
                // (iOS)
                return size
            } else if let size = windowSize {
                // (macOS)
                return size
            } else {
                throw GameConfigurationError.windowSizeUnspecified
            }
        }()

        switch graphicsApiName {
        case .metal:
            return try MetalGraphicsAPI(viewSize: screenSize, scaleFactor: System.viewNativeScale)

        default:
            throw GameConfigurationError.unsupportedGraphicsApi
        }
    }

    func createTimeSource() -> TimeSource {
        return SystemTimeSource()
    }
}

// MARK: - Supporting Types

enum GameConfigurationError: Error {
    ///
    case defaultResourceFileMissing

    ///
    case unsupportedGraphicsApi

    ///
    case windowSizeUnspecified
}

extension String {
    static let metal = "Metal"
}
