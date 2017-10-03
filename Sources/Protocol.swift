//  Protocol.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation
import CocoaLumberjack

enum PacketType: Int {
    case m1 = 1, m2 = 2, m3 = 3, m4 = 4, appPacket = 5, encrypted = 6
}

protocol Protocol {
    func m1(time: Double, myEncPub: Data) throws -> Data
    func m2() throws -> (time: Double, remoteEncPub: Data, hash: Data)
    func m3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: Double, remoteSignPub: Data)
    func m4(time: Double, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data
}

extension SaltChannel: Protocol {

    func m1(time: Double, myEncPub: Data) throws -> Data {
        let protocolId = "SCv2"
        let header = createHeader(packageType: PacketType.m1)
        
        let m1 = Data(protocolId.utf8) + header + packBytes(UInt64(time), parts: 4) + myEncPub
        DDLogInfo("write called from m1 salt handshake")
        try self.channel.write([m1])
        
        return sodium.genericHash.hashSha512(data: m1)
    }
    
    func m2() throws -> (time: Double, remoteEncPub: Data, hash: Data) {
        DDLogInfo("read called from m2 salt handshake")
        let data = try channel.read()
        let hash = sodium.genericHash.hashSha512(data: data)
        let header = data.subdata(in: 0 ..< 2)
        guard readHeader(header: header) == PacketType.m2 else {
            throw ChannelError.gotWrongMessage
        }
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let remoteEncPub = data.subdata(in: 6 ..< data.endIndex)
        guard remoteEncPub.count == 32 else {
            throw ChannelError.errorInMessage
        }
        return (Double(time), remoteEncPub, hash)
    }
    
    func m3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: Double, remoteSignPub: Data) {
        let header = data.subdata(in: 0 ..< 2)
        guard readHeader(header: header) == PacketType.m3 else {
            throw ChannelError.gotWrongMessage
        }
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let remoteSignPub = data.subdata(in: 6 ..< 38)
        let sign = data.subdata(in: 38 ..< data.endIndex)
        guard sign.count == 64 else {
            throw ChannelError.errorInMessage
        }
        let signedMessage = m1Hash + m2Hash
        
        guard validateSignature(sign: sign, signPub: remoteSignPub, signedData: signedMessage) else {
            throw ChannelError.signatureDidNotMatch
        }
        
        return (Double(time), remoteSignPub)
    }
    
    func m4(time: Double, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data {
        let header = createHeader(packageType: PacketType.m4)
        let signedMessage = m1Hash + m2Hash
        guard let signature = createSignature(message: signedMessage, signSec: clientSignSec) else {
            throw ChannelError.couldNotCreateSignature
        }
        return header + packBytes(UInt64(time), parts: 4) + clientSignPub + signature
    }
    
    func createHeader(packageType: PacketType) -> Data {
        let type = packBytes(UInt64(packageType.rawValue), parts: 1)
        let dummy = packBytes(0, parts: 1)
        return type + dummy
    }
    
    func readHeader(header: Data) -> PacketType {
        return PacketType(rawValue: Int(header.first!))!
    }
}
