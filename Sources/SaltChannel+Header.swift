//
//  SaltChannel+Header.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-09.

import Foundation

typealias Byte = UInt8

enum PacketType: Byte {
    case Unknown = 0, M1 = 1, M2 = 2, M3 = 3, M4 = 4, App = 5,
    Encrypted = 6, A1 = 8, A2 = 9, TT = 10, MultiApp = 11
    
    /**
     ````
     0            Not used
     1            M1
     2            M2
     3            M3
     4            M4
     5            App
     6            Encrypted
     7            Reserved (has been used for Ticket in v2 drafts)
     8            A1
     9            A2
     10           TT (not used in v2 spec)
     11           MultiApp
     12-127       Not used
     ´´´´
     */
    
    public var hex: String {
        return data.toHexString("0x")
    }
    
    public var data: Data {
        return Data(bytes: [rawValue])
    }
}

protocol Header {
    func createHeader(from packageType: PacketType, first: Bool, last: Bool) -> Data
    func readHeader(from data: Data) -> (type: PacketType, firstBit: Bool, lastBit: Bool)
}

extension SaltChannel: Header {
    func createHeader(from packageType: PacketType, first: Bool = false, last: Bool = false) -> Data {
        let type = packBytes(UInt64(packageType.rawValue), parts: 1)
        
        // TODO: optimize Data
        var bits: UInt8 = first ? 0b10000000: 0b00000000
        bits = bits | (last ? 0b00000001: 0b00000000)

        return type + Data(bytes: [bits])
    }
    
    func readHeader(from data: Data) -> (type: PacketType, firstBit: Bool, lastBit: Bool) {
        let unknown = (type: PacketType.Unknown, firstBit: false, lastBit: false)
        
        guard data.count == 2,
            let byte1 = data.first,
            let byte2 = data.last,
            let type = PacketType(rawValue: byte1) else {
            return unknown
        }

        let first = (byte2 & 0b10000000) != 0
        let last  = (byte2 & 0b00000001) != 0
        
        return (type, first, last)
    }
}
