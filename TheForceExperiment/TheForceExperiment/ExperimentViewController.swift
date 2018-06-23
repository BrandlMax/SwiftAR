//
//  ExperimentViewController
//  TheForceExperiment
//
//  Created by Maximilian Brandl on 23.06.18.
//  Copyright © 2018 Maximilian Brandl. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

class ExperimentViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    // GLOBAL
    
    var screenCenter: CGPoint {
        let screenSize = view.bounds
        return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
    }
    
    let omniLight = SCNLight()
    let ambientLight = SCNLight()
    var currentLightEstimate : ARLightEstimate?
    
    var locked = false
    var currentTransform : matrix_float4x4?
    var planeDetectionActive = true
    
    let objectID = "testBoxModel"
    
    // 🎉 EVENTS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runSession()
        addLightToScene()
        
        // Add Cube
        let modelClone = SCNScene(named: "art.scnassets/cube.scn")!.rootNode.clone()
        modelClone.name = objectID
        sceneView.scene.rootNode.addChildNode(modelClone)
        
        // Add Physics to Cube
        updatePhysicsOnBox(modelClone)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        locked = true
        print(locked)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        locked = false
        print(locked)
    }
    
    // 🔧 CUSTOM FUNCTIONS
    
    func addLightToScene () {
        omniLight.type = .omni
        omniLight.name = "omniLight"
        let spotNode = SCNNode()
        spotNode.light = omniLight
        spotNode.position = SCNVector3Make(0, 50, 0)
        sceneView.scene.rootNode.addChildNode(spotNode)
        
        ambientLight.type = .ambient
        ambientLight.name = "ambientLight"
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        ambientNode.position = SCNVector3Make(0, 50, 50)
        sceneView.scene.rootNode.addChildNode(ambientNode)
    }
    
    
    func runSession() {
        sceneView.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        
        if planeDetectionActive {
            if #available(iOS 11.3, *) {
                configuration.planeDetection = [.horizontal, .vertical]
            } else {
                configuration.planeDetection = .horizontal
            }
        }
        
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        
    }
    
    
    func updateLights () {
        if let lightInfo = currentLightEstimate {
            omniLight.intensity = lightInfo.ambientIntensity
            omniLight.temperature = lightInfo.ambientColorTemperature
            ambientLight.intensity = lightInfo.ambientIntensity / 2
            ambientLight.temperature = lightInfo.ambientColorTemperature
        }
    }
    
    
    func hitInteraction(for nodeName: String){
        let hits = sceneView.hitTest(screenCenter, options: nil)
        if !planeDetectionActive && hits.count > 0 && hits[0].isKind(of: SCNHitTestResult.self) {  //found an element!
            let node = hits[0].node
            if node.name == nodeName {
                applyForce(to: node)
                return
            }
        }
    }
    
    
}

// ➕ EXTENSIONS

extension ExperimentViewController : ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            // WHEN CHILDNODE ADDED
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            // WHEN SCENE UPDATED
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // WHEN SOMETHING IS REMOVED
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateLights()
        }
    }
    
}

extension ExperimentViewController : ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        currentTransform = frame.camera.transform
        
        /*
         [[0.896318, -0.321191, 0.305697, 0.0)],
         [0.442325, 0.695921, -0.565724, 0.0)],
         [-0.0310358, 0.642286, 0.765837, 0.0)],
         [-0.00246346, 0.000930991, -0.00169784, 1.0)]]
         */
        
        for node in sceneView.scene.rootNode.childNodes{
            
            if node.name == objectID{
                if locked{
                    node.simdTransform = currentTransform!
                }
                else{
                    applyForce(to: node)
                }
            }
            
        }
        
    }
    
}
