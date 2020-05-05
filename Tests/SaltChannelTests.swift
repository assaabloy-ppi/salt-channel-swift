//  SaltChannelTests.swift
//  SaltChannelTests
//
//  Created by Håkan Olsson on 2017-06-02.

import XCTest
import Sodium

@testable import SaltChannel

class SaltChannelTests: XCTestCase {
    //let sodium = Sodium()
    var receivedData: [Data] = []

    func waitForData(_ data: Data) {
        if WaitUntil.waitUntil(2, self.receivedData.isEmpty == false) {
            XCTAssertEqual(receivedData.first, data)
            receivedData.remove(at: 0)
        } else {
            XCTFail("Did not receive data")
        }
    }

    func receiver(data: Data) {
        receivedData.append(data)
    }

    func errorhandler(error: Error) {
        print(error)
        XCTFail("Got error: " + error.localizedDescription)
    }

    func runClientHandshake(testDataSet: TestDataSet, timeKeeper: TimeKeeper, serverPub: Bool = false) {
        do {
            /*** Setup ***/
            let signSec = Data(testDataSet.clientKeys.signSec)
            let signPub = Data(testDataSet.clientKeys.signPub)

            let mock = BasicHostMock(mockdata: testDataSet)
            mock.start()

            let channel = SaltChannel(channel: mock, sec: signSec, pub: signPub, timeKeeper: timeKeeper)
            channel.register(callback: receiver, errorhandler: errorhandler)

            /*** A1 A2 negotiation ***/
            if let abox = testDataSet.abox {
                var pubKey: Data?
                if abox.pubKey != nil {
                    pubKey = Data(abox.pubKey!)
                }

                let expectation1 = expectation(description: "Negotiation successfull")
                var unpackedA2 = SaltChannelProtocols()
                channel.negotiate(pubKey: pubKey, success: { result in
                    unpackedA2 = result
                    expectation1.fulfill()
                }, failure: { error in
                    XCTFail("Negotiate failed: \(error)")
                })
                waitForExpectations(timeout: 2.0)

                XCTAssertEqual(unpackedA2.count, abox.unpackedA2.count)
                for index in 0..<unpackedA2.count {
                    XCTAssertEqual(unpackedA2[index].first, abox.unpackedA2[index].first)
                    XCTAssertEqual(unpackedA2[index].second, abox.unpackedA2[index].second)
                }
            }

            /*** Handshake ***/
            if testDataSet.handshake != nil {
                let serverSignPub = serverPub ? Data(testDataSet.hostKeys.signPub): nil

                let expectation2 = expectation(description: "Handshake successfull")
                channel.handshake(encSec: Data(testDataSet.clientKeys.diffiSec),
                                      encPub: Data(testDataSet.clientKeys.diffiPub),
                                      serverSignPub: serverSignPub, success: { _ in
                    expectation2.fulfill()
                }, failure: { error in
                    XCTFail("Handshake failed: \(error)")
                })
                waitForExpectations(timeout: 2.0)

                XCTAssertEqual(try channel.getRemoteSignPub(), Data(testDataSet.hostKeys.signPub))
            }

            /*** Data transfer ***/
            for transfer in testDataSet.transfers {
                if transfer.direction == .toHost {
                    try channel.write(transfer.plain.map {Data($0)})
                } else {
                    for item in transfer.plain {
                        waitForData(Data(item))
                    }
                }
            }

            // Wait until mock is done
            if WaitUntil.waitUntil(4, mock.isDone == true) {
                print("Mock is done")
                XCTAssertEqual(mock.isDone, true)
            }
        } catch {
            print(error)
            XCTFail("Got exception")
        }
    }

    func runHostHandshake(testDataSet: TestDataSet, timeKeeper: TimeKeeper) {
        do {
            /*** Setup ***/
            let signSec = Data(testDataSet.hostKeys.signSec)
            let signPub = Data(testDataSet.hostKeys.signPub)

            let mock = BasicClientMock(mockdata: testDataSet)

            let channel = SaltChannel(channel: mock, sec: signSec, pub: signPub, timeKeeper: timeKeeper, isHost: true)
            channel.register(callback: receiver, errorhandler: errorhandler)

            /*** Handshake ***/
            if testDataSet.handshake != nil {

                let expectation2 = expectation(description: "Handshake successfull")
                channel.handshake(encSec: Data(testDataSet.hostKeys.diffiSec),
                                  encPub: Data(testDataSet.hostKeys.diffiPub),
                                  success: { _ in
                                    expectation2.fulfill()
                }, failure: { error in
                    XCTFail("Handshake failed: \(error)")
                })
                mock.start()

                waitForExpectations(timeout: 2.0)

                XCTAssertEqual(try channel.getRemoteSignPub(), Data(testDataSet.clientKeys.signPub))
            }

            /*** Data transfer ***/
            for transfer in testDataSet.transfers {
                if transfer.direction == .toHost {
                    for item in transfer.plain {
                        waitForData(Data(item))
                    }
                } else {
                    try channel.write(transfer.plain.map {Data($0)})
                }
            }

            // Wait until mock is done
            if WaitUntil.waitUntil(4, mock.isDone == true) {
                print("Mock is done")
                XCTAssertEqual(mock.isDone, true)
            }
        } catch {
            print(error)
            XCTFail("Got exception")
        }
    }
    /*********************************************************/
    // Negative testes
    func testNegativeA1() {
        let clientKeys = SaltTestData().session1TestData.clientKeys
        let channel = SaltChannel(channel: DummyChannel(), sec: Data(clientKeys.signSec), pub: Data(clientKeys.signPub))

        do {
            _ = try channel.packA1(pubKey: Data([0x22, 0x34]))
            XCTFail("Should have failed")
        } catch { }
    }

    /*********************************************************/
    // Test client handshake, a1 and a2
    func testSession1ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session1TestData, timeKeeper: NullTimeKeeper())
    }

    func testSession2ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session2TestData, timeKeeper: NullTimeKeeper())
    }

    func testSession3ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session3TestData, timeKeeper: CounterTimeKeeper(timeArray: [1, 2, 3, 4]))
    }

    func testSession4ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session4TestData, timeKeeper: NullTimeKeeper(), serverPub: true)
    }

    func testSessionALongClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().sessionALong, timeKeeper: NullTimeKeeper())
    }

    // Test host handshake
    func testSession1HostHandshake() {
        runHostHandshake(testDataSet: SaltTestData().session1TestData, timeKeeper: NullTimeKeeper())
    }

    func testPrettyPrintSession3() {
        let m1 = "534376320100010000008520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"
        let m2 = "020001000000de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
        let m3 = "06005f545037bc60f771254bb562a5545193c6cdd969b86e299a47a9b1f1c18666e5cf8b000742bad609bfd9bf2ef2798743ee092b07eb32f55c386d4c5f986a22a793f2886c407756e9c16f416ad6a039bec1f546c28e53e3cdd8b6a0b728e1b576dc73c0826fde10a8e8fa95dd840f27887fad9c43e523"
        let m4 = "06002541b8476e6f38c121f9f4fb63d99c09b32fff053d58a54bdcc8eef60a47d0bf53057418b6054eb260cca4d827c068edff9efb48f0eb93170c3dd24c413625f3a479a4a3aeef72b78938dd6342954f6c5deaa6046a2558dc4608c8eea2e95eee1d70053428193ab4b89efd6c6d731fe89281ffe7557f"
        let c1 = "0600fc874e03bdcfb575da8035aef06178ac0b9744d8a0971591abf2e4fb"
        let c2 = "060045bfb5a275a3d9e175bfb1acf36cc10a5585b4d0ad354d9b5c56f755"
        let c3 = "060051f0396cdadf6e74adb417b715bf3e93cc27e6aef94d2852fd4229970630df2c34bb76ec4c"
        let c4 = "06808ab0c2c5e3a660e3767d28d4bc0fda2d23fd515aaef131889c0a4b4b3ce8ccefcd95c2c5b9"

        [Byte](hex: m1)!.prettyPrint(8)
        [Byte](hex: m2)!.prettyPrint(8)
        [Byte](hex: m3)!.prettyPrint(8)
        [Byte](hex: m4)!.prettyPrint(8)
        [Byte](hex: c1)!.prettyPrint(8)
        [Byte](hex: c2)!.prettyPrint(8)
        [Byte](hex: c3)!.prettyPrint(8)
        [Byte](hex: c4)!.prettyPrint(8)
    }

    /*
    74 -->   WRITE
     534376320101000000008520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b
    <--  38   READ
    020000000000de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f
    <-- 120   READ
    06000dfa318c6337d600252260503124352ec6cddb69b86e299a47a9b1f1c18666e5cf8b000742bad609bfd9bf2ef2798743ee092b07eb3207d89eb0ec2da1f0c21e5c744a12757e6c0e71c752d67cc866257ef47f5d80bf9517203d2326737f1355fafd73d50b01c50a306b09cebed4c68d0a7cd6938a2a
    120 -->   WRITE
    060002bc1cc5f1f04c93319e47602d442ec1b32ffd053d58a54bdcc8eef60a47d0bf53057418b6054eb260cca4d827c068edff9efb48f0ebfd3ad7a2b6718d119bb64dbc149d002100f372763a43f1e81ed9d557f9958240d627ae0b78c89fd87a7e1d49800e9fa05452cb142cbf4b39635bf19b2f91ba7a
    30 -->   WRITE_WITH_PREVIOUS
    06005089769da0def9f37289f9e5ff6e78710b9747d8a0971591abf2e4fb
    <--  30   READ
    068082eb9d3660b82984f3c1c1051f8751ab5585b7d0ad354d9b5c56f755
   */
    private func prettyPrintSession4() {
        let m1 = "534376320101000000008520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b"
        let m2 = "020000000000de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
        let m3 = "06000dfa318c6337d600252260503124352ec6cddb69b86e299a47a9b1f1c18666e5cf8b000742bad609bfd9bf2ef2798743ee092b07eb3207d89eb0ec2da1f0c21e5c744a12757e6c0e71c752d67cc866257ef47f5d80bf9517203d2326737f1355fafd73d50b01c50a306b09cebed4c68d0a7cd6938a2a"
        let m4 = "060002bc1cc5f1f04c93319e47602d442ec1b32ffd053d58a54bdcc8eef60a47d0bf53057418b6054eb260cca4d827c068edff9efb48f0ebfd3ad7a2b6718d119bb64dbc149d002100f372763a43f1e81ed9d557f9958240d627ae0b78c89fd87a7e1d49800e9fa05452cb142cbf4b39635bf19b2f91ba7a"
        let c1 = "06005089769da0def9f37289f9e5ff6e78710b9747d8a0971591abf2e4fb"
        let c2 = "068082eb9d3660b82984f3c1c1051f8751ab5585b7d0ad354d9b5c56f755"

        [Byte](hex: m1)!.prettyPrint(8)
        [Byte](hex: m2)!.prettyPrint(8)
        [Byte](hex: m3)!.prettyPrint(8)
        [Byte](hex: m4)!.prettyPrint(8)
        [Byte](hex: c1)!.prettyPrint(8)
        [Byte](hex: c2)!.prettyPrint(8)
    }
}
