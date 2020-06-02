//
//  TickObserver.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/02.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Helps calculate the time ellapsed between screen refreshes.
 */
class TimeSource {

    private var machToMilliseconds: Double
    private var lastMachTime: UInt64

    // MARK: - Initialization

    init() {
        var timebase: mach_timebase_info_data_t = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        self.machToMilliseconds = Double(timebase.numer) / Double(timebase.denom) * 1e-6
        self.lastMachTime = mach_absolute_time()
    }

    // MARK: - Operation
    
    /**
     Returns the time ellapsed since the last time the method was called. Call
     once on each invocation of the vSync callback and use the returned interval
     to update all nodes and transitions.
     */
    func update() -> TimeInterval {
        let now = mach_absolute_time()
        let deltaTime = now - lastMachTime
        self.lastMachTime = now

        let deltaSeconds = machToMilliseconds*Double(deltaTime) / 1000.0

        #if DEBUG
        if deltaSeconds > 1.0/30.0 {
            return 1.0 / 60.0
        }
        #endif

        return TimeInterval(deltaSeconds)
    }
}
