//
//  NodeUtils.swift
//  DragObject
//
//  Created by Maximilian Brandl on 19.06.18.
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

func playHover (for node: SCNNode) {
//    node.runAction(
//        SCNAction.playAudio(boxKickedAudioSource, waitForCompletion: true))
//    print("Hover")
}
