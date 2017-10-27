//  Handshake.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-10-02.

import Foundation
import os.log

extension SaltChannel {

    func handshake(holdUntilFirstWrite: Bool = false) throws {
        let encKeyPair = sodium.box.keyPair()! // ToDo: Use true random from HW
        try handshake(clientEncSec: encKeyPair.secretKey, clientEncPub: encKeyPair.publicKey,
            holdUntilFirstWrite: holdUntilFirstWrite)
    }
    
    func negotiate(pubKey: Data?) throws -> [(first: String, second: String)] {
        if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }
        
        let a1 = try packA1(pubKey: pubKey)
        try channel.write([a1])
        
        guard let a2Raw = waitForData() else {
            throw ChannelError.readTimeout
        }
        return try unpackA2(data: a2Raw)
    }

    func handshake(clientEncSec: Data, clientEncPub: Data, holdUntilFirstWrite: Bool = false) throws {

        if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }

        // *** Send M1 ***
        let (m1Hash, m1) = try packM1(time: timeKeeper.time(), myEncPub: clientEncPub)
        try channel.write([m1])

        // *** Receive M2 ***
        guard let m2Raw = waitForData() else {
            throw ChannelError.readTimeout
        }
        let (_, serverEncPub, m2Hash) = try unpackM2(data: m2Raw)

        // *** Create a session ***
        guard let key = sodium.box.beforenm(recipientPublicKey: serverEncPub,
            senderSecretKey: clientEncSec) else {
            throw ChannelError.couldNotCalculateKey
        }
        self.session = Session(key: key)
        guard let session = self.session else {
            throw ChannelError.couldNotCalculateKey
        }

        // *** Receive M3 ***
        guard let m3Raw = waitForData() else {
            throw ChannelError.readTimeout
        }
        let data: Data = try decryptMessage(message: m3Raw, session: session)
        let (_, remoteSignPub) = try unpackM3(data: data, m1Hash: m1Hash, m2Hash: m2Hash)
        self.remoteSignPub = remoteSignPub

        // *** Send M4 ***
        let m4Data: Data = try packM4(time: timeKeeper.time(), clientSignSec: clientSignSec,
            clientSignPub: clientSignPub, m1Hash: m1Hash, m2Hash: m2Hash)
        let m4cipher = encryptMessage(session: session, message: m4Data)
        
        if holdUntilFirstWrite {
            bufferedM4 = m4cipher
        } else {
            try channel.write([m4cipher])
        }

        self.handshakeDone = true
    }

    func waitForData() -> Data? {
        if WaitUntil.waitUntil(10, receiveData.isEmpty == false) {
            let temporery = receiveData.first
            receiveData.remove(at: 0)
            return temporery
        }
        return nil
    }
}
