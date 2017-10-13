//  Protocol.swift
//  SaltChannel
//
//  Created by Håkan Ohlsson/Kenneth Pernyer on 2017-10-02.

import Foundation
import os.log

extension SaltChannel: Protocol {

    ///- Client --

    /**
     ##M1## is sent to the server in plain
     */
    public func writeM1(time: TimeInterval, myEncPub: Data, serverSignPub: Data? = nil) throws -> Data {
        
        let serverSignKeys = (serverSignPub != nil)
        let header = createHeader(from: PacketType.M1, first: serverSignKeys)
        
        // TODO: better toBytes for Double
        var m1 = Constants.protocolId + header + packBytes(UInt64(time), parts: 4) + myEncPub
        if let serverKeys = serverSignPub {
            os_log("Client: Using Server Sign PubKeys %{public}s", log: log, type: .debug, serverKeys as CVarArg)
            m1 = m1 + serverKeys
        } else {
            // TODO
        }
        os_log("Client: Write called from M1 salt handshake", log: log, type: .debug)
        try self.channel.write([m1])
        
        return sodium.genericHash.hashSha512(data: m1)
    }
    
    /**
     ##M2## sent from the server in plain
     */
    public func readM2(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data) {
        os_log("Client: Read called from M2 salt handshake.", log: log, type: .debug)
        
        let hash = sodium.genericHash.hashSha512(data: data)
        let header = data[..<2]
        
        let (type, nosuch, last) = self.readHeader(from: header)
        guard (nosuch && last) || (!nosuch && !last) else {
            throw ChannelError.errorInMessage(reason:
                "NoSuchMessage and Last must both be set or none of them")
        }
        guard type == PacketType.M2 else {
            throw ChannelError.badMessageType(reason: "Expected M2 Header ")
        }
        
        if (last) {
            guard let session = session else {
                throw ChannelError.setupNotDone(reason: "Client: No session object in M2")
            }
            session.lastMessageReceived = true
            os_log("Client: last message flag received.", log: log, type: .debug)
        }
        
        // TODO: better unpack for Integer and convert to Double
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let remoteEncPub = data.subdata(in: 6 ..< data.endIndex)
        
        guard !nosuch || (nosuch && isNullContent(data: remoteEncPub)) else {
            throw ChannelError.errorInMessage(reason:
                "No such server set, but still sent remoteEncPub. \(time)")
        }
        
        guard remoteEncPub.count == 32 else {
            throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong. \(time)")
        }
        
        let realtime = TimeInterval(time)
        os_log("M2 returning. Time= %{public}s", log: log, type: .debug, realtime)
        return (realtime, remoteEncPub, hash)
    }
    
    /**
     ##M3## sent from the server encrypted for me. Decrypted before this call using
     receiveAndDecryptMessage()
     */
    public func readM3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: TimeInterval, remoteSignPub: Data) {
        os_log("Client: Read called from M3 salt handshake.", log: log, type: .debug)
       let header = data[..<2]
        
        let (type, _, _) = readHeader(from: header)
        guard type == PacketType.M3 else {
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
        os_log("M3 returning. Time= %{public}s", log: log, type: .debug, realtime)
        return (realtime, remoteSignPub)
    }
    
    /**
     ##M4## is sent to the server encrypted
     */
    public func writeM4(time: TimeInterval, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data {
        let header = createHeader(from: PacketType.M4)
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
    public func writeA1(time: TimeInterval, message: Data) -> Data {
        // TODO
        return Data()
    }
    
    /**
     */
    public func readA2(data: Data) throws -> [String] {
        let header = data[..<2]
        let (type, nosuch, last) = self.readHeader(from: header)
        guard (nosuch && last) || (!nosuch && !last) else {
            throw ChannelError.errorInMessage(reason:
                "NoSuchMessage and Last must both be set or none of them")
        }
    
        guard type == PacketType.A2 else {
            throw ChannelError.badMessageType(reason: "Expected A2 message header")
        }
        
        if (last) {
            guard let session = session else {
                throw ChannelError.setupNotDone(reason: "Client: No session object in A2")
            }
            session.lastMessageReceived = true
        }
        
        return try extractProtocols(data: data[2...])
    }
    
    /**
     */
    func writeApp(time: TimeInterval, message: Data) -> Data {
        let header = createHeader(from: PacketType.App)
        return header + packBytes(UInt64(time), parts: 4) + message
    }
    
    /**
     */
    public func readApp(data: Data) throws -> (time: TimeInterval, message: Data) {
        let header = data[..<2]
        let (type, _, _) = readHeader(from: header)
        guard  type == PacketType.App else {
            throw ChannelError.badMessageType(reason: "Expected App message header")
        }
        
        // TODO: better unpack for Time
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let message = data.subdata(in: 6 ..< data.endIndex)
        return (Double(time), message)
    }
    
    /**
     ##MultiApp## is multiple messages batched together in the application layer protocol
     */
    func writeMultiApp(data: Data) throws -> (time: TimeInterval, message: Data) {
        let header = createHeader(from: PacketType.MultiApp)
        let time = self.session!.time
        let message = header + packBytes(UInt64(time), parts: 4)
        return (time, message)
    }
    
    ///- Host --
    
    /**
     ##M1## is sent to the server in plain
     */
    public func readM1(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data) {
        os_log("Host: unpack M1", log: log, type: .debug)

        let hash = sodium.genericHash.hashSha512(data: data)
        let protocolId = data[..<4]
        guard protocolId ==  Constants.protocolId else {
            throw ChannelError.badMessageType(reason: "Expected M1 Header")
        }
        
        let header = data[4..<6]
        let (type, _, last) = readHeader(from: header)
        guard type == PacketType.M1 else {
            throw ChannelError.badMessageType(reason: "Expected M1 Header")
        }
        
        if (last) {
            guard let session = session else {
                throw ChannelError.setupNotDone(reason: "Host: No session object in M1")
            }
            session.lastMessageReceived = true
        }
        
        // TODO: better unpack for Integer and convert to Double
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let remoteEncPub = data.subdata(in: 6 ..< data.endIndex)
        guard remoteEncPub.count == 32 else {
            throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong. \(time)")
        }
        
        let realtime = TimeInterval(time)
        os_log("M1 returning. Time= %{public}s", log: log, type: .debug, realtime)
        return (realtime, remoteEncPub, hash)
    }
}

public func extractProtocols(data: Data) throws -> [String] {
    var versionArray: [String] = []
    let length: Int = 10
    let size = data.count
    let n = data[0]

    guard size > length, (size - 1) % length == 0, (length * Int(n)) == (size-1) else {
        throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong.")
    }
    
    for i in stride(from: 1, to: n*10, by: 10) {
        let protocolData = data[i ..< i + 10]
        let protocolString = String(data: protocolData, encoding: .utf8)
        versionArray.append(protocolString ?? "SCBullshit")
    }
    
    return versionArray
}
