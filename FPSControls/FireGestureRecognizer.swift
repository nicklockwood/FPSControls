//
//  FireGestureRecognizer.swift
//  FPSControls
//
//  Created by Nick Lockwood on 09/11/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class FireGestureRecognizer: UIGestureRecognizer {
    
    var timeThreshold = 0.15
    var distanceThreshold = 5.0
    private var startTimes = [Int:TimeInterval]()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        
        //record the start times of each touch
        for touch in touches {
            startTimes[touch.hash] = touch.timestamp
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        
        //discard any touches that have moved
        for touch in touches {
            
            let newPos = touch.location(in: view)
            let oldPos = touch.previousLocation(in: view)
            let distanceDelta = Double(max(abs(newPos.x - oldPos.x), abs(newPos.y - oldPos.y)))
            if distanceDelta >= distanceThreshold {
                startTimes[touch.hash] = nil
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        
        for touch in touches {

            let startTime = startTimes[touch.hash]
            if let startTime = startTime {
                
                //check if within time
                let timeDelta = touch.timestamp - startTime
                if timeDelta < timeThreshold {
                    
                    //recognized
                    state = .ended
                }
            }
        }
        reset()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        
        reset()
    }
    
    override func reset() {

        if state == .possible {
            state = .failed
        }
    }
}
