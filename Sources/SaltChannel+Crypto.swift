//  Crypto.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-03.

import Foundation
import CocoaLumberjack

protocol Crypto {

}

extension SaltChannel: Crypto {

    public func receiveAndDecryptMessage(message: Data, session: Session) throws -> Data {
        DDLogInfo("read called from receiveAndDecryptMessage salt handshake")
        let header = message[..<2]
        guard read(header: header) == PacketType.Encrypted else {
            throw ChannelError.badMessageType(reason: "Expected Encrypted PacketType Header")
        }
        
        let encryptedData = message.subdata(in: 2 ..< message.endIndex)
        
        guard let decryptedData = sodium.box.open(authenticatedCipherText: encryptedData, beforenm: session.key, nonce: receiveNonce.getNextNonce()) else {
            throw ChannelError.couldNotDecrypt
        }
        
        return decryptedData
    }
    
    public func encryptMessage(session: Session, message: Data) -> Data {
        // Added for byte channel multicall, TODO: Review
        let header = create(from: PacketType.Encrypted)
        let encryptedMessage =  header + sodium.box.seal(message: message, beforenm: session.key, nonce: sendNonce.getNextNonce())!
        return encryptedMessage
    }
    
    public func encryptAndSendMessage(session: Session, message: Data) throws {
        let header = create(from: PacketType.Encrypted)
        let cipherData = sodium.box.seal(message: message, beforenm: session.key, nonce: sendNonce.getNextNonce())!
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
            throw ChannelError.setupNotDone
        }
        
        return sign
    }
}
