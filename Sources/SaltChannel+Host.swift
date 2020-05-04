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
    public func unpackM1(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data) {
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
        let (time, _) = unpackInteger(data.subdata(in: 6 ..< 10), count: 4)
        let remoteEncPub = data.subdata(in: 10 ..< data.endIndex)
        guard remoteEncPub.count == 32 else {
            throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong. \(time)")
        }

        let realtime = TimeInterval(time)
        os_log("M1 returning. Time=%@", log: log, type: .debug, realtime)
        return (realtime, remoteEncPub, Data(bytes: hash))
    }

    func packM2(time: TimeInterval, myEncPub: Data) throws -> (hash: Data, data: Data) {
        let header = createHeader(from: PacketType.m2)

        // TODO: better toBytes for Double
        let tData = Data(UInt32(time).toBytes())
        let m2 = header + tData + myEncPub

        os_log("Host: Write called from M2 salt handshake", log: log, type: .debug)
        return ( hash: Data(bytes: sodium.genericHash.hashSha512(data: m2)), data: m2)
    }

    public func packM3(time: TimeInterval, hostSignSec: Data, hostSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data {
        let header = createHeader(from: PacketType.m3)
        let signedMessage = Constants.serverprefix + m1Hash + m2Hash
        guard let signature = createSignature(message: signedMessage, signSec: hostSignSec) else {
            throw ChannelError.couldNotCreateSignature
        }

        let tData = Data(UInt32(time).toBytes())
        return header + tData + hostSignPub + signature
    }

    func unpackM4(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: TimeInterval, remoteSignPub: Data) {
        os_log("Host: Read called from M4 salt handshake.", log: log, type: .debug)

        guard data.count == 102 else {
            throw ChannelError.errorInMessage(reason: "Size is too small")
        }

        let header = data[..<2]

        let (type, _, _) = readHeader(from: header)
        guard type == PacketType.m4 else {
            throw ChannelError.badMessageType(reason: "Expected M4 Header")
        }

        // TODO: better unpack for Integer and convert to Double
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let remoteSignPub = data.subdata(in: 6 ..< 38)
        let sign = data.subdata(in: 38 ..< data.endIndex)
        guard sign.count == 64 else {
            throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong")
        }
        let signedMessage = Constants.clientprefix + m1Hash + m2Hash
        guard validateSignature(sign: sign, signPub: remoteSignPub, signedData: signedMessage) else {
            throw ChannelError.signatureDidNotMatch
        }

        let realtime = TimeInterval(time)
        os_log("M4 returning. Time= %@", log: log, type: .debug, realtime)
        return (realtime, remoteSignPub)
    }

    func packA2(time: TimeInterval, message: Data) -> Data {
        // TODO
        return Data()
    }

    func unpackA1(data: Data) throws -> (time: TimeInterval, message: Data) {
        // TODO
        return (1, Data())
    }
}
