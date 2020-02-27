//
//  RuntimeError.swift
//  MuMuEngineTests
//
//  Created by Nicolás Miari on 2019/04/03.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

enum ResourceFileType {
    case gameConfiguration
    case atlasMetadata
    case sceneManifest
    case sceneData
    case animationData
    case blueprintData

    var localizedDescription: String {
        switch self {
        case .gameConfiguration:
            return "Game Configuration"
        case .atlasMetadata:
            return "Atlas Metadata"
        case .sceneManifest:
            return "Scene Manifest"
        case .sceneData:
            return "Scene Data"
        case .animationData:
            return "Animation Data"
        case .blueprintData:
            return "Blueprint Data"
        }
    }
}

enum RuntimeError: Error {

    // MARK: - Runtime Initialization

    case failedToInitializeGraphicsDriver(customMessage: String)

    case failedToInitializeGraphicsDriverResource(customMessage: String)

    case scaleFactorUnspecified

    case fileNotFound(fileName: String, type: ResourceFileType, bundleIdentifier: String?)

    case configurationKeyMissing(key: String, fileName: String?)

    case unsupportedGraphicsAPI(apiName: String, fileName: String?)

    case configurationFileCorrupted(fileName: String?)

    // MARK: - Resource Loading

    case animationNotLoaded(animationName: String)

    case blueprintNotLoaded(blueprintName: String)

    case failedToLoadTextureAtlasTexture(name: String)

    case failedToLoadTextureAtlasDescriptor(name: String)

    case textureAtlasNotLoaded(atlasName: String)

    case spriteNotFoundInAtlas(spriteName: String, atlasName: String)

    case componentIsCorrupted(nodeName: String)

    case dataIsCorrupted(type: String)

    case unsupportedComponent(type: String)

    case concurrentLoadSceneRequests
}

// MARK: - Use-Facing Messages

extension RuntimeError: LocalizedError {

    var errorDescription: String? {
        switch self {

        case .failedToInitializeGraphicsDriver(let customMessage):
            return customMessage

        case .failedToInitializeGraphicsDriverResource(let customMessage):
            return customMessage

        case .scaleFactorUnspecified:
            return "Scale Factor Is Not Specified."

        case .fileNotFound(let fileName, let fileType, let bundleIdentifier):
            let identifier = bundleIdentifier ?? "unknown"
            return "\(fileType.localizedDescription) File '\(fileName)' Not Found in Bundle '\(identifier)'."

        case .configurationFileCorrupted(let fileName):
            let file: String = fileName ?? .defaultConfigFileName
            return "Configuration File '\(file)' Is Corrupted."

        case .configurationKeyMissing(let key, let fileName):
            let file: String = fileName ?? .defaultConfigFileName
            return "Configuration File '\(file)' Is Missing Required Key '\(key)'."

        case .unsupportedGraphicsAPI(let apiName, let fileName):
            let file: String = fileName ?? .defaultConfigFileName
            return "Configuration File '\(file)' Specifies the Unsupported Graphics API '\(apiName)'."

        case .textureAtlasNotLoaded(let atlasName):
            return "Texture Atlas '\(atlasName)' Has Not Been Loaded."

        case .failedToLoadTextureAtlasTexture(let name):
            return "Failed to load texture atlas texture: \(name)"

        case .failedToLoadTextureAtlasDescriptor(let name):
            return "Failed to load texture atlas descriptor: \(name)"

        case .blueprintNotLoaded(let blueprintName):
            return "Blueprint '\(blueprintName)' Has Not Been Loaded."

        case .animationNotLoaded(let animationName):
            return "Animation '\(animationName)' Has Not Been Loaded."

        case .spriteNotFoundInAtlas(let spriteName, let atlasName):
            return "Sprite '\(spriteName)' Was Not Found in Texture Atlas '\(atlasName)'."

        case .componentIsCorrupted(let nodeName):
            return "Corrupted Component Found in Nide '\(nodeName)'."

        case .dataIsCorrupted(let type):
            return "Data is corrupted (\(type))"
    
        case .unsupportedComponent(let type):
            return "Unsupported Component Type: '\(type)'."

        case .concurrentLoadSceneRequests:
            return "Attempted to load multiple scenes concurrently."
        }
    }
}
