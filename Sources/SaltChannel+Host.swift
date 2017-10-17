//  SaltChannel+Host.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-16.

import Foundation
import os.log

extension SaltChannel: Host {
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
        guard type == PacketType.m1 else {
            throw ChannelError.badMessageType(reason: "Expected M1 Header")
        }
        
        if last {
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
    
    func writeM2(time: TimeInterval, myEncPub: Data) throws -> Data {
        // TODO
        return Data()
    }
    
    func writeM3(time: TimeInterval, myEncPub: Data) throws -> Data {
        // TODO
        return Data()
    }
    
    func readM4(data: Data) throws -> (time: TimeInterval, message: Data) {
        // TODO
        return (1, Data())
    }
    
    func writeA2(time: TimeInterval, message: Data) -> Data {
        // TODO
        return Data()
    }
    
    func readA1(data: Data) throws -> (time: TimeInterval, message: Data) {
        // TODO
        return (1, Data())
    }
}
