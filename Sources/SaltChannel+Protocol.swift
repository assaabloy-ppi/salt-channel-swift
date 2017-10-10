//  Protocol.swift
//  SaltChannel
//
//  Created by Håkan Ohlsson/Kenneth Pernyer on 2017-10-02.

import Foundation
import CocoaLumberjack

extension SaltChannel: Protocol {
    /**
     ##M1## is sent to the server in plain
     */
    public func m1(time: TimeInterval, myEncPub: Data) throws -> Data {
        let header = create(from: PacketType.M1)
        
        // TODO: better toBytes for Double
        let m1 = Constants.protocolId + header + packBytes(UInt64(time), parts: 4) + myEncPub
        DDLogInfo("Write called from M1 salt handshake")
        try self.channel.write([m1])
        
        return sodium.genericHash.hashSha512(data: m1)
    }
    
    /**
     ##M1## is sent to the server in plain
     */
    public func unpackmM1(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data) {
        DDLogInfo("Host: unpack M1")
        let hash = sodium.genericHash.hashSha512(data: data)
        let protocolId = data[..<4]
        guard protocolId ==  Constants.protocolId else {
            throw ChannelError.badMessageType(reason: "Expected M1 Header")
        }
        
        let header = data[4..<6]
        guard read(header: header) == PacketType.M1 else {
            throw ChannelError.badMessageType(reason: "Expected M1 Header")
        }
        // TODO: better unpack for Integer and convert to Double
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let remoteEncPub = data.subdata(in: 6 ..< data.endIndex)
        guard remoteEncPub.count == 32 else {
            throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong. /(time)")
        }
        
        let realtime = TimeInterval(time)
        DDLogInfo("M2 returning. Time= /(realtime)")
        return (realtime, remoteEncPub, hash)
    }
    
    /**
     ##M2## sent from the server in plain
     */
    public func m2(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data) {
        DDLogInfo("Client: Read called from M2 salt handshake.")
        let hash = sodium.genericHash.hashSha512(data: data)
        let header = data[..<2]
        guard read(header: header) == PacketType.M2 else {
            print(header.hex)
            throw ChannelError.badMessageType(reason: "Expected M2 Header")
        }
        // TODO: better unpack for Integer and convert to Double
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let remoteEncPub = data.subdata(in: 6 ..< data.endIndex)
        guard remoteEncPub.count == 32 else {
            throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong. /(time)")
        }
        
        let realtime = TimeInterval(time)
        DDLogInfo("M2 returning. Time= /(realtime)")
        return (realtime, remoteEncPub, hash)
    }
    
    /**
     ##M3## sent from the server encrypted for me. Decrypted before this call using
     receiveAndDecryptMessage()
     */
    public func m3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: TimeInterval, remoteSignPub: Data) {
        let header = data[..<2]
        
        print(header.hex)
        print(data.hex)
        
        guard read(header: header) == PacketType.M3 else {
            throw ChannelError.badMessageType(reason: "Expected M3 Header")
        }
        
        // TODO: better unpack for Integer and convert to Double
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let remoteSignPub = data.subdata(in: 6 ..< 38)
        let sign = data.subdata(in: 38 ..< data.endIndex)
        guard sign.count == 64 else {
            throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong")
        }
        let signedMessage = Constants.serverprefix + m1Hash + m2Hash
        guard validateSignature(sign: sign, signPub: remoteSignPub, signedData: signedMessage) else {
            throw ChannelError.signatureDidNotMatch
        }
        
        let realtime = TimeInterval(time)
        DDLogInfo("M3 returning. Time= /(realtime)")
        return (realtime, remoteSignPub)
    }
    
    /**
     ##M4## is sent to the server encrypted
     */
    public func m4(time: TimeInterval, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data {
        let header = create(from: PacketType.M4)
        let signedMessage = Constants.clientprefix + m1Hash + m2Hash
        guard let signature = createSignature(message: signedMessage, signSec: clientSignSec) else {
            throw ChannelError.couldNotCreateSignature
        }
        
        // TODO: better pack for Time
        return header + packBytes(UInt64(time), parts: 4) + clientSignPub + signature
    }
    
    /**
     ##A1## is sent to the server in the open
     */
    public func a1(time: TimeInterval, message: Data) -> Data {
        let header = create(from: PacketType.App)
        return header + packBytes(UInt64(time), parts: 4) + message
    }
    
    /**
     */
    public func a2(data: Data) throws -> (time: TimeInterval, message: Data) {
        let header = data[..<2]
        print(header.hex)
        print(data.hex)
        guard read(header: header) == PacketType.App else {
            throw ChannelError.badMessageType(reason: "Expected A2 message header")
        }
        
        // TODO: better unpack for Time
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let message = data.subdata(in: 6 ..< data.endIndex)
        return (Double(time), message)
    }
    
    /**
     */
    func app(time: TimeInterval, message: Data) -> Data {
        return Data()
    }
    
    /**
     ##MultiApp## is multiple messages batched together in the application layer protocol
     */
    func multiApp(data: Data) throws -> (time: TimeInterval, message: Data) {
        return (0, Data())
    }
}

