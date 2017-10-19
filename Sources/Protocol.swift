//  Protocol.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-06.

import Foundation

enum Constants {
    static let protocolId   = Data("SCv2".utf8)
    static let serverprefix = Data("SC-SIG01".utf8)
    static let clientprefix = Data("SC-SIG02".utf8)
    
    static let a1Type0 = Data(bytes: [0x00])
    static let a1Type1 = Data(bytes: [0x01])
}

typealias Protocol = Client & Host

protocol Peer {
    func writeApp(time: TimeInterval, message: Data) throws -> Data
    func writeMultiApp(message: Data) throws -> (time: TimeInterval, message: Data)
    
    func readApp(data: Data) throws -> (time: TimeInterval, message: Data)
    func readMultiApp(data: Data) throws -> [String]
}

protocol Client: Peer {
    func writeM1(time: TimeInterval, myEncPub: Data, serverSignPub: Data?) throws -> Data
    func readM2(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data)
    func readM3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: TimeInterval, remoteSignPub: Data)
    func writeM4(time: TimeInterval, clientSignSec: Data, clientSignPub: Data,
                 m1Hash: Data, m2Hash: Data) throws -> Data

    func writeA1(type: Int, pubKey: Data?) throws -> Data
    func readA2(data: Data) throws -> [(first: String, second: String)]?
}

protocol Host: Peer {
    func readM1(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data)
    func writeM2(time: TimeInterval, myEncPub: Data) throws -> Data
    func writeM3(time: TimeInterval, myEncPub: Data) throws -> Data
    func readM4(data: Data) throws -> (time: TimeInterval, message: Data)

    func writeA2(time: TimeInterval, message: Data) throws -> Data
    func readA1(data: Data) throws -> (time: TimeInterval, message: Data)
}
