//
//  MPackTest.swift
//  SaltChannel-Tests
//
//  Created by Anders Tidbeck on 2020-04-23.
//

import XCTest
import Sodium
@testable import SaltChannel

class MPacketTest: XCTestCase {
    let sodium = Sodium()
    let saltChannel = SaltChannel(channel: DummyChannel(), sec: Data(), pub: Data())
    let testData = SaltTestData().session1TestData
    let timeKeeper = NullTimeKeeper()

    func testM1Packet() throws {
        let clientPubKey = Data(testData.clientKeys.signPub)

        let (_, data) = try saltChannel.packM1(time: timeKeeper.time(), myEncPub: clientPubKey)
        let (time, remoteEncPub, _) = try saltChannel.unpackM1(data: data)
        XCTAssertEqual(timeKeeper.time(), time)
        XCTAssertEqual(remoteEncPub, clientPubKey)
    }

    func testM2Packet() throws {
        let hostPubKey = Data(testData.hostKeys.signPub)

        let (_, data) = try saltChannel.packM2(time: timeKeeper.time(), myEncPub: hostPubKey)
        let (time, remoteEncPub, _) = try saltChannel.unpackM2(data: data)
        XCTAssertEqual(timeKeeper.time(), time)
        XCTAssertEqual(remoteEncPub, hostPubKey)
    }

    func testM3Packet() throws {
        let clientPubKey = Data(testData.clientKeys.signPub)
        let hostSecKey = Data(testData.hostKeys.signSec)
        let hostPubKey = Data(testData.hostKeys.signPub)

        let (m1Hash, _) = try saltChannel.packM1(time: timeKeeper.time(), myEncPub: clientPubKey)
        let (m2Hash, _) = try saltChannel.packM2(time: timeKeeper.time(), myEncPub: hostPubKey)

        let data = try saltChannel.packM3(time: timeKeeper.time(), hostSignSec: hostSecKey, hostSignPub: hostPubKey, m1Hash: m1Hash, m2Hash: m2Hash)
        let (time, remoteSignPub) = try saltChannel.unpackM3(data: data, m1Hash: m1Hash, m2Hash: m2Hash)
        XCTAssertEqual(timeKeeper.time(), time)
        XCTAssertEqual(remoteSignPub, hostPubKey)
    }

    func testM4Packet() throws {
        let clientSecKey = Data(testData.clientKeys.signSec)
        let clientPubKey = Data(testData.clientKeys.signPub)
        let hostPubKey = Data(testData.hostKeys.signPub)

        let (m1Hash, _) = try saltChannel.packM1(time: timeKeeper.time(), myEncPub: clientPubKey)
        let (m2Hash, _) = try saltChannel.packM2(time: timeKeeper.time(), myEncPub: hostPubKey)

        let data = try saltChannel.packM4(time: timeKeeper.time(), clientSignSec: clientSecKey, clientSignPub: clientPubKey, m1Hash: m1Hash, m2Hash: m2Hash)
        print("M4: \(data.hex)")
        let (time, remoteSignPub) = try saltChannel.unpackM4(data: data, m1Hash: m1Hash, m2Hash: m2Hash)
        XCTAssertEqual(timeKeeper.time(), time)
        XCTAssertEqual(remoteSignPub, clientPubKey)
    }

    func testEncryption() throws {

        guard let clientKey = sodium.box.beforenm(recipientPublicKey: testData.clientKeys.diffiPub,
                                            senderSecretKey: testData.clientKeys.diffiSec) else {
                                                throw ChannelError.couldNotCalculateKey
        }
        guard let hostKey = sodium.box.beforenm(recipientPublicKey: testData.clientKeys.diffiPub,
                                                  senderSecretKey: testData.clientKeys.diffiSec) else {
                                                    throw ChannelError.couldNotCalculateKey
        }
        XCTAssertEqual(clientKey, hostKey)
        let clientSession = Session(key: Data(bytes: clientKey))
        let hostSession = Session(key: Data(bytes: hostKey))

        let data = saltChannel.encryptMessage(session: clientSession, message: Data("Encrypt this message".utf8))
        let decryptedMessage = try saltChannel.decryptMessage(message: data, session: hostSession)
        XCTAssertEqual(Data("Encrypt this message".utf8), decryptedMessage)
    }
}
