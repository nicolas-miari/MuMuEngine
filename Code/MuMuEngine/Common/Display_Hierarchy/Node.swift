//
//  Node.swift
//  TestbedApp(macOS)
//
//  Created by Nicolás Miari on 2019/04/01.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Foundation
import CoreGraphics
import simd

/**
 Represents one node in the display hierarchy.

 Not all nodes contain a renderable component: some act as grouping containers, so all their children can be
 transformed together.
 */
public class Node: Codable, Equatable {

    public static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs === rhs
    }

    internal(set) public var clearColor: Color = Color(red: 0.3, green: 0.4, blue: 1, alpha: 1) {
        didSet {
            //print("Did Set")
        }
    }

    internal var timeOffset: TimeInterval?

    public var name: String = ""

    public var isRoot: Bool {
        return (parent is Scene)
    }

    /**
     The parent object in the hierarchy.

     A node's parent object is:
       - A `Scene` instance, if the node is the root node of the scene represented by that instance,
       - Another `Node` instance, if the node is a non-root node,
      - `nil` if the node is dettached from the display hierarchy.
     */
    private(set) public weak var parent: AnyObject?

    public var parentNode: Node? {
        return parent as? Node
    }

    public var scene: Scene? {
        if let scene = parent as? Scene {
            return scene
        }
        return parentNode?.scene
    }

    public func setAsRootNode(of scene: Scene) {
        if parentNode == nil {
            removeFromParent()
        }
        if let parentScene = parent as? Scene, parentScene == scene {
            return
        }
        self.parent = scene
    }

    private(set) public var children: [Node]

    private(set) public var components: [Component]

    private(set) var componentsByName: [String: Component]

    private(set) var eventHandlersByType: [String: [EventHandler]]

    var meshComponent: TexturedMeshComponent? // Shortcut

    var z: Float = 0.0

    var draws: Bool {
        return (meshComponent != nil)
    }

    // MARK: - Space Transformations

    /**
     The receiver's transformation matrix, in the coordinate system of the parent node.
     */
    private(set) var localTransform: float4x4 {
        didSet {
            updateWorldTransform()
        }
    }

    /**
     The receiver's transformation matrix, in the global coordinate system.
     */
    private(set) var worldTransform: float4x4

    // MARK: - Initialization

    public init() {
        self.children = []
        self.localTransform = float4x4.identity
        self.worldTransform = float4x4.identity
        self.components = []
        self.componentsByName = [:]
        self.eventHandlersByType = [:]
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case name
        case children
        case localTransform
        case components
        case eventHandlers
        case blueprint
        case timeOffset
    }

    public required init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = (try container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.name = name
        self.localTransform = (try container.decodeIfPresent(float4x4.self, forKey: .localTransform)) ?? .identity
        self.worldTransform = .identity

        if container.contains(.blueprint) {
            let api = Runtime.shared.graphics
            let blueprintName = try container.decode(String.self, forKey: .blueprint)
            self.components = try api.componentsFromBlueprint(name: blueprintName)

        } else if container.contains(.components) {
            let componentContainers = try container.decode([Container].self, forKey: .components)
            self.components = componentContainers.compactMap { $0.payload as? Component  }
        } else {
            self.components = []
        }

        let tuples = components.map { (component) -> (String, Component) in
            return (component.name, component)
        }
        self.componentsByName = Dictionary(uniqueKeysWithValues: tuples)

        let handlers = try container.decodeIfPresent([EventHandler].self, forKey: .eventHandlers) ?? []
        self.eventHandlersByType = Dictionary.init(grouping: handlers, by: { $0.event.typeName })

        self.children = []
        let children = try container.decodeIfPresent([Node].self, forKey: .children) ?? []
        if children.isEmpty == false {
            children.forEach { addChild($0) } // (sets each child's `parent` property to self)
            updateWorldTransform()
        }

        self.timeOffset = try container.decodeIfPresent(TimeInterval.self, forKey: .timeOffset)
        configureComponents()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if !name.isEmpty {
            try container.encode(name, forKey: .name)
        }
        try container.encode(localTransform, forKey: .localTransform)
        try container.encode(children, forKey: .children)

        // TODO: Components/blueprints
    }

    // MARK: - Initialization Support

    func configureComponents() {
        if let stateMachine = componentsByName[StateMachineComponent.name] as? StateMachineComponent {
            stateMachine.setOwner(self)
        }
        if let hitBox = (components.first { $0 is HitBoxComponent } as? HitBoxComponent) {
            if hitBox.rect == CGRect.null {
                if let mesh = meshComponent {
                    // Use the mesh's extent as bounding box
                    hitBox.rect = mesh.bounds.centeredAtOrigin
                }
            }
            self.componentsByName[HitBoxComponent.name] = hitBox
        }
        if let offset = timeOffset {
            update(dt: offset)
        }
    }

    // MARK: - Node Hierarchy Manipulation

    public func addChild(_ child: Node) {
        insertChild(child, at: children.count)
    }

    public func insertChild(_ child: Node, at index: Int) {
        guard child.parent == nil else {
            fatalError("Attempting to insert child node from another parent. Remove from current parent first.")
        }
        guard child != self else {
            fatalError("Attempting to insert node as its own child.")
        }
        guard index >= 0, index <= children.count else {
            fatalError("Attempting to insert child at index beyond bounds.")
        }
        children.insert(child, at: index)
        child.parent = self
    }

    @discardableResult public func removeChild(at index: Int) -> Node {
        guard index >= 0, index < children.count else {
            fatalError("Attempting to remove child from index beyond bounds.")
        }
        let child = children.remove(at: index)
        child.parent = nil
        return child
    }

    public func removeFromParent() {
        guard let parent = parentNode else {
            return
        }
        guard let index = parent.children.firstIndex(of: self) else {
            fatalError("Tree inconsistency: Node not present in parent node's array of children.")
        }
        parent.removeChild(at: index)
    }

    public func swapChildrenAt(_ index1: Int, and index2: Int) {
        let temp = children[index1]
        self.children[index1] = children[index2]
        self.children[index2] = temp
    }

    // MARK: - Visibility

    /**
     Set per-node, used to determine the _effective_ visibility.

     Nodes are effectively visible if they are attached to the hierarchy, and this property has the value `true` for all
     ancestors all the way up to root node (that is: hiding a node effectively hides all of its descendants).
     */
    public var instrinsicVisibility: Bool = true

    /**
     Computed recursively based on own `instrinsicVisibility` and all ancestors' `effectiveVisibility`. Determines whether
     the node is ultimately visible on screen (rendered) or not.

     Nodes are effectively visible if they are attached to the hierarchy, and this property has the value `true` for all
     ancestors all the way up to root node (that is: hiding a node effectively hides all of its descendants).
     */
    public var effectiveVisibility: Bool {
        guard let parent = parentNode else {
            if isRoot {
                return instrinsicVisibility
            } else {
                return false
            }
        }
        return instrinsicVisibility && parent.effectiveVisibility
    }

    /**
     Size of the display hierarchy subtree that has the receiver as its root (i.e., the tree composed of the receiver and
     all its descendants).

     Calculated recursively: The returned value is the sum of the values obtained by querying this porperty on all of the
     receiver's children, plus one (to account for the receiver itself).
     */
    public var subtreeSize: Int {
        return (1 + children.map { $0.subtreeSize }.reduce(0, +))
    }

    // MARK: -

    func updateWorldTransform() {
        guard let parentWorld = parentNode?.worldTransform else {
            self.worldTransform = localTransform
            return
        }
        self.worldTransform = parentWorld * localTransform // (check order!)

        // Propagate:
        children.forEach { $0.updateWorldTransform() }
    }

    // MARK: - Input

    func handlePointInput(_ input: PointInput) {
        if let handlers = eventHandlersByType[PointInputEvent.name] {
            let filtered = handlers.filter { ($0.event as? PointInputEvent)?.pointInput == input }
            let actions = filtered.map { $0.action }
            performActions(actions)

        } else if let stateMachine = (components.first{ $0 is StateMachineComponent } as? StateMachineComponent) {
            stateMachine.handlePointInput(input)
        }
    }

    func performActions(_ actions: [Action]) {
        actions.forEach { (action) in
            switch action {
            case let sceneTransition as SceneTransitionAction:
                let sceneName = sceneTransition.destination
                let effect = sceneTransition.effect ?? Runtime.shared.defaultTransitionEffect
                let duration = sceneTransition.duration ?? Runtime.shared.defaultTransitionDuration

                Runtime.shared.loadScene(name: sceneName, onCompletion: .runAfterTransition(effect: effect, duration: duration), failure: { (error) in
                    systemAlert(title: "Error", message: error.localizedDescription)
                })
            default:
                break
            }
        }
    }

    // MARK: - Frame Updates

    func update(dt: TimeInterval) {
        // Update components:
        components.forEach { $0.update(dt: dt) }

        // Propagate to descendants:
        children.forEach { $0.update(dt: dt) }
    }

    func hitTest(point: CGPoint) -> Node? {
        guard pointIsWithinBounds(point) else {
            return nil
        }
        let firstChildHit = children.reversed().first { $0.pointIsWithinBounds(point) }
        return firstChildHit ?? self
    }

    // MARK: - Hit Testing

    private func pointIsWithinBounds(_ point: CGPoint) -> Bool {
        guard let hitbox = componentsByName[HitBoxComponent.name] as? HitBoxComponent else {
            return isRoot // (root node is all-emcompassing, always hit)
        }
        guard hitbox.rect != .null else {
            return true // (null rect represents "full-screen" hit area)
        }
        let local = worldTransform * SIMD4([Float(point.x), Float(point.y), 1, 0])
        let contains: Bool = hitbox.rect.contains(CGPoint(x: CGFloat(local.x), y: CGFloat(local.y)))

        return contains
    }
}
