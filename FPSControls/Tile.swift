//
//  Tile.swift
//  FPSControls
//
//  Created by Nick Lockwood on 09/11/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import Foundation

enum TileType {
    
    case Rock
    case Wall
    case Floor
}

struct FaceVisibility: OptionSet {

    let rawValue: UInt
    static let none = FaceVisibility([])
    static let top = FaceVisibility(rawValue: 1 << 0)
    static let right = FaceVisibility(rawValue: 1 << 1)
    static let bottom = FaceVisibility(rawValue: 1 << 2)
    static let left = FaceVisibility(rawValue: 1 << 3)
}

class Tile {
    
    unowned let map: Map
    let x, y: Int
    var type: TileType = .Rock
    var visibility: FaceVisibility {
        var visibility: FaceVisibility = .none
        if x > 0 && map.tile(x - 1, y).type == .Floor {
            visibility.insert(.left)
        }
        if x < map.width - 1 && map.tile(x + 1, y).type == .Floor {
            visibility.insert(.right)
        }
        if y > 0 && map.tile(x, y - 1).type == .Floor {
            visibility.insert(.top)
        }
        if y < map.height - 1 && map.tile(x, y + 1).type == .Floor {
            visibility.insert(.bottom)
        }
        return visibility
    }
    
    init(map: Map, x: Int, y: Int) {
        
        self.map = map
        self.x = x
        self.y = y
    }
}
