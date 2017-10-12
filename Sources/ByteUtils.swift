//  ByteUtils.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

extension UInt32 {
    
    enum ByteOrder {
        case BigEndian
        case LittleEndian
    }
    
    func toBytes(_ order: ByteOrder = .LittleEndian) -> [UInt8] {
        var bytes: [UInt8] = [0, 0, 0, 0]
        var value: UInt32 = self.littleEndian
        if order == .BigEndian {
            value = self.bigEndian
        }
        bytes[0] = UInt8(value & 0x000000FF)
        bytes[1] = UInt8((value & 0x0000FF00) >> 8) //0x12345678 => 0x00005600 >> 8 => 0x00000056
        bytes[2] = UInt8((value & 0x00FF0000) >> 16)
        bytes[3] = UInt8((value & 0xFF000000) >> 24)
        return bytes
    }
    
    static func fromBytes(_ sizeBytes: [UInt8], order: ByteOrder = .LittleEndian) -> UInt32 {
        var value: UInt32 = 0
        value += UInt32(sizeBytes[0])
        value += UInt32(sizeBytes[1]) << 8
        value += UInt32(sizeBytes[2]) << 16
        value += UInt32(sizeBytes[3]) << 24
        if order == .BigEndian {
            return value.bigEndian
        }
        return value
    }
}

public func isNullContent(data: Data) -> Bool {
    return data.reduce(true) { $0 && ($1 == 0) }
}

public func packBytes(_ value: UInt64, parts: Int) -> Data {
    precondition(parts > 0)
    
    let bytesw = stride(from: (8 * (parts - 1)), through: 0, by: -8).map { shift in
        return UInt8(truncatingIfNeeded: value >> UInt64(shift))
    }
    
    return Data(bytesw)
}

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
