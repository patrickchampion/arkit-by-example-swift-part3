//
//  ViewController.swift
//  ArkitTest-Part3
//
//  Created by Patrick on 28/07/2017.
//  Copyright © 2017 0xDD. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var planes = [ARPlaneAnchor: Plane]()
    var boxes = [SCNNode]()
    
    let CollisionCategoryBottom  = 1 << 0  //1
    let CollisionCategoryCube    = 1 << 1  //2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupScene() {
        sceneView.delegate = self
        
        sceneView.showsStatistics = true
        sceneView.automaticallyUpdatesLighting = true
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints , ARSCNDebugOptions.showWorldOrigin]
        
        // var scnScene = SCNScene()
        // sceneView.scene = scnScene
        
        let bottomPlane: SCNBox = SCNBox(width: 1000.0, height: 0.5, length: 1000.0, chamferRadius: 0.0)
        let  bottomMaterial: SCNMaterial = SCNMaterial()
        bottomMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        bottomPlane.materials = [bottomMaterial]
        
        let bottomNode: SCNNode = SCNNode(geometry: bottomPlane)
        bottomNode.position = SCNVector3Make(0, -10, 0)
        bottomNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        
        bottomNode.physicsBody?.categoryBitMask = CollisionCategoryBottom
        bottomNode.physicsBody?.contactTestBitMask = CollisionCategoryCube
        
        sceneView.scene.rootNode.addChildNode(bottomNode)
        sceneView.scene.physicsWorld.contactDelegate = self
        
    }
    
    func setupSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    func setupRecognizers() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapFrom(recognizer:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let explosionGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleHoldFrom(recognizer:)))
        explosionGestureRecognizer.minimumPressDuration = 0.5
        sceneView.addGestureRecognizer(explosionGestureRecognizer)
        
        let hidePlanesGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleHidePlaneFrom(recognizer:)))
        hidePlanesGestureRecognizer.minimumPressDuration = 1
        hidePlanesGestureRecognizer.numberOfTouchesRequired = 2
        sceneView.addGestureRecognizer(hidePlanesGestureRecognizer)

    }
    
    @objc func handleTapFrom(recognizer: UITapGestureRecognizer) {
        let tapPoint = recognizer.location(in: sceneView)
        let result = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        
        if (result.count == 0) {
            return
        }
        
        let hitResult = result.first
        insertGeometry(hitResult: hitResult!)
    }
    
    @objc func handleHoldFrom(recognizer: UILongPressGestureRecognizer) {
        
        if (recognizer.state != .began) {
            return
        }
        
        let tapPoint = recognizer.location(in: sceneView)
        let result = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        
        if (result.count == 0) {
            return
        }
        
        let hitResult = result.first
        explode(hitResult: hitResult!)
    }
    
    @objc func handleHidePlaneFrom(recognizer: UILongPressGestureRecognizer) {
        
        if (recognizer.state != .began) {
            return
        }
        
        for plane in planes {
            plane.value.hide()
        }
        
        let configuration = sceneView.session.configuration as! ARWorldTrackingConfiguration
        configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection(rawValue: 0)
        sceneView.session.run(configuration)
    }
    
    func explode (hitResult :ARHitTestResult) {
        
        let explosionYOffset: Float = 0.1
        
        let position = SCNVector3Make(
            hitResult.worldTransform.columns.3.x,
            hitResult.worldTransform.columns.3.y - explosionYOffset,
            hitResult.worldTransform.columns.3.z
        )
        
        for cubeNode in boxes {
            
            var distance = SCNVector3Make(
                cubeNode.worldPosition.x - position.x,
                cubeNode.worldPosition.y - position.y,
                cubeNode.worldPosition.z - position.z
            )
            
            let len: Float = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
            
            let maxDistance: Float = 2.0;
            var scale: Float  = max(0, (maxDistance - len))
            
            scale = scale * scale * 2;
            
            distance.x = distance.x / len * scale;
            distance.y = distance.y / len * scale;
            distance.z = distance.z / len * scale;
            
            cubeNode.physicsBody?.applyForce(distance, at: SCNVector3Make(0.05, 0.05, 0.05), asImpulse: true)
        }
    }
    
    func insertGeometry(hitResult :ARHitTestResult) {
        
        let dimension: CGFloat = 0.1;
        
        let cube = SCNBox(width: dimension, height: dimension, length: dimension, chamferRadius: CGFloat(0))
        let node = SCNNode(geometry: cube)
        
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.mass = 2.0
        node.physicsBody?.categoryBitMask = CollisionCategoryCube
        
        let insertionYOffset : Float = 0.5
        node.position = SCNVector3Make(
            hitResult.worldTransform.columns.3.x,
            hitResult.worldTransform.columns.3.y + insertionYOffset,
            hitResult.worldTransform.columns.3.z
        )
        
        sceneView.scene.rootNode.addChildNode(node)
        boxes.append(node)
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        
        if (contactMask == (CollisionCategoryBottom | CollisionCategoryCube)) {
            if (contact.nodeA.physicsBody?.categoryBitMask == CollisionCategoryBottom) {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                
                let plane = Plane(planeAnchor, isHidden: false)
                
                self.planes[planeAnchor] = plane
                node.addChildNode(plane)
                
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if let plane = self.planes[planeAnchor] {
                    plane.update(planeAnchor)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if let plane = self.planes.removeValue(forKey: planeAnchor) {
                    plane.removeFromParentNode()
                }
                
            }
        }
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
