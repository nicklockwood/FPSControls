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

struct FaceVisibility : OptionSetType {

    let rawValue: UInt
    static let None = FaceVisibility(rawValue: 0)
    static let Top = FaceVisibility(rawValue: 1 << 0)
    static let Right = FaceVisibility(rawValue: 1 << 1)
    static let Bottom = FaceVisibility(rawValue: 1 << 2)
    static let Left = FaceVisibility(rawValue: 1 << 3)
}

class Tile {
    
    unowned let map: Map
    let x, y: Int
    var type: TileType = .Rock
    var visibility: FaceVisibility {
        var visibility: FaceVisibility = .None
        if x > 0 && map.tile(x - 1, y).type == .Floor {
            visibility.unionInPlace(.Left)
        }
        if x < map.width - 1 && map.tile(x + 1, y).type == .Floor {
            visibility.unionInPlace(.Right)
        }
        if y > 0 && map.tile(x, y - 1).type == .Floor {
            visibility.unionInPlace(.Top)
        }
        if y < map.height - 1 && map.tile(x, y + 1).type == .Floor {
            visibility.unionInPlace(.Bottom)
        }
        return visibility
    }
    
    init(map: Map, x: Int, y: Int) {
        
        self.map = map
        self.x = x
        self.y = y
    }
}