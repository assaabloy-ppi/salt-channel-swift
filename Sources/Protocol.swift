//  Protocol.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-06.

import Foundation

enum PacketType: UInt8 {
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

enum Constants {
    static let protocolId   = Data("SCv2".utf8)
    static let serverprefix = Data("SC-SIG01".utf8)
    static let clientprefix = Data("SC-SIG02".utf8)
}

protocol Protocol {
    func m1(time: Double, myEncPub: Data) throws -> Data
    func m2(data: Data) throws -> (time: Double, remoteEncPub: Data, hash: Data)
    func m3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: Double, remoteSignPub: Data)
    func m4(time: Double, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data
    
    func a1(time: Double, message: Data) -> Data
    func a2(data: Data) throws -> (time: Double, message: Data)
    
    func app(time: Double, message: Data) -> Data
    func multiApp(data: Data) throws -> (time: Double, message: Data)
}

