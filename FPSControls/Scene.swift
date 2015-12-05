//
//  Scene.swift
//  FPSControls
//
//  Created by Luke Schoen on 4/12/2015.
//  Copyright © 2015 Nick Lockwood. All rights reserved.
//

import Foundation
import SceneKit

struct CollisionCategory {

    static let None: Int = 0b00000000
    static let All: Int = 0b11111111
    static let Map: Int = 0b00000001
    static let Hero: Int = 0b00000010
    static let Monster: Int = 0b00000100
    static let Bullet: Int = 0b00001000
}

class Scene: SCNScene, SCNSceneRendererDelegate {

    // MARK: Properties

    internal var sceneView: SCNView?
    internal var cameraNode: SCNNode?
    internal var heroNode: SCNNode!
    internal var camNode: SCNNode!
    internal var elevation: Float = 0
    var mapNode: SCNNode!
    var map: Map!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init() {
        super.init()
    }

    func setupSceneWithView(scnView: SCNView) {

        /**
        *  Setup Map, Scene View, Entities, Camera,
        *  Level, Floor, Ceiling, and Physics
        */
        self.setupMap()
        self.setupView(scnView)
        self.setupEntities()
        self.setupCamera()
        self.setupLevel()
        self.setupFloor()
        self.setupCeiling()
        self.setupPhysics()
    }

    func setupMap() {

        map = Map(image: UIImage(named:"Map")!)
    }

    func setupView(view: SCNView) {

        self.sceneView = view
    }

    func setupEntities() {

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
                heroNode.physicsBody?.velocityFactor = SCNVector3(x: 1, y: 0, z: 1)
                heroNode.physicsBody?.categoryBitMask = CollisionCategory.Hero
                heroNode.physicsBody?.collisionBitMask = CollisionCategory.All ^ CollisionCategory.Bullet
                if #available(iOS 9.0, *) {
                    heroNode.physicsBody?.contactTestBitMask = ~0
                }
                heroNode.position = SCNVector3(x: entity.x, y: 0.5, z: entity.y)
                self.rootNode.addChildNode(heroNode)

            case .Monster:

                let monsterNode = SCNNode()
                monsterNode.position = SCNVector3(x: entity.x, y: 0.3, z: entity.y)
                monsterNode.geometry = SCNCylinder(radius: 0.15, height: 0.6)
                monsterNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: monsterNode.geometry!, options: nil))
                monsterNode.physicsBody?.categoryBitMask = CollisionCategory.Monster
                monsterNode.physicsBody?.collisionBitMask = CollisionCategory.All
                if #available(iOS 9.0, *) {
                    monsterNode.physicsBody?.contactTestBitMask = ~0
                }
                self.rootNode.addChildNode(monsterNode)
            }
        }
    }

    func setupCamera() {

        //add a camera node
        camNode = SCNNode()
        camNode.position = SCNVector3(x: 0, y: 0, z: 0)
        heroNode.addChildNode(camNode)

        //add camera
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = Double(max(map.width, map.height))
        camNode.camera = camera
    }

    func setupLevel() {

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
    }

    func setupFloor() {

        //add floor
        let floorNode = SCNNode()
        floorNode.geometry = SCNPlane(width: CGFloat(map.width), height: CGFloat(map.height))
        floorNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(-M_PI_2))
        floorNode.position = SCNVector3(x: Float(map.width)/2, y: 0, z: Float(map.height)/2)
        mapNode.addChildNode(floorNode)
    }

    func setupCeiling() {

        //add ceiling
        let ceilingNode = SCNNode()
        ceilingNode.geometry = SCNPlane(width: CGFloat(map.width), height: CGFloat(map.height))
        ceilingNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI_2))
        ceilingNode.position = SCNVector3(x: Float(map.width)/2, y: 1, z: Float(map.height)/2)
        mapNode.addChildNode(ceilingNode)
    }

    func setupPhysics() {

        self.physicsWorld.gravity = SCNVector3(x: 0, y: -9, z: 0)
        self.physicsWorld.timeStep = 1.0/360

        //set up map physics
        mapNode.physicsBody = SCNPhysicsBody(type: .Static, shape: SCNPhysicsShape(node: mapNode, options: [SCNPhysicsShapeKeepAsCompoundKey: true]))
        mapNode.physicsBody?.categoryBitMask = CollisionCategory.Map
        mapNode.physicsBody?.collisionBitMask = CollisionCategory.All
        if #available(iOS 9.0, *) {
            mapNode.physicsBody?.contactTestBitMask = ~0
        }
        self.rootNode.addChildNode(mapNode)
    }

    // MARK: Thread Safe Singleton Pattern

    /**
    *  Threadsafe Singleton declaration of static constant to
    *  hold the single instance of class. Supports lazy initialisation
    *  since Swift lazily initialises class constants and variables
    *  and is thread safe by the definition of let
    */
    static let sharedInstance = Scene()
}
