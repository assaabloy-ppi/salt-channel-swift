//  Crypto.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-03.

import Foundation
import CocoaLumberjack

protocol Crypto {

}

extension SaltChannel: Crypto {

    public func receiveAndDecryptMessage(message: Data, sessionKey: Data) throws -> Data {
        DDLogInfo("read called from receiveAndDecryptMessage salt handshake")
        let header = message[..<2]
        guard readHeader(header: header) == PacketType.Encrypted else {
            throw ChannelError.badMessageType(reason: "Expected Encrypted PacketType Header")
        }
        
        let encryptedData = message.subdata(in: 2 ..< message.endIndex)
        
        guard let decryptedData = sodium.box.open(authenticatedCipherText: encryptedData, beforenm: sessionKey, nonce: receiveNonce.getNextNonce()) else {
            throw ChannelError.couldNotDecrypt
        }
        
        return decryptedData
    }
    
    public func encryptMessage(sessionKey: Data, message: Data) -> Data {
        // Added for byte channel multicall, TODO: Review
        let encryptedMessage = createHeader(packageType: PacketType.Encrypted) + sodium.box.seal(message: message, beforenm: sessionKey, nonce: sendNonce.getNextNonce())!
        return encryptedMessage
    }
    
    public func encryptAndSendMessage(sessionKey: Data, message: Data) throws {
        let header = createHeader(packageType: PacketType.Encrypted)
        let cipherData = sodium.box.seal(message: message, beforenm: sessionKey, nonce: sendNonce.getNextNonce())!
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

extension SaltChannel {
    func createHeader(packageType: PacketType) -> Data {
        let type = packBytes(UInt64(packageType.rawValue), parts: 1)
        let dummy = packBytes(0, parts: 1)
        return type + dummy
    }
    
    func readHeader(header: Data) -> PacketType {
        guard let byte = header.first else {
            return .Unknown
        }
        
        if let type = PacketType(rawValue: byte) {
            return type
        } else {
            return .Unknown
        }
    }
}
