//  Protocol.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-06.

import Foundation

enum Constants {
    static let protocolId   = Data("SCv2".utf8)
    static let serverprefix = Data("SC-SIG01".utf8)
    static let clientprefix = Data("SC-SIG02".utf8)
}

protocol Protocol {
    func m1(time: TimeInterval, myEncPub: Data) throws -> Data
    func m2(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data)
    func m3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: TimeInterval, remoteSignPub: Data)
    func m4(time: TimeInterval, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data
    
    func a1(time: TimeInterval, message: Data) -> Data
    func a2(data: Data) throws -> (time: TimeInterval, message: Data)
    
    func app(time: TimeInterval, message: Data) -> Data
    func multiApp(data: Data) throws -> (time: TimeInterval, message: Data)
}
