//  Handshake.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-10-02.

import Foundation
import os.log

extension SaltChannel: Setup {

    public func negotiate(pubKey: Data?) throws -> [(first: String, second: String)] {
        /*if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }
        
        let a1 = try packA1(pubKey: pubKey)
        try channel.write([a1])
        
        guard let a2Raw = waitForData() else {
            throw ChannelError.readTimeout
        }
        return try unpackA2(data: a2Raw)*/
        return []
    }

    public func handshake_M1(clientEncSec: Data, clientEncPub: Data, serverSignPub: Data? = nil) throws {
        if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }
        self.clientEncSec = clientEncSec
        self.clientEncPub = clientEncPub
        // *** Send M1 ***
        let (m1Hash, m1) = try packM1(time: timeKeeper.time(), myEncPub: self.clientEncPub!, serverSignPub: serverSignPub)
        self.m1Hash = m1Hash
        self.handshakeState = HandshakeState.m1
        try channel.write([m1])
    }
    
    public func handshake_M2(m2Raw: Data, serverSignPub: Data? = nil) throws {
        if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }
        // *** Receive M2 ***
        let (_, serverEncPub, m2Hash) = try unpackM2(data: m2Raw)
        self.m2Hash = m2Hash
        self.serverEncPub = serverEncPub
        self.handshakeState = HandshakeState.m2
    }
    
    public func handshake_M3(m3Raw: Data, serverSignPub: Data? = nil) throws {
        if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }
        // *** Create a session ***
        guard let key = sodium.box.beforenm(recipientPublicKey: self.serverEncPub!.bytes,
                                            senderSecretKey: self.clientEncSec!.bytes) else {
                                                throw ChannelError.couldNotCalculateKey
        }
        self.session = Session(key: Data(bytes: key))
        guard let session = self.session else {
            throw ChannelError.couldNotCalculateKey
        }
        // *** Receive M3 ***
        let data: Data = try decryptMessage(message: m3Raw, session: session)
        let (_, remoteSignPub) = try unpackM3(data: data, m1Hash: self.m1Hash!, m2Hash: self.m2Hash!)
        self.remoteSignPub = remoteSignPub
        self.handshakeState = HandshakeState.m3
    }
    
    public func handshake_M4(serverSignPub: Data? = nil) throws {
        if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }
        // *** Send M4 ***
        let m4Data: Data = try packM4(time: timeKeeper.time(), clientSignSec: clientSignSec,
                                      clientSignPub: clientSignPub, m1Hash: m1Hash!, m2Hash: m2Hash!)
        guard let session = self.session else {
            throw ChannelError.couldNotCalculateKey
        }
        let m4cipher = encryptMessage(session: session, message: m4Data)
        
        self.handshakeState = HandshakeState.m4
        try channel.write([m4cipher])
        print("🤝 Handshake completed!!")
        self.handshakeDone = true

    }

   public func handshake(
                    clientEncSec: Data, clientEncPub: Data, serverSignPub: Data? = nil,
                    holdUntilFirstWrite: Bool = false) throws {

      /*   if self.handshakeDone {
            throw ChannelError.handshakeAlreadyDone
        }

        // *** Send M1 ***
        let (m1Hash, m1) = try packM1(time: timeKeeper.time(), myEncPub: clientEncPub, serverSignPub: serverSignPub)
        try channel.write([m1])

        // *** Receive M2 ***
        guard let m2Raw = waitForData() else {
            print("☠️ Read timeout")
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

        self.handshakeDone = true*/
    }

    public func handshake(holdUntilFirstWrite: Bool = false) throws {
        let encKeyPair = sodium.box.keyPair()! // ToDo: Use true random from HW
        try handshake(clientEncSec: Data(bytes: encKeyPair.secretKey), clientEncPub: Data(bytes: encKeyPair.publicKey),
                      holdUntilFirstWrite: holdUntilFirstWrite)
    }
    
    /*func waitForData() -> Data? {
        if WaitUntil.waitUntil(10, receiveData.isEmpty == false) {
            let temporery = receiveData.first
            receiveData.remove(at: 0)
            return temporery
        }
        return nil
    }*/
}
