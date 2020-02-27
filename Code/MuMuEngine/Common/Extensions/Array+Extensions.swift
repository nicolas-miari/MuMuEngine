//
//  Array+Extensions.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/08/21.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

public extension Array {

    // MARK: - Stack-like Interface

    mutating func push(_ element: Element) {
        append(element)
    }

    mutating func pop() -> Element? {
        if count > 0 {
            return self.removeLast()
        }
        return nil
    }

    // MARK: - Queue-like Interface

    mutating func enqueue(_ element: Element) {
        insert(element, at: 0)
    }

    mutating func dequeue() -> Element? {
        if count > 0 {
            return self.removeLast()
        }
        return nil
    }
}




