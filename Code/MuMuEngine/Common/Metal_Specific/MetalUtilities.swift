//
//  MetalUtilities.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/08/22.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Metal

/**
 Wraps the call to `MTLCreateSystemDefaultDevice()`, which returns an optional but never really fails,
 in a throwing function.

 This way, we can avoid littering all the numerous throwing methods and initializers with guard/else
 blocks that will never be called and thus affect **code coverage** negatively (now only the `else`
 block of _this_ method will not be covenered) and instead use:

     // (inside a throwing function or initializer)
     let device = try `createSystemDefaultMetalDevice()`
 */
public func createSystemDefaultMetalDevice() throws -> MTLDevice {
    guard let device = MTLCreateSystemDefaultDevice() else {
        throw RuntimeError.failedToInitializeGraphicsDriver(customMessage: "Failed to acquire system default Metal device.")
    }
    return device
}
