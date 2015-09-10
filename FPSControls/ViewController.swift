//
//  ViewController.swift
//  FPSControls
//
//  Created by Nick Lockwood on 30/10/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import UIKit
import SceneKit

struct CollisionCategory {
    
    static let None: Int = 0b00000000
    static let All: Int = 0b11111111
    static let Map: Int = 0b00000001
    static let Hero: Int = 0b00000010
    static let Monster: Int = 0b00000100
    static let Bullet: Int = 0b00001000
}

class ViewController: UIViewController, UIGestureRecognizerDelegate, SCNSceneRendererDelegate {

    //MARK: config
    let autofireTapTimeThreshold = 0.2
    let maxRoundsPerSecond = 30
    let bulletRadius = 0.05
    let bulletImpulse = 15
    let maxBullets = 100
    
    @IBOutlet var sceneView: SCNView!
    @IBOutlet var overlayView: UIView!
    
    var lookGesture: UIPanGestureRecognizer!
    var walkGesture: UIPanGestureRecognizer!
    var fireGesture: FireGestureRecognizer!
    var heroNode: SCNNode!
    var camNode: SCNNode!
    var elevation: Float = 0
    var mapNode: SCNNode!
    var map: Map!
    
    var tapCount = 0
    var lastTappedFire: NSTimeInterval = 0
    var lastFired: NSTimeInterval = 0
    var bullets = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //generate map
        map = Map(image: UIImage(named:"Map")!)
        
        //create a new scene
        let scene = SCNScene()
        scene.physicsWorld.gravity = SCNVector3(x: 0, y: -9, z: 0)
        scene.physicsWorld.timeStep = 1.0/360

        //add entities
        for entity in map.entities {
            switch entity.type {
            case .Hero:
                
                heroNode = SCNNode()
                heroNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.2, height: 1), options: nil))
                heroNode.physicsBody?.angularDamping = 0.9999999
                heroNode.physicsBody?.damping = 0.9999999
                heroNode.physicsBody?.rollingFriction = 0
                heroNode.physicsBody?.friction = 0
                heroNode.physicsBody?.restitution = 0
                if #available(iOS 9.0, *) {
                    heroNode.physicsBody?.affectedByGravity = false
                } else {
                    heroNode.physicsBody?.velocityFactor = SCNVector3(x: 1, y: 0, z: 1)
                }
                heroNode.physicsBody?.categoryBitMask = CollisionCategory.Hero
                heroNode.physicsBody?.collisionBitMask = CollisionCategory.All ^ CollisionCategory.Bullet
                heroNode.position = SCNVector3(x: entity.x, y: 0.5, z: entity.y)
                scene.rootNode.addChildNode(heroNode)

            case .Monster:
                
                let monsterNode = SCNNode()
                monsterNode.position = SCNVector3(x: entity.x, y: 0.3, z: entity.y)
                monsterNode.geometry = SCNCylinder(radius: 0.15, height: 0.6)
                monsterNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: monsterNode.geometry!, options: nil))
                monsterNode.physicsBody?.categoryBitMask = CollisionCategory.Monster
                monsterNode.physicsBody?.collisionBitMask = CollisionCategory.All
                scene.rootNode.addChildNode(monsterNode)
            }
        }
        
        //add a camera node
        camNode = SCNNode()
        camNode.position = SCNVector3(x: 0, y: 0, z: 0)
        heroNode.addChildNode(camNode)
        
        //add camera
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = Double(max(map.width, map.height))
        camNode.camera = camera
        
        //create map node
        mapNode = SCNNode()
        
        //add walls
        for tile in map.tiles {
            
            if tile.type == .Wall {
                
                //create walls
                if tile.visibility.contains(.Top) {
                    let wallNode = SCNNode()
                    wallNode.geometry = SCNPlane(width: 1, height: 1)
                    wallNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(M_PI))
                    wallNode.position = SCNVector3(x: Float(tile.x) + 0.5, y: 0.5, z: Float(tile.y))
                    mapNode.addChildNode(wallNode)
                }
                if tile.visibility.contains(.Right) {
                    let wallNode = SCNNode()
                    wallNode.geometry = SCNPlane(width: 1, height: 1)
                    wallNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(M_PI_2))
                    wallNode.position = SCNVector3(x: Float(tile.x) + 1, y: 0.5, z: Float(tile.y) + 0.5)
                    mapNode.addChildNode(wallNode)
                }
                if tile.visibility.contains(.Bottom) {
                    let wallNode = SCNNode()
                    wallNode.geometry = SCNPlane(width: 1, height: 1)
                    wallNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: 0)
                    wallNode.position = SCNVector3(x: Float(tile.x) + 0.5, y: 0.5, z: Float(tile.y) + 1)
                    mapNode.addChildNode(wallNode)
                }
                if tile.visibility.contains(.Left) {
                    let wallNode = SCNNode()
                    wallNode.geometry = SCNPlane(width: 1, height: 1)
                    wallNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(-M_PI_2))
                    wallNode.position = SCNVector3(x: Float(tile.x), y: 0.5, z: Float(tile.y) + 0.5)
                    mapNode.addChildNode(wallNode)
                }
            }
        }
        
        //add floor
        let floorNode = SCNNode()
        floorNode.geometry = SCNPlane(width: CGFloat(map.width), height: CGFloat(map.height))
        floorNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(-M_PI_2))
        floorNode.position = SCNVector3(x: Float(map.width)/2, y: 0, z: Float(map.height)/2)
        mapNode.addChildNode(floorNode)

        //add ceiling
        let ceilingNode = SCNNode()
        ceilingNode.geometry = SCNPlane(width: CGFloat(map.width), height: CGFloat(map.height))
        ceilingNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI_2))
        ceilingNode.position = SCNVector3(x: Float(map.width)/2, y: 1, z: Float(map.height)/2)
        mapNode.addChildNode(ceilingNode)

        //set up map physics
        mapNode.physicsBody = SCNPhysicsBody(type: .Static, shape: SCNPhysicsShape(node: mapNode, options: nil))
        mapNode.physicsBody?.categoryBitMask = CollisionCategory.Map
        mapNode.physicsBody?.collisionBitMask = CollisionCategory.All
        scene.rootNode.addChildNode(mapNode)
        
        //set the scene to the view
        sceneView.scene = scene
        sceneView.delegate = self
        
        //show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //configure the view
        sceneView.backgroundColor = UIColor.blackColor()
        
        //look gesture
        lookGesture = UIPanGestureRecognizer(target: self, action: "lookGestureRecognized:")
        lookGesture.delegate = self
        view.addGestureRecognizer(lookGesture)
        
        //walk gesture
        walkGesture = UIPanGestureRecognizer(target: self, action: "walkGestureRecognized:")
        walkGesture.delegate = self
        view.addGestureRecognizer(walkGesture)

        //fire gesture
        fireGesture = FireGestureRecognizer(target: self, action: "fireGestureRecognized:")
        fireGesture.delegate = self
        view.addGestureRecognizer(fireGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        UIView.animateWithDuration(0.5) {
            self.overlayView.alpha = 1
        }
    }
    
    @IBAction func hideOverlay() {
        
        UIView.animateWithDuration(0.5) {
            self.overlayView.alpha = 0
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if gestureRecognizer == lookGesture {
            return touch.locationInView(view).x > view.frame.size.width / 2
        } else if gestureRecognizer == walkGesture {
            return touch.locationInView(view).x < view.frame.size.width / 2
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    func lookGestureRecognized(gesture: UIPanGestureRecognizer) {
        
        //get translation and convert to rotation
        let translation = gesture.translationInView(self.view)
        let hAngle = acos(Float(translation.x) / 200) - Float(M_PI_2)
        let vAngle = acos(Float(translation.y) / 200) - Float(M_PI_2)
        
        //rotate hero
        heroNode.physicsBody?.applyTorque(SCNVector4(x: 0, y: 1, z: 0, w: hAngle), impulse: true)
        
        //tilt camera
        elevation = max(Float(-M_PI_4), min(Float(M_PI_4), elevation + vAngle))
        camNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: elevation)
        
        //reset translation
        gesture.setTranslation(CGPointZero, inView: self.view)
    }
    
    func walkGestureRecognized(gesture: UIPanGestureRecognizer) {

        if gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled {
            gesture.setTranslation(CGPointZero, inView: self.view)
        }
    }
    
    func fireGestureRecognized(gesture: FireGestureRecognizer) {

        //update timestamp
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastTappedFire < autofireTapTimeThreshold {
            tapCount += 1
        } else {
            tapCount = 1
        }
        lastTappedFire = now
    }

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

