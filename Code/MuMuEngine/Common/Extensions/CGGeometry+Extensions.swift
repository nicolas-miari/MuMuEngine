//
//  CGGeometry+Extensions.swift
//  TestBedApp(iOS)
//
//  Created by Nicolás Miari on 2019/04/03.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGRect {
    var centeredAtOrigin: CGRect {
        return self.offsetBy(dx: -width/2, dy: -height/2)
    }
}


