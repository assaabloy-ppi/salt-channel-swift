//  Misc.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-06-08.

import Foundation

func unpackInteger(_ data: Data, count: Int) -> (value: UInt64, remainder: Data) {
    /*
    guard count > 0 else {
        throw Error
    }
    
    guard data.count >= count else {
        throw Error
    }
    */
    
    var value: UInt64 = 0
    for i in 0 ..< count {
        let byte = data[i]
        value = value << 8 | UInt64(byte)
    }
    
    return (value, data.subdata(in: count ..< data.count))
}
