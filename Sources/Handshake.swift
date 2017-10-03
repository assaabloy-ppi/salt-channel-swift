//
//  Handshake.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.
//

import Foundation

extension SaltChannel {
    
    func handshake(holdUntilFirstWrite: Bool = false) throws {
        let encKeyPair = sodium.box.keyPair()! // ToDo: Use true random from HW
        try handshake(clientEncSec: encKeyPair.secretKey, clientEncPub: encKeyPair.publicKey, holdUntilFirstWrite: holdUntilFirstWrite)
    }
    
    func handshake(clientEncSec: Data, clientEncPub: Data, holdUntilFirstWrite: Bool = false) throws {
        let m1Hash = try m1(time: 0, myEncPub: clientEncPub)
        
        if WaitUntil.waitUntil(60, self.didReceiveMsg == true) {
            self.didReceiveMsg = false
            let (_, serverEncPub, m2Hash) = try m2()
            
            guard let key = sodium.box.beforenm(recipientPublicKey: serverEncPub, senderSecretKey: clientEncSec) else {
                throw ChannelError.couldNotCalculateSessionKey
            }
            self.sessionKey = key
            
            if WaitUntil.waitUntil(60, self.didReceiveMsg == true) {
                let data: Data = try receiveAndDecryptMessage( sessionKey: self.sessionKey!)
                
                let (_, remoteSignPub) = try m3(data: data, m1Hash: m1Hash, m2Hash: m2Hash)
                self.remoteSignPub = remoteSignPub
                
                let m4Data: Data = try m4(time: 0, clientSignSec: clientSignSec, clientSignPub: clientSignPub, m1Hash: m1Hash, m2Hash: m2Hash)
                
                if holdUntilFirstWrite {
                    bufferedM4 = encryptMessage(sessionKey: self.sessionKey!, message: m4Data)
                } else {
                    try encryptAndSendMessage(sessionKey: self.sessionKey!, message: m4Data)
                }
            } else {
                throw ChannelError.readTimeout
            }
        } else {
            throw ChannelError.readTimeout
        }
    }
}
    
extension SaltChannel {

    public func getRemoteSignPub() throws -> Data {
        guard let sign = self.remoteSignPub else {
            throw ChannelError.setupNotDone
        }
        
        return sign
    }
    
}
