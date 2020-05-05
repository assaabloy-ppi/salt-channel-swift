//  Crypto.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-03.

import Foundation
import os.log

protocol Crypto {

}

extension SaltChannel: Crypto {
    public func decryptMessage(message: Data, session: Session) throws -> Data {
        os_log("Crypto: read called from receiveAndDecryptMessage salt handshake", log: log, type: .debug)
        let header = message[..<2]
        let (type, _, lastMessageFlag) = readHeader(from: header)
        guard type == PacketType.encrypted else {
            throw ChannelError.badMessageType(reason: "Expected Encrypted PacketType Header")
        }
        
        // TODO: check semantics for lastMsg
        if lastMessageFlag {
            session.lastMessageReceived = true
            os_log("Crypto: last message flag set. what now?", log: log)
        }
        
        let encryptedData = message.subdata(in: 2 ..< message.endIndex)
        
        let nonce = receiveNonce.next()
        print("Decrypt nonce: \(nonce.hex)")
        guard let decryptedData = sodium.box.open(authenticatedCipherText: encryptedData.bytes,
                                                  beforenm: session.key.bytes, nonce: nonce.bytes) else {
            throw ChannelError.couldNotDecrypt
        }
        
        return Data(bytes: decryptedData)
    }
    
    public func encryptMessage(session: Session, message: Data, isLastMessage: Bool = false) -> Data {
        let header = createHeader(from: PacketType.encrypted, last: isLastMessage)
        let nonce = sendNonce.next()
        print("Decrypt nonce: \(nonce.hex)")
        let encryptedMessage =  header +
            sodium.box.seal(message: message.bytes, beforenm: session.key.bytes,
                            nonce: nonce.bytes)!
        return encryptedMessage
    }
    
    public func validateSignature(sign: Data, signPub: Data, signedData: Data) -> Bool {
        let message = sodium.sign.open(signedMessage: (sign + signedData).bytes, publicKey: signPub.bytes)
        if message != nil {
            return true
        } else {
            return false
        }
    }
    
    public func createSignature(message: Data, signSec: Data) -> Data? {
        let rawSignature = sodium.sign.sign(message: message.bytes, secretKey: signSec.bytes)!
        return Data(bytes: rawSignature.prefix(64))
    }
    
    public func getRemoteSignPub() throws -> Data {
        guard let sign = self.remoteSignPub else {
            throw ChannelError.setupNotDone(reason: "No Host Sign Pub available")
        }
        
        return sign
    }
}
