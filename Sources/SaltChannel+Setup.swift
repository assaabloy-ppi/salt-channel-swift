//  Handshake.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-10-02.

import Foundation
import os.log

extension SaltChannel: Setup {

    public func negotiate(pubKey: Data?, success: @escaping (SaltChannelProtocols) -> Void, failure: @escaping (Error) -> Void) {
        do {
            guard handshakeState == .notStarted else {
                throw ChannelError.handshakeAlreadyDone
            }

            handshakeData.negotiateCompleted = success
            handshakeData.failure = failure

            let a1 = try packA1(pubKey: pubKey)
            try channel.write([a1])

            handshakeState = .expectA2
        } catch {
            failure(error)
        }
    }

    public func handshake(serverSignPub: Data?, success: @escaping (Data) -> Void, failure: @escaping (Error) -> Void) {
        let encKeyPair = sodium.box.keyPair()!
        handshake(encSec: Data(bytes: encKeyPair.secretKey),
                  encPub: Data(bytes: encKeyPair.publicKey),
                  serverSignPub: serverSignPub,
                  success: success,
                  failure: failure)
    }

    public func handshake(encSec: Data, encPub: Data, serverSignPub: Data? = nil,
                          success: @escaping (Data) -> Void, failure: @escaping (Error) -> Void) {

        do {
            guard handshakeState == .notStarted  else {
                throw ChannelError.handshakeAlreadyDone
            }

            handshakeData.handshakeCompleted = success
            handshakeData.failure = failure

            if isHost {
                handshakeData.hostEncSec = encSec
                handshakeData.hostEncPub = encPub
                
                // *** Wait for M1 ***
                handshakeState = .expectM1
            } else {
                handshakeData.clientEncSec = encSec
                handshakeData.clientEncPub = encPub
                
                // *** Send M1 ***
                let (m1Hash, m1) = try packM1(time: timeKeeper.time(), myEncPub: handshakeData.clientEncPub!, serverSignPub: serverSignPub)
                handshakeData.m1Hash = m1Hash
                try channel.write([m1])
                handshakeState = .expectM2
            }
        } catch {
            failure(error)
        }
    }

    // MARK: internal
    internal func receiveA2(a2Raw: Data) {
        do {
            guard handshakeState == .expectA2 else {
                throw ChannelError.invalidHandshakeSequence
            }

            let a2 = try unpackA2(data: a2Raw)
            handshakeState = .notStarted

            print("🤝 Negotiate completed!!")

            handshakeData.negotiateCompleted?(a2)
        } catch {
            handshakeData.failure?(error)
        }
    }

    internal func receiveM1sendM2M3(m1Raw: Data) {
        do {
            guard handshakeState == .expectM1 else {
                throw ChannelError.invalidHandshakeSequence
            }
            // *** Receive M1 ***
            let (_, clientEncPub, m1Hash) = try unpackM1(data: m1Raw)
            handshakeData.m1Hash = m1Hash
            handshakeData.remoteEncPub = clientEncPub
            
            // *** Send M2 ***
            let (m2Hash, m2) = try packM2(time: timeKeeper.time(), myEncPub: handshakeData.hostEncPub!)
            handshakeData.m2Hash = m2Hash
            try channel.write([m2])

            // *** Create a session ***
            guard let key = sodium.box.beforenm(recipientPublicKey: handshakeData.remoteEncPub!.bytes,
                                                senderSecretKey: handshakeData.hostEncSec!.bytes) else {
                                                    throw ChannelError.couldNotCalculateKey
            }
            let session = Session(key: Data(bytes: key))
            self.session = session

            // *** Send M3 ***
            let m3Data: Data = try packM3(time: timeKeeper.time(), hostSignSec: signSec,
                                          hostSignPub: signPub, m1Hash: handshakeData.m1Hash!, m2Hash: handshakeData.m2Hash!)
            let m3cipher = encryptMessage(session: session, message: m3Data)

            try channel.write([m3cipher])

            handshakeState = .expectM4
        } catch {
            handshakeData.failure?(error)
        }
    }

    internal func receiveM2(m2Raw: Data) {
        do {
            guard handshakeState == .expectM2 else {
                throw ChannelError.invalidHandshakeSequence
            }
            // *** Receive M2 ***
            let (_, serverEncPub, m2Hash) = try unpackM2(data: m2Raw)
            handshakeData.m2Hash = m2Hash
            handshakeData.remoteEncPub = serverEncPub
            handshakeState = .expectM3
        } catch {
            handshakeData.failure?(error)
        }
    }

    internal func receiveM3sendM4(m3Raw: Data) {
        do {
            guard handshakeState == .expectM3 else {
                throw ChannelError.invalidHandshakeSequence
            }
            // *** Create a session ***
            guard let key = sodium.box.beforenm(recipientPublicKey: handshakeData.remoteEncPub!.bytes,
                                                senderSecretKey: handshakeData.clientEncSec!.bytes) else {
                                                    throw ChannelError.couldNotCalculateKey
            }
            let session = Session(key: Data(bytes: key))
            self.session = session
            // *** Receive M3 ***
            let data: Data = try decryptMessage(message: m3Raw, session: session)
            let (_, remoteSignPub) = try unpackM3(data: data, m1Hash: handshakeData.m1Hash!, m2Hash: handshakeData.m2Hash!)
            self.remoteSignPub = remoteSignPub

            // *** Send M4 ***
            let m4Data: Data = try packM4(time: timeKeeper.time(), clientSignSec: signSec,
                                          clientSignPub: signPub, m1Hash: handshakeData.m1Hash!, m2Hash: handshakeData.m2Hash!)
            let m4cipher = encryptMessage(session: session, message: m4Data)
            print("M4cipher: \(m4cipher.hex)")

            try channel.write([m4cipher])
            self.handshakeState = .done
            print("🤝 Handshake completed!!")

            handshakeData.handshakeCompleted?(remoteSignPub)
        } catch {
            handshakeData.failure?(error)
        }
    }

    internal func receiveM4(m4Raw: Data) {
        do {
            guard handshakeState == .expectM4 else {
                throw ChannelError.invalidHandshakeSequence
            }
            // *** Receive M4 ***
            let data: Data = try decryptMessage(message: m4Raw, session: session!)
            let (_, remoteSignPub) = try unpackM4(data: data, m1Hash: handshakeData.m1Hash!, m2Hash: handshakeData.m2Hash!)
            self.remoteSignPub = remoteSignPub
            handshakeState = .done
            print("🤝 Handshake completed!!")
            
            handshakeData.handshakeCompleted?(remoteSignPub)
        } catch {
            handshakeData.failure?(error)
        }
    }
}
