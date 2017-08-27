//
//  Plane.swift
//  ArkitTest-Part3
//
//  Created by Patrick on 31/07/2017.
//  Copyright © 2017 0xDD. All rights reserved.
//

import Foundation
import ARKit

class Plane: SCNNode {
    
    var anchor: ARPlaneAnchor
    var planeGeometry: SCNBox
    
    init(_ anchor: ARPlaneAnchor,isHidden hidden:Bool) {
        self.anchor = anchor
        
        let width =  CGFloat(anchor.extent.x)
        let length = CGFloat(anchor.extent.z)
        let planeHeight = CGFloat(0.01)
        
        planeGeometry = SCNBox(width: width, height: planeHeight, length: length, chamferRadius: 0.0)
        
        super.init()
        
        let material = SCNMaterial()
        let grid = UIImage(named: "tron_grid.png")
        
        material.diffuse.contents = grid
        material.isDoubleSided = true
        
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        
       //             planeGeometry.materials = [material, material, material, material, material, material]
        
        if hidden {
            planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
        } else {
            planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material, transparentMaterial]
        }
     
        
        let planeNode : SCNNode = SCNNode(geometry:planeGeometry)
        planeNode.position = SCNVector3Make(0, Float(-planeHeight) / 2.0, 0);
        // to try
        // with planGeometry.materials in comment 
        // planeNode.position = SCNVector3Make(0, Float(-planeHeight), 0);
        
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil) )
        
        self.setTextureScale()
        self.addChildNode(planeNode)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ anchor: ARPlaneAnchor) {
        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.length = CGFloat(anchor.extent.z)
        
        self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
        
        let node = self.childNodes.first
        node!.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil) )
        
        self.setTextureScale()
    }
    
    func setTextureScale() {
        let width : CGFloat = self.planeGeometry.width
        let height : CGFloat = self.planeGeometry.length
        
        let material : SCNMaterial = self.planeGeometry.materials[4]
        
        let m  = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material.diffuse.contentsTransform = m
        material.diffuse.wrapS = SCNWrapMode.repeat
        material.diffuse.wrapT = SCNWrapMode.repeat
    }
    
    
    func hide() {
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
    }

}


