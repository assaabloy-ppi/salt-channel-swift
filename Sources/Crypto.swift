//  Crypto.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-03.

import Foundation
import CocoaLumberjack

protocol Crypto {

}

extension SaltChannel: Crypto {

    func receiveAndDecryptMessage(sessionKey: Data) throws -> Data {
        DDLogInfo("read called from receiveAndDecryptMessage salt handshake")
        let message = try channel.read()
        let header = message.subdata(in: 0 ..< 2)
        guard readHeader(header: header) == PacketType.encrypted else {
            throw ChannelError.gotWrongMessage
        }
        
        let encryptedData = message.subdata(in: 2 ..< message.endIndex)
        
        guard let decryptedData = sodium.box.open(authenticatedCipherText: encryptedData, beforenm: sessionKey, nonce: receiveNonce.getNextNonce()) else {
            throw ChannelError.couldNotDecrypt
        }
        
        return decryptedData
    }
    
    func encryptMessage(sessionKey: Data, message: Data) -> Data {
        // Added for byte channel multicall, TODO: Review
        let encryptedMessage = createHeader(packageType: PacketType.encrypted) + sodium.box.seal(message: message, beforenm: sessionKey, nonce: sendNonce.getNextNonce())!
        return encryptedMessage
    }
    
    func encryptAndSendMessage(sessionKey: Data, message: Data) throws {
        let header = createHeader(packageType: PacketType.encrypted)
        let cipherData = sodium.box.seal(message: message, beforenm: sessionKey, nonce: sendNonce.getNextNonce())!
        try self.channel.write([header + cipherData])
    }
    
    func packAppPacket(time: Double, message: Data) -> Data {
        let header = createHeader(packageType: PacketType.appPacket)
        return header + packBytes(UInt64(time), parts: 4) + message
    }
    
    func unpackAppPacket(data: Data) throws -> (time: Double, message: Data) {
        let header = data.subdata(in: 0 ..< 2)
        guard readHeader(header: header) == PacketType.appPacket else {
            throw ChannelError.gotWrongMessage
        }
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let message = data.subdata(in: 6 ..< data.endIndex)
        return (Double(time), message)
    }
    
    func validateSignature(sign: Data, signPub: Data, signedData: Data) -> Bool {
        let message = sodium.sign.open(signedMessage: sign + signedData, publicKey: signPub)
        if message != nil {
            return true
        } else {
            return false
        }
    }
    
    func createSignature(message: Data, signSec: Data) -> Data? {
        let rawSignature = sodium.sign.sign(message: message, secretKey: signSec)!
        return rawSignature.subdata(in: 0 ..< 64)
    }
}
