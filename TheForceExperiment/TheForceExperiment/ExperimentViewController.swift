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
import Vision

class ExperimentViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var gestureBlurEffectView: UIVisualEffectView!
    @IBOutlet weak var debugBlurEffectView: UIVisualEffectView!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var gestureLabel: UILabel!
    @IBOutlet weak var targetPointerEffectView: UIVisualEffectView!
    @IBOutlet weak var gestureImageView: UIImageView!
    
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
    
    
    var trooperSelected = false
    let objectID = "Stormtrooper"
    
    var tieSelected = false
    let object2ID = "Tie"
    
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.brandlmax.dispatchqueueml")
    
    var showHelperInterface = false
    
    
    // ACTIONS
    
//    var isPushed = true
//    let push = SCNAction.moveBy(x: 0, y: 0, z: -0.8, duration: 0.5)
//    let reset = SCNAction.moveBy(x: 0, y: 0, z: 0.8, duration: 0.5)
    
    // 🎉 EVENTS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // # 🚀 ARkit
        sceneView.delegate = self
        
        runSession()
        addLightToScene()
        
        // Trooper
        // FROM: https://sketchfab.com/models/9c80ee9978834250bd5940a3fb97e56b#
        
        let modelClone = SCNScene(named: "art.scnassets/trooper.scn")!.rootNode.clone()
        modelClone.name = objectID
        sceneView.scene.rootNode.addChildNode(modelClone)
        
        // TIE Fighter
        // FROM: https://sketchfab.com/models/720c1e633729446b91e339eacb23de3a
//        let secModelClone = SCNScene(named: "art.scnassets/tie.scn")!.rootNode.clone()
//        secModelClone.name = object2ID
//        sceneView.scene.rootNode.addChildNode(secModelClone)
//
        
        // Add Physics to Cube
        // updatePhysicsOnBox(modelClone)
        
        // # 🤖 CoreML
        // Setup Vision Model
        guard let selectedModel = try? VNCoreMLModel(for: GestureRec_01_Iteration11().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project. Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
        
        
        // # 🍬 Styling & Eye Candy
        debugBlurEffectView.layer.cornerRadius = 10
        debugBlurEffectView.clipsToBounds = true
        
        gestureBlurEffectView.layer.cornerRadius = 10
        gestureBlurEffectView.clipsToBounds = true
        
        targetPointerEffectView.layer.cornerRadius = 30
        targetPointerEffectView.clipsToBounds = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // 👆 Touch Events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        showHelperInterface = !showHelperInterface
        
//        locked = true
//        print(locked)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        locked = false
//        print(locked)
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
                // applyForce(to: node)
                return
            }
        }
    }
    
    func checkTrooperHit(){
        // 🎯 Select Target
        trooperSelected = false
        tieSelected = false
        
        guard let result = sceneView.hitTest(screenCenter, options: nil).first else {
            return
        }
        
        let trooperNode = sceneView.scene.rootNode.childNode(withName: "Stormtrooper", recursively: true)
        
        if (trooperNode?.contains(result.node))! { //myObjectNodes is declared as  Set<SCNNode>
            //This is a match
            // print("Match")
            trooperSelected = true
        }
        
//        let boxNode = sceneView.scene.rootNode.childNode(withName: "Tie", recursively: true)
//
//        if (boxNode?.contains(result.node))! { //myObjectNodes is declared as  Set<SCNNode>
//            //This is a match
//            // print("Match")
//            tieSelected = true
//        }
//
        
    }
    
    
    // # 🤖 CoreML
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        dispatchQueueML.async {
            // 1. Run Update.
            self.updateCoreML()
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
    }
    
    func updateCoreML() {
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Run Vision Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...2] // top 3 results
            .compactMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:" : %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        // Render Classifications
        DispatchQueue.main.async {
            // Print Classifications
            // print(classifications)
            // print("-------------")
            
            // Display Debug Text on screen
            self.debugLabel.text = "Prediction: \n" + classifications
            
            // Display Top Symbol
            var symbol = "❎"
            self.gestureImageView.image = nil
            
            let topPrediction = classifications.components(separatedBy: "\n")[0]
            let topPredictionName = topPrediction.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
            
            // Only display a prediction if confidence is above 1%
            
            let topPredictionScore:Float? = Float(topPrediction.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces))
            
            
            if (topPredictionScore != nil && topPredictionScore! > 0.5) {
                if (topPredictionName == "aim") {
                    symbol = "👉"
                    self.gestureImageView.image = UIImage(named: "Aim")
                }
                
                if (topPredictionName == "shoot") {
                    symbol = "💥"
                    self.gestureImageView.image = UIImage(named: "Shoot")
                    
                }
                
                if (topPredictionName == "hold") {
                    symbol = "👊"
                    self.gestureImageView.image = UIImage(named: "Hold")
                    self.locked = true
            
                }else{
                    self.locked = false
                }
                
                if (topPredictionName == "open") {
                    symbol = "🖐"
                    self.gestureImageView.image = UIImage(named: "Open")
                }
                
            }
            
            if(self.showHelperInterface){
                self.gestureBlurEffectView.isHidden = true
                self.debugBlurEffectView.isHidden = true
            }else{
                self.gestureBlurEffectView.isHidden = false
                self.debugBlurEffectView.isHidden = false
            }
            
            self.gestureLabel.text = symbol
            
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
        
        
        // Check if Trooper is Selected (in Center)
        self.checkTrooperHit()
        
        for node in sceneView.scene.rootNode.childNodes{
            
            if node.name == objectID{
                if locked && trooperSelected{
                    node.simdTransform = currentTransform!
                    
                    // Animation Try
//                    if(isPushed){
//                        isPushed = false
//                        node.runAction(push) {
//                            print("done")
//                            self.isPushed = true;
//                            // node.runAction(self.reset)
//                        }
//                    }

                }
                else{
                    // applyForce(to: node)
                }
            }
            
//            if node.name == object2ID{
//                if locked && tieSelected{
//                    node.simdTransform = currentTransform!
//                }
//                else{
//                    applyForce(to: node)
//                }
//            }
            
        }
        
    }
    
}
