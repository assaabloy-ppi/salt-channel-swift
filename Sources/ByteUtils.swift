//  ByteUtils.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

enum ByteOrder {
    case bigEndian
    case littleEndian
}

extension UInt32 {
    func toBytes(_ order: ByteOrder = .littleEndian) -> [Byte] {
        var bytes: [Byte] = [0, 0, 0, 0]
        var value: UInt32 = self.littleEndian
        if order == .bigEndian {
            value = self.bigEndian
        }
        bytes[0] = Byte(value & 0x000000FF)
        bytes[1] = Byte((value & 0x0000FF00) >> 8)
        bytes[2] = Byte((value & 0x00FF0000) >> 16)
        bytes[3] = Byte((value & 0xFF000000) >> 24)
        return bytes
    }
    
    static func fromBytes(_ sizeBytes: [Byte], order: ByteOrder = .littleEndian) -> UInt32 {
        var value: UInt32 = 0
        value += UInt32(sizeBytes[0])
        value += UInt32(sizeBytes[1]) << 8
        value += UInt32(sizeBytes[2]) << 16
        value += UInt32(sizeBytes[3]) << 24
        if order == .bigEndian {
            return value.bigEndian
        }
        return value
    }
}

extension UInt64 {
    func toBytes(_ order: ByteOrder = .littleEndian) -> [Byte] {
        var bytes: [Byte] = [0, 0, 0, 0, 0, 0, 0, 0]
        var value: UInt64 = self.littleEndian
        if order == .bigEndian {
            value = self.bigEndian
        }
        bytes[0] = Byte((value & 0x00000000000000FF))
        bytes[1] = Byte((value & 0x000000000000FF00) >> 8)
        bytes[2] = Byte((value & 0x0000000000FF0000) >> 16)
        bytes[3] = Byte((value & 0x00000000FF000000) >> 24)
        bytes[4] = Byte((value & 0x000000FF00000000) >> 32)
        bytes[5] = Byte((value & 0x0000FF0000000000) >> 40)
        bytes[6] = Byte((value & 0x00FF000000000000) >> 48)
        bytes[7] = Byte((value & 0xFF00000000000000) >> 56)
        return bytes
    }
    
    static func fromBytes(_ sizeBytes: [UInt8], order: ByteOrder = .littleEndian) -> UInt64 {
        var value: UInt64 = 0
        value += UInt64(sizeBytes[0])
        value += UInt64(sizeBytes[1]) << 8
        value += UInt64(sizeBytes[2]) << 16
        value += UInt64(sizeBytes[3]) << 24
        value += UInt64(sizeBytes[4]) << 32
        value += UInt64(sizeBytes[5]) << 40
        value += UInt64(sizeBytes[6]) << 48
        value += UInt64(sizeBytes[7]) << 56
        if order == .bigEndian {
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
    
    return Data(bytesw.reversed())
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
        let byte = data[count-i-1]
        value = value << 8 | UInt64(byte)
    }
    
    return (value, data.subdata(in: count ..< data.count))
}
