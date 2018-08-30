//  Handshake.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-10-02.

import Foundation
import os.log

extension SaltChannel: Setup {

    public func negotiate(pubKey: Data?, completion: (([(first: String, second: String)]) -> Void)?) throws {
        guard handshakeState == .notStarted else {
            throw ChannelError.handshakeAlreadyDone
        }

        handshakeData.negotiateCompleted = completion

        let a1 = try packA1(pubKey: pubKey)
        try channel.write([a1])

        handshakeState = .expectA2
    }

    public func handshake(
        clientEncSec: Data, clientEncPub: Data, serverSignPub: Data? = nil, completion: (() -> Void)?) throws {

        guard handshakeState == .notStarted  else {
            throw ChannelError.handshakeAlreadyDone
        }

        handshakeData.clientEncSec = clientEncSec
        handshakeData.clientEncPub = clientEncPub
        handshakeData.handshakeCompleted = completion

        // *** Send M1 ***
        let (m1Hash, m1) = try packM1(time: timeKeeper.time(), myEncPub: handshakeData.clientEncPub!, serverSignPub: serverSignPub)
        handshakeData.m1Hash = m1Hash
        try channel.write([m1])
        handshakeState = .expectM2
    }

    public func handshake(completion: (() -> Void)?) throws {
        let encKeyPair = sodium.box.keyPair()! // ToDo: Use true random from HW
        try handshake(clientEncSec: encKeyPair.secretKey, clientEncPub: encKeyPair.publicKey, completion: completion)
    }

    internal func receiveA2(a2Raw: Data) throws {
        guard handshakeState == .expectA2 else {
            throw ChannelError.invalidHandshakeSequence
        }

        let a2 = try unpackA2(data: a2Raw)
        handshakeState = .notStarted

        print("🤝 Negotiate completed!!")

        handshakeData.negotiateCompleted?(a2)
    }

    internal func receiveM2(m2Raw: Data) throws {
        guard handshakeState == .expectM2 else {
            throw ChannelError.invalidHandshakeSequence
        }
        // *** Receive M2 ***
        let (_, serverEncPub, m2Hash) = try unpackM2(data: m2Raw)
        handshakeData.m2Hash = m2Hash
        handshakeData.serverEncPub = serverEncPub
        handshakeState = .expectM3
    }

    public func receiveM3sendM4(m3Raw: Data) throws {
        guard handshakeState == .expectM3 else {
            throw ChannelError.invalidHandshakeSequence
        }
        // *** Create a session ***
        guard let key = sodium.box.beforenm(recipientPublicKey: handshakeData.serverEncPub!,
                                            senderSecretKey: handshakeData.clientEncSec!) else {
                                                throw ChannelError.couldNotCalculateKey
        }
        let session = Session(key: key)
        self.session = session
        // *** Receive M3 ***
        let data: Data = try decryptMessage(message: m3Raw, session: session)
        let (_, remoteSignPub) = try unpackM3(data: data, m1Hash: handshakeData.m1Hash!, m2Hash: handshakeData.m2Hash!)
        self.remoteSignPub = remoteSignPub

        // *** Send M4 ***
        let m4Data: Data = try packM4(time: timeKeeper.time(), clientSignSec: clientSignSec,
                                      clientSignPub: clientSignPub, m1Hash: handshakeData.m1Hash!, m2Hash: handshakeData.m2Hash!)
        let m4cipher = encryptMessage(session: session, message: m4Data)

        try channel.write([m4cipher])
        self.handshakeState = .done
        print("🤝 Handshake completed!!")

        handshakeData.handshakeCompleted?()
    }
}
