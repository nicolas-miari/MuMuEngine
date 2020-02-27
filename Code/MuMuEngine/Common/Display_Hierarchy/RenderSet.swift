//
//  RenderSet.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/24.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Groups all nodes to render in one scene frame, split by opacity status and sorted by depth.

 The fully-opaque nodes are sorted front-to-back to leverage depth-culling (occlusion culling).
 The non-fully-opaque nodes are orted back-to-front to yield correct alpha blending results.
 */
public struct RenderSet {
    /**
     A list of all fully-opaque nodes to render in one scene frame, sorted front-to-back to leverage depth-culling (occlusion culling).
     */
    let opaque: [Node]

    /**
     A list of all non-fully-opaque nodes to render in one scene frame, sorted back-to-front to yield correct alpha blending results.
     */
    let nonOpaque: [Node]

    /**
     Initializes an instance by splitting all the nodes in the tree into two 'buckets' according to opacity status, and sorting each bucket's
     nodes by depth: all fully-opaque nodes are sorted front-to-back to leverage depth-culling (occlusion culling); all non-fully-opaque
     nodes to render in one scene frame, sorted back-to-front to yield correct alpha blending results.
     */
    public init(from rootNode: Node) {
        // 1. First Pass: Assign Depths

        let treeSize = rootNode.subtreeSize
        let step = 1.0 / Float(treeSize)
        var z: Float = 0.0

        var nodeStack = [Node]()
        nodeStack.push(rootNode)

        while let node = nodeStack.pop() {
            node.z = z

            z = z + step

            let reverseChildren = node.children.reversed()
            reverseChildren.forEach { (child) in
                if child.effectiveVisibility == true {
                    child.updateWorldTransform()
                    nodeStack.push(child)
                }
            }
        }

        // 2. Second Pass: Split according to opacity

        var opaqueBucket = [Node]()
        var nonOpaqueBucket = [Node]()

        nodeStack.push(rootNode)

        while let node = nodeStack.pop() {
            if let sprite = node.meshComponent {
                if sprite.isFullyOpaque {
                    opaqueBucket.append(node)
                } else {
                    nonOpaqueBucket.append(node)
                }
            }
            let reverseChildren = node.children.reversed()
            reverseChildren.forEach { (child) in
                if child.effectiveVisibility == true { // NEEDED?
                    child.updateWorldTransform()
                    nodeStack.push(child)
                }
            }
        }

        // Sort opaques front-to-back:
        opaqueBucket.sort { (lhs, rhs) -> Bool in
            return lhs.z < rhs.z
        }

        // Sort translucents back-to-front:
        nonOpaqueBucket.sort { (lhs, rhs) -> Bool in
            return lhs.z > rhs.z
        }

        self.opaque = opaqueBucket
        self.nonOpaque = nonOpaqueBucket
    }
}
