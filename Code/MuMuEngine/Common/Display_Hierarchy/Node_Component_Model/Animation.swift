//
//  Animation.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/16.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

struct AnimationFrame {
    let mesh: Any
    let duration: TimeInterval
}


private struct AnimationFrameDescriptor: Codable {
    let index: Int
    let duration: TimeInterval
}

// MARK: - Animation Template

/**
 An ordered, timed sequence of sprites.

 Objects of this class are used as a blueprints to create instances of `AnimationSession`,
 each of which which represents a single 'run' of the animation. As such, the imstances are pretty
 much immutable (instances of `AnimationSession`, in cpntrast, keep track of the ellapsed time,
 frame currently being displayed, loops remaining, etc.).
 */
class Animation: Codable {

    private(set) var name: String = ""

    private let atlasName: String
    private let sourceNames: [String]
    private let frameDescriptors: [AnimationFrameDescriptor]

    private(set) var frames: [AnimationFrame]

    let frameOnsets: [TimeInterval]

    let totalDuration: TimeInterval

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case atlas
        case sources
        case frames
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        
        self.atlasName = try container.decode(String.self, forKey: .atlas)
        self.sourceNames = try container.decode([String].self, forKey: .sources)
        self.frameDescriptors = try container.decode([AnimationFrameDescriptor].self, forKey: .frames)
        self.frames = []

        self.totalDuration = frameDescriptors.map { $0.duration }.reduce(0,+)

        // There HAS to be a swiftier way...
        var accum: TimeInterval = 0
        self.frameOnsets = frameDescriptors.map({ (descriptor) -> TimeInterval in
            let retVal = accum
            accum += descriptor.duration
            return retVal
        })
        Swift.print("Successfully decoded Animation")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(atlasName, forKey: .atlas)
        try container.encode(sourceNames, forKey: .sources)
        try container.encode(frameDescriptors, forKey: .frames)
    }

    // MARK: - Initialization Support
    
    func assembleRuntimeResources(using api: GraphicsAPI = Runtime.shared.graphicsAPI) throws {
        self.frames = try frameDescriptors.map { (descriptor) -> AnimationFrame in
            let mesh = try api.spriteComponent(name: sourceNames[descriptor.index], inAtlas: atlasName)
            return AnimationFrame(mesh: mesh, duration: descriptor.duration)
        }
        Swift.print("Successfully loaded Animation Runtime Resources")
    }

    func setName(_ name: String) {
        self.name = name
    }
}

/**
 Represents one run of an animation.
 */
struct AnimationSession {
    enum LoopMode {
        case unlimited
        case limited(count: Int, completion: (() -> Void))
    }

    let source: Animation
    let loopMode: LoopMode

    var loopProgress: TimeInterval
    var frameProgress: TimeInterval

    var currentFrame: AnimationFrame
    var currentFrameIndex: Int

    var timeToNextFrame: TimeInterval
    var timeToNextLoop: TimeInterval

    var loopsCompleted: Int

    var isFinished: Bool {
        switch loopMode {
        case .unlimited:
            return false
        case .limited(let count, _):
            return loopsCompleted >= count
        }
    }

    init(source: Animation, loopMode: LoopMode = .unlimited) {
        self.source = source
        self.loopMode = loopMode

        self.loopProgress = 0
        self.frameProgress = 0

        self.currentFrameIndex = 0
        self.currentFrame = source.frames[0]

        self.timeToNextFrame = source.frames[0].duration
        self.timeToNextLoop = source.totalDuration

        self.loopsCompleted = 0
    }

    mutating func update(dt: TimeInterval) {
        loopProgress += dt
        frameProgress += dt

        if loopProgress < source.totalDuration {
            // Within the same loop...

            if frameProgress < currentFrame.duration {
                // Within the same frame; nothing more to do:
                return
            }
            // Seek new frame
            seekFrame()
        } else {
            // Wrapped into next loop, possibly skipped loops

            let covered = Int(floor(loopProgress / source.totalDuration))
            self.loopsCompleted += covered

            switch loopMode {
            case .unlimited:
                break
            case .limited(let count, let completion):
                if loopsCompleted >= count {
                    completion()
                    return
                }
            }
            loopProgress = remainder(loopProgress, source.totalDuration)
            // Seek new frame
            seekFrame()
        }
    }

    /**
     Updates `currentFrame`, `currentFrameIndex` and `frameProgress` based on
     the value of `loopProgress`.
     */
    mutating private func seekFrame() {
        // Find the index of the last frame that begins before loopProgress:

        let index = (0 ..< source.frames.count - 1).first {
            source.frameOnsets[$0 + 1] > loopProgress
        } ?? (source.frames.count - 1)

        self.currentFrameIndex = index
        self.currentFrame = source.frames[index]
        self.frameProgress = loopProgress - source.frameOnsets[index]
    }
}
