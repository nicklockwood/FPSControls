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

//http://natecook.com/blog/2014/07/swift-options-bitmask-generator/
struct FaceVisibility : RawOptionSetType {
    
    typealias RawValue = UInt
    private var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    init(rawValue value: UInt) { self.value = value }
    init(nilLiteral: ()) { self.value = 0 }
    static var allZeros: FaceVisibility { return self(0) }
    static func fromMask(raw: UInt) -> FaceVisibility { return self(raw) }
    var rawValue: UInt { return self.value }
    
    static var None: FaceVisibility { return self(0) }
    static var Top: FaceVisibility { return FaceVisibility(1 << 0) }
    static var Right: FaceVisibility { return FaceVisibility(1 << 1) }
    static var Bottom: FaceVisibility { return FaceVisibility(1 << 2) }
    static var Left: FaceVisibility { return FaceVisibility(1 << 3) }
}

class Tile {
    
    unowned let map: Map
    let x, y: Int
    var type: TileType = .Rock
    var visibility: FaceVisibility {
        var visibility: FaceVisibility = .None
        if x > 0 && map.tile(x - 1, y).type == .Floor {
            visibility |= .Left
        }
        if x < map.width - 1 && map.tile(x + 1, y).type == .Floor {
            visibility |= .Right
        }
        if y > 0 && map.tile(x, y - 1).type == .Floor {
            visibility |= .Top
        }
        if y < map.height - 1 && map.tile(x, y + 1).type == .Floor {
            visibility |= .Bottom
        }
        return visibility
    }
    
    init(map: Map, x: Int, y: Int) {
        
        self.map = map
        self.x = x
        self.y = y
    }
}