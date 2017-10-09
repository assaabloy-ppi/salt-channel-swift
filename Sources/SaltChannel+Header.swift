//
//  File.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-09.
//

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
}

protocol Header {
    func create(from packageType: PacketType) -> Data
    func read(header: Data) -> PacketType
}

extension SaltChannel: Header {
    func create(from packageType: PacketType) -> Data {
        let type = packBytes(UInt64(packageType.rawValue), parts: 1)
        let dummy = packBytes(0, parts: 1)
        return type + dummy
    }
    
    func read(header: Data) -> PacketType {
        guard let byte = header.first else {
            return .Unknown
        }
        
        if let type = PacketType(rawValue: byte) {
            return type
        } else {
            return .Unknown
        }
    }
}
