//  Protocol.swift
//  SaltChannel
//
//  Created by Håkan Ohlsson/Kenneth Pernyer on 2017-10-02.

import Foundation
import os.log

extension SaltChannel: Client {
    enum A1Types {
        static let defaultAddress  = Data(bytes: [0x00])
        static let specificAddress = Data(bytes: [0x01])
    }
    
    /**
     ##M1## is sent to the server in plain
     **** M1 ****
     
     4   ProtocolIndicator.
     MUST be ASCII 'SCv2' for Salt Channel v2.
     Bytes: 0x53, 0x43, 0x76, 0x32
     
     2   Header.
     Message type and flags.
     
     4   Time.
     See separate documentation.
     
     32  ClientEncKey.
     The public ephemeral encryption key of the client.
     
     32  ServerSigKey, OPT.
     The server's public signing key. Used to choose what virtual
     server to connect to in cases when there are many to choose from.
     
     
     **** M1/Header ****
     
     1   PacketType.
     Integer in [0, 127]
     The value is 1 for this packet.
     
     1b  ServerSigKeyIncluded.
     Set to 1 when ServerSigKey is included in the message.
     
     7b  Zero.
     Bits set to 0.
     */
    public func packM1(time: TimeInterval, myEncPub: Data, serverSignPub: Data? = nil) throws -> (hash: Data, data: Data) {
        let serverSignKeys = (serverSignPub != nil)
        let header = createHeader(from: PacketType.m1, first: serverSignKeys)
        
        // TODO: better toBytes for Double
        let tData = Data(UInt32(time).toBytes())
        var m1 = Constants.protocolId + header + tData + myEncPub
        if let serverKeys = serverSignPub {
            os_log("Client: Using Server Sign PubKeys %@", log: log, type: .debug, serverKeys as CVarArg)
            m1 += serverKeys
        } else {
            // TODO
        }
        
        os_log("Client: Write called from M1 salt handshake", log: log, type: .debug)
        return ( hash: Data(bytes: sodium.genericHash.hashSha512(data: m1)), data: m1)
    }
    
    /**
     ##M2## sent from the server in plain
     **** M2 ****
     
     2   Header.
     Message type and flags.
     
     4   Time.
     See separate documentation.
     
     32  ServerEncKey.
     The public ephemeral encryption key of the server.
     
     **** M2/Header ****
     
     1   PacketType.
     Integer in [0, 127].
     The value is 2 for this packet.
     
     1b  NoSuchServer.
     Set to 1 if ServerSigKey was included in M1 but a server with such a
     public signature key does not exist at this end-point or could not be
     connected to. Note, when this happens, the client MUST ignore ServerEncKey.
     The server MUST send zero-valued bytes in ServerEncKey if this
     condition happens.
     
     6b  Zero.
     Bits set to zero.
     
     1b  LastFlag.
     Set to 1 when this is the last message of the session.
     That is, when the NoSuchServer bit is set.
     */
    public func unpackM2(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data) {
        os_log("Client: Read called from M2 salt handshake.", log: log, type: .debug)
        
        guard data.count == 38 else {
            throw ChannelError.errorInMessage(reason: "Size is too small")
        }
        
        let hash = sodium.genericHash.hashSha512(data: data)
        let header = data[..<2]
        
        let (type, nosuch, last) = self.readHeader(from: header)
        guard (nosuch && last) || (!nosuch && !last) else {
            throw ChannelError.errorInMessage(reason:
                "NoSuchMessage and Last must both be set or none of them")
        }
        guard type == PacketType.m2 else {
            throw ChannelError.badMessageType(reason: "Expected M2 Header ")
        }
        
        if last {
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
        os_log("M2 returning. Time=%@", log: log, type: .debug, realtime)
        return (realtime, remoteEncPub, Data(bytes: hash))
    }
    
    /**
     ##M3## sent from the server encrypted for me. Decrypted before this call using
     receiveAndDecryptMessage()
     
     **** M3 ****
     
     This packet is encrypted. It is sent within the body of EncryptedMessage
     (EncryptedMessage/Body).
     
     2   Header.
     Message type and flags.
     
     4   Time.
     See separate documentation.
     
     32  ServerSigKey.
     The server's public signature key. Must be included even when
     it was specified in M1 (to keep things simple).
     
     64  Signature1
     The following: sig("SC-SIG01" + hash(M1) + hash(M2)).
     "SC-SIG01" are the bytes: 0x53, 0x43, 0x2d, 0x53, 0x49, 0x47, 0x30, 0x31.
     hash() is used to denote the SHA512 checksum.
     "+" is concatenation and "sig" is defined on the "Crypto details" section.
     Only the actual signature (64 bytes) is included in the field.
     
     
     **** M3/Header ****
     
     1   PacketType.
     Integer in [0, 127].
     The value is 3 for this packet.
     
     8b  Zero.
     Bits set to 0.
     
     */
    public func unpackM3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: TimeInterval, remoteSignPub: Data) {
        os_log("Client: Read called from M3 salt handshake.", log: log, type: .debug)
        
        guard data.count == 102 else {
            throw ChannelError.errorInMessage(reason: "Size is too small")
        }
        
       let header = data[..<2]
        
        let (type, _, _) = readHeader(from: header)
        guard type == PacketType.m3 else {
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
        os_log("M3 returning. Time= %@", log: log, type: .debug, realtime)
        return (realtime, remoteSignPub)
    }
    
    /**
     ##M4## is sent to the server encrypted
     
     */
    public func packM4(time: TimeInterval, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data {
        let header = createHeader(from: PacketType.m4)
        let signedMessage = Constants.clientprefix + m1Hash + m2Hash
        guard let signature = createSignature(message: signedMessage, signSec: clientSignSec) else {
            throw ChannelError.couldNotCreateSignature
        }
        
        let tData = Data(UInt32(time).toBytes())
        return header + tData + clientSignPub + signature
    }
    
    /**
     ##A1## is sent to the server in the open. We support two addressing types for now
     
     2   Header.
     Message type and flags.
     
     1   AddressType
     Type of address that follows.
     MUST be 0 for the default address on the server.
     MUST be 1 for Salt Channel v2 public key (32 bytes).
     
     2   AddressSize
     Byte size of Address field that follows.
     Integer in [0, 65535].
     
     x   Address
     The address.
     */
    public func packA1(pubKey: Data? = nil) throws -> Data {
        let header = createHeader(from: PacketType.a1)
        var a1 = header

        if let garanteedPubKey = pubKey {
            guard garanteedPubKey.count == 32 else {
                throw ChannelError.badMessageType(reason: "Expected PubKey of size 32")
            }
            a1 += A1Types.specificAddress + Data(bytes: [0x00, 0x20]) + garanteedPubKey
        } else {
            a1 += A1Types.defaultAddress + Data(bytes: [0x00, 0x00])
        }
        
        return a1
    }
    
    /**
     **** A2 ****
     
     The message sent by the server in response to an A1 message.
     
     2   Header.
     Message type and flags.
     
     1   Count
     Integer in [0, 127].
     The number of protocol entries (Prot) that follows.
     
     x   Prot+
     1 to 127 Prot packets.
     
     0x09, 0x80, 0x01, 0x53, 0x43, 0x32, 0x2d, 0x2d,
     0x2d, 0x2d, 0x2d, 0x2d, 0x2d, 0x45, 0x43, 0x48,
     0x4f, 0x2d, 0x2d, 0x2d, 0x2d, 0x2d, 0x2d
     
     **** A2/Header ****
     
     1   PacketType.
     Integer in [0, 127].
     The value is 9 for this packet.
     
     1b  NoSuchServer.
     Set to 1 if no server could be found or connected to that matches
     the Address field of A1. When this bit is set, A2/Count MUST
     have the value 0.
     
     6b  Zero.
     Bits set to zero.
     
     1b  LastFlag.
     Always set to 1 for this message to indicate that this is
     the last message of the the session.
     
     
     **** A2/Prot ****
     
     10  P1.
     Protocol ID of Salt Channel with version.
     Exactly 10 ASCII bytes. The value for this field in for this version
     of Salt Channel MUST BE "SCv2------".
     
     10  P2.
     Protocol ID of the protocol on top of Salt Channel.
     Exactly 10 ASCII bytes. If the server does not wish to reveal any
     information about the layer above, the server MUST use value
     "----------" for this field.
     */
    public func unpackA2(data: Data) throws -> SaltChannelProtocols {
        guard data.count >= 3 else {
            throw ChannelError.errorInMessage(reason: "Size is to small")
        }
        
        let header = data[..<2]
        let (type, nosuch, last) = self.readHeader(from: header)
        
        guard last else {
            throw ChannelError.errorInMessage(reason:
                "Last Bit should always be set for A2")
        }
    
        /* ToDo Shall this be here
        guard let session = session else {
            throw ChannelError.setupNotDone(reason: "Client: No session object in A2")
        }
        
        session.lastMessageReceived = true
         */
 
        guard type == PacketType.a2 else {
            throw ChannelError.badMessageType(reason: "Expected A2 message header")
        }
        
        let number = data[2]
        
        guard !nosuch || (nosuch && number == 0) else {
            throw ChannelError.badMessageType(reason: "No such server should not return protocols")
        }
        
        guard !nosuch && data.count >= 23 else {
            throw ChannelError.badMessageType(reason: "No such server and data to large")
        }
        
        let rest = data[3...]
        return try extractProtocols(n: Int(number), data: Data(rest))
    }
}

func extractProtocols(n: Int, data: Data) throws -> SaltChannelProtocols {
    var protocols = SaltChannelProtocols()
    let chunk: Int = 20
    let half: Int = chunk/2
    let size = data.count

    guard size != 0, size % chunk == 0, (chunk * Int(n)) == size else {
        throw ChannelError.errorInMessage(reason: "Size of Messsage is wrong.")
    }
    
    for i in stride(from: 0, to: n*chunk, by: chunk) {
        let part1 = data[i..<(i+half)]
        let part2 = data[i+half..<i+chunk]
        let str1 = String(data: part1, encoding: .utf8)!
        let str2 = String(data: part2, encoding: .utf8)!

        protocols.append(SaltChannelProtocol(first: str1, second: str2))
    }
    
    return protocols
}
