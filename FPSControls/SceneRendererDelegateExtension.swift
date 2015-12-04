//
//  SceneRendererDelegateExtension.swift
//  FPSControls
//
//  Created by Luke Schoen on 4/12/2015.
//  Copyright © 2015 Nick Lockwood. All rights reserved.
//

import Foundation
import SceneKit

extension ViewController: SCNSceneRendererDelegate {

    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {

        //get walk gesture translation
        let translation = walkGesture.translationInView(self.view)

        //create impulse vector for hero
        let angle = heroNode.presentationNode.rotation.w * heroNode.presentationNode.rotation.y
        var impulse = SCNVector3(x: max(-1, min(1, Float(translation.x) / 50)), y: 0, z: max(-1, min(1, Float(-translation.y) / 50)))
        impulse = SCNVector3(
            x: impulse.x * cos(angle) - impulse.z * sin(angle),
            y: 0,
            z: impulse.x * -sin(angle) - impulse.z * cos(angle)
        )
        heroNode.physicsBody?.applyForce(impulse, impulse: true)

        //handle firing
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastTappedFire < autofireTapTimeThreshold {
            let fireRate = min(Double(maxRoundsPerSecond), Double(tapCount) / autofireTapTimeThreshold)
            if now - lastFired > 1 / fireRate {

                //get hero direction vector
                let angle = heroNode.presentationNode.rotation.w * heroNode.presentationNode.rotation.y
                var direction = SCNVector3(x: -sin(angle), y: 0, z: -cos(angle))

                //get elevation
                direction = SCNVector3(x: cos(elevation) * direction.x, y: sin(elevation), z: cos(elevation) * direction.z)

                //create or recycle bullet node
                let bulletNode: SCNNode = {
                    if self.bullets.count < self.maxBullets {
                        return SCNNode()
                    } else {
                        return self.bullets.removeAtIndex(0)
                    }
                }()
                bullets.append(bulletNode)
                bulletNode.geometry = SCNBox(width: CGFloat(bulletRadius) * 2, height: CGFloat(bulletRadius) * 2, length: CGFloat(bulletRadius) * 2, chamferRadius: CGFloat(bulletRadius))
                bulletNode.position = SCNVector3(x: heroNode.presentationNode.position.x, y: 0.4, z: heroNode.presentationNode.position.z)
                bulletNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: bulletNode.geometry!, options: nil))
                bulletNode.physicsBody?.categoryBitMask = CollisionCategory.Bullet
                bulletNode.physicsBody?.collisionBitMask = CollisionCategory.All ^ CollisionCategory.Hero
                bulletNode.physicsBody?.velocityFactor = SCNVector3(x: 1, y: 0.5, z: 1)
                self.sceneView.scene!.rootNode.addChildNode(bulletNode)

                //apply impulse
                let impulse = SCNVector3(x: direction.x * Float(bulletImpulse), y: direction.y * Float(bulletImpulse), z: direction.z * Float(bulletImpulse))
                bulletNode.physicsBody?.applyForce(impulse, impulse: true)

                //update timestamp
                lastFired = now
            }
        }
    }
}
