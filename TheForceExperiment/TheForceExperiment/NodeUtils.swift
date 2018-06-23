//
//  NodeUtils.swift
//  TheForceExperiment
//
//  Created by Maximilian Brandl on 23.06.18.
//  Copyright © 2018 Maximilian Brandl. All rights reserved.
//

import Foundation
import SceneKit
import ARKit
import GameplayKit

func test(){
    print("TEST!")
}

func applyForce(to node: SCNNode) {
    let forceX = Float(GKRandomSource.sharedRandom().nextInt(upperBound: 3))
    let forceY = Float(GKRandomSource.sharedRandom().nextInt(upperBound: 3))
    let forceZ = Float(GKRandomSource.sharedRandom().nextInt(upperBound: 3))
    node.physicsBody?.applyForce(SCNVector3Make(forceX, forceY, forceZ), asImpulse: true)
}

func playHoverAction (for node: SCNNode) {
    //    node.runAction(
    //        SCNAction.playAudio(boxKickedAudioSource, waitForCompletion: true))
    //    print("Hover")
}


// PHYSICS

struct CollisionTypes : OptionSet {
    let rawValue: Int
    
    static let bottom  = CollisionTypes(rawValue: 1 << 0)
    static let shape = CollisionTypes(rawValue: 1 << 1)
}

func updatePhysicsOnBox (_ model: SCNNode) {
    let boxNode = model.childNode(withName: "mybox", recursively: true)
    if let node = boxNode {
        
        node.physicsBody = nil
        
        let physicsBody = SCNPhysicsBody.dynamic()
        physicsBody.mass = 1
        physicsBody.restitution = 0.1
        physicsBody.friction = 0.75
        physicsBody.damping = 0.3
        physicsBody.categoryBitMask = CollisionTypes.shape.rawValue
        node.physicsBody = physicsBody
        node.position.y = 0.2
    }
}
