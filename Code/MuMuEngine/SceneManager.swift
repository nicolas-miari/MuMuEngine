//
//  SceneManager.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2020/04/26.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Manages initialization of scenes from resource files and transitions between
 them.
 */
class SceneManager {

    /*
    func transitionToScene(name: String, bundle: Bundle, api: GraphicsAPI) {
        /*
         load manifest
         -> preload resources listed
         -> instantiate scene
         -> transition to it
         */
        loadSceneManifest(name: name, bundle: bundle).then { [unowned self](manifest) -> (Promise<Void>) in
            return try api.preloadSceneResources(from: manifest, bundle: bundle)
        }.then { () -> (Promise<Scene>) in

        }
    }*/
    
    /*
    private func loadScene(name: String, bundle: Bundle = .main, completion: @escaping ((Scene) -> Void), failure: @escaping ((Error) -> Void) = defaultFailureHandler) {
        loadSceneManifest(name: name, bundle: bundle, completion: { [unowned self](manifest) in
            self.graphicsAPI.preloadSceneResources(from: manifest, bundle: bundle, completion: { [unowned self] in

                // Load Scene Data Proper
                guard let path = bundle.path(forResource: name, ofType: sceneDataFileExtension) else {
                    let error = RuntimeError.fileNotFound(fileName: name, type: .sceneData, bundleIdentifier: bundle.bundleIdentifier)
                    return failure(error)
                }
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    let scene = try JSONDecoder().decode(Scene.self, from: data)

                    completion(scene)
                    self.onLoadScene(scene)
                } catch {
                    failure(error) // todo: Add a corrupted json scene to cover this path
                }
            }, failure: { (error) in
                failure(error)
            })
        }, failure: { (error) in
            failure(error)
        })
    }*/

    fileprivate func loadSceneManifest(name: String, bundle: Bundle = .main) -> Promise<SceneManifest> {
        let promise = Promise<SceneManifest>(in: .background) { (resolve, reject) in
            guard let path = bundle.path(forResource: name, ofType: sceneManifestFileExtension) else {
                throw RuntimeError.fileNotFound(fileName: name, type: .sceneManifest, bundleIdentifier: bundle.bundleIdentifier)
            }
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let manifest = try JSONDecoder().decode(SceneManifest.self, from: data)
                resolve(manifest)
            } catch {
                reject(error)
            }
        }
        return promise
    }
}

// MARK: - Support

fileprivate extension String {
    static let configurationFileName = "GameConfiguration"
    static let configurationFileExtension = "json"

    static let sceneDataFileExtension = "scenedata"
    static let sceneManifestFileExtension = "scenemanifest"
}
