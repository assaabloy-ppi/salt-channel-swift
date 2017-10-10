//  Handshake.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation
import CocoaLumberjack

extension SaltChannel {
    
    func handshake(holdUntilFirstWrite: Bool = false) throws {
        let encKeyPair = sodium.box.keyPair()! // ToDo: Use true random from HW
        try handshake(clientEncSec: encKeyPair.secretKey, clientEncPub: encKeyPair.publicKey, holdUntilFirstWrite: holdUntilFirstWrite)
    }
    
    func handshake(clientEncSec: Data, clientEncPub: Data, holdUntilFirstWrite: Bool = false) throws {
        
        if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }
        
        self.channel.register(callback: read, errorhandler: error)
        
        // *** Send M1 ***
        let m1Hash = try writeM1(time: 0, myEncPub: clientEncPub)
        
        // *** Receive M2 ***
        guard let m2Raw = waitForData() else {
            throw ChannelError.readTimeout
        }
        let (_, serverEncPub, m2Hash) = try readM2(data: m2Raw)
        
        // *** Create a session ***
        guard let key = sodium.box.beforenm(recipientPublicKey: serverEncPub, senderSecretKey: clientEncSec) else {
            throw ChannelError.couldNotCalculateSessionKey
        }
        self.session = Session(key: key)
        guard let session = self.session else {
            throw ChannelError.couldNotCalculateSessionKey
        }
        
        // *** Receive M3 ***
        guard let m3Raw = waitForData() else {
            throw ChannelError.readTimeout
        }
        let data: Data = try receiveAndDecryptMessage(message: m3Raw, session: session)
        let (m3time, remoteSignPub) = try readM3(data: data, m1Hash: m1Hash, m2Hash: m2Hash)
        self.remoteSignPub = remoteSignPub
        
        // *** Send M4 ***
        let m4Data: Data = try writeM4(time: 0, clientSignSec: clientSignSec, clientSignPub: clientSignPub, m1Hash: m1Hash, m2Hash: m2Hash)
        
        if holdUntilFirstWrite {
            bufferedM4 = encryptMessage(session: session, message: m4Data)
        } else {
            try encryptAndSendMessage(session: session, message: m4Data)
        }
        
        self.handshakeDone = true
    }
    
    func waitForData() -> Data?{
        if WaitUntil.waitUntil(10, receiveData.isEmpty == false) {
            let temporery = receiveData.first
            receiveData.remove(at: 0)
            return temporery
        }
        return nil
    }
}
