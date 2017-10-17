//  Crypto.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-03.

import Foundation
import os.log

protocol Crypto {

}

extension SaltChannel: Crypto {
    public func receiveAndDecryptMessage(message: Data, session: Session) throws -> Data {
        os_log("Client: read called from receiveAndDecryptMessage salt handshake", log: log, type: .debug)
        let header = message[..<2]
        let (type, _, lastMessageFlag) = readHeader(from: header)
        guard type == PacketType.encrypted else {
            throw ChannelError.badMessageType(reason: "Expected Encrypted PacketType Header")
        }
        
        // TODO: check semantics for lastMsg
        if lastMessageFlag {
            session.lastMessageReceived = true
            os_log("Client: last message flag set. what now?", log: log)
        }
        
        let encryptedData = message.subdata(in: 2 ..< message.endIndex)
        
        guard let decryptedData = sodium.box.open(authenticatedCipherText: encryptedData,
                                                  beforenm: session.key, nonce: receiveNonce.next()) else {
            throw ChannelError.couldNotDecrypt
        }
        
        return decryptedData
    }
    
    public func encryptMessage(session: Session, message: Data) -> Data {
        // Added for byte channel multicall, TODO: Review
        let header = createHeader(from: PacketType.encrypted)
        let encryptedMessage =  header +
            sodium.box.seal(message: message, beforenm: session.key,
                            nonce: sendNonce.next())!
        return encryptedMessage
    }
    
    public func encryptAndSendMessage(session: Session,
                                      message: Data, lastMessage: Bool = false) throws {
        let header = createHeader(from: PacketType.encrypted, last: lastMessage)
        let cipherData = sodium.box.seal(message: message, beforenm: session.key,
                                         nonce: sendNonce.next())!
        try self.channel.write([header + cipherData])
    }
    
    public func validateSignature(sign: Data, signPub: Data, signedData: Data) -> Bool {
        let message = sodium.sign.open(signedMessage: sign + signedData, publicKey: signPub)
        if message != nil {
            return true
        } else {
            return false
        }
    }
    
    public func createSignature(message: Data, signSec: Data) -> Data? {
        let rawSignature = sodium.sign.sign(message: message, secretKey: signSec)!
        return rawSignature.subdata(in: 0 ..< 64)
    }
    
    public func getRemoteSignPub() throws -> Data {
        guard let sign = self.remoteSignPub else {
            throw ChannelError.setupNotDone(reason: "No Host Sign Pub available")
        }
        
        return sign
    }
}
