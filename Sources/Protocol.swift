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

// typealias Protocol = Client & Host
typealias Protocol = Client

protocol Client {
    func writeM1(time: TimeInterval, myEncPub: Data) throws -> Data
    func readM2(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data)
    func readM3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: TimeInterval, remoteSignPub: Data)
    func writeM4(time: TimeInterval, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data
    
    func writeA1(time: TimeInterval, message: Data) -> Data
    func readA2(data: Data) throws -> (time: TimeInterval, message: Data)
    
    func writeApp(time: TimeInterval, message: Data) -> Data
    func writeMultiApp(data: Data) throws -> (time: TimeInterval, message: Data)
}

protocol Host {
    func readM1(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data)
    func writeM2(time: TimeInterval, myEncPub: Data) throws -> Data
    func writeM3(time: TimeInterval, myEncPub: Data) throws -> Data
    func readM4(data: Data) throws -> (time: TimeInterval, message: Data)
    
    func writeA2(time: TimeInterval, message: Data) -> Data
    func readA1(data: Data) throws -> (time: TimeInterval, message: Data)
}
