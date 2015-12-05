//
//  GestureRecognizerExtension.swift
//  FPSControls
//
//  Created by Luke Schoen on 4/12/2015.
//  Copyright © 2015 Nick Lockwood. All rights reserved.
//

import UIKit
import SceneKit

extension ViewController: UIGestureRecognizerDelegate {

    internal func setupGestureRecognizers() {

        //look gesture
        lookGesture = UIPanGestureRecognizer(target: self, action: "lookGestureRecognized:")
        lookGesture.delegate = self
        self.sceneView.addGestureRecognizer(lookGesture)

        //walk gesture
        walkGesture = UIPanGestureRecognizer(target: self, action: "walkGestureRecognized:")
        walkGesture.delegate = self
        self.sceneView.addGestureRecognizer(walkGesture)

        //fire gesture
        fireGesture = FireGestureRecognizer(target: self, action: "fireGestureRecognized:")
        fireGesture.delegate = self
        self.sceneView.addGestureRecognizer(fireGesture)
    }

    //implement protocol methods for conformance
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        if gestureRecognizer == lookGesture {
            return touch.locationInView(self.view).x > self.view.frame.size.width / 2
        } else if gestureRecognizer == walkGesture {
            return touch.locationInView(self.view).x < self.view.frame.size.width / 2
        }
        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }

    //custom methods
    func lookGestureRecognized(gesture: UIPanGestureRecognizer) {

        //get translation and convert to rotation
        let translation = gesture.translationInView(self.sceneView)
        let hAngle = acos(Float(translation.x) / 200) - Float(M_PI_2)
        let vAngle = acos(Float(translation.y) / 200) - Float(M_PI_2)

        //rotate hero
        Scene.sharedInstance.heroNode.physicsBody?.applyTorque(SCNVector4(x: 0, y: 1, z: 0, w: hAngle), impulse: true)

        //tilt camera
        Scene.sharedInstance.elevation = max(Float(-M_PI_4), min(Float(M_PI_4), Scene.sharedInstance.elevation + vAngle))
        Scene.sharedInstance.camNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Scene.sharedInstance.elevation)

        //reset translation
        gesture.setTranslation(CGPointZero, inView: self.sceneView)
    }

    func walkGestureRecognized(gesture: UIPanGestureRecognizer) {

        if gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled {
            gesture.setTranslation(CGPointZero, inView: self.sceneView)
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
}
