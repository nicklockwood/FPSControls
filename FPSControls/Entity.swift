//
//  Entity.swift
//  FPSControls
//
//  Created by Nick Lockwood on 09/11/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import Foundation

enum EntityType {
    
    case Hero
    case Monster
}

class Entity {
    
    var type: EntityType
    var x, y: Float
    
    init(type: EntityType, x: Float, y: Float) {
        
        self.type = type
        self.x = x
        self.y = y
    }
}
