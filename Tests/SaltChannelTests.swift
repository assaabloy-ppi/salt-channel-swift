//  SaltChannelTests.swift
//  SaltChannelTests
//
//  Created by Håkan Olsson on 2017-06-02.
import XCTest
import Sodium

@testable import SaltChannel

class SaltChannelTests: XCTestCase {
    let sodium = Sodium()
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
    
    func runClientHandshake(testDataSet: TestDataSet, timeKeeper: TimeKeeper) {
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
                var pubKey: Data? = nil
                if abox.pubKey != nil {
                    pubKey = Data(abox.pubKey!)
                }
                let unpackedA2 = try channel.negotiate(pubKey: pubKey)
                XCTAssertEqual(unpackedA2.count, abox.unpackedA2.count)
                for index in 0..<unpackedA2.count {
                    XCTAssertEqual(unpackedA2[index].first, abox.unpackedA2[index].first)
                    XCTAssertEqual(unpackedA2[index].second, abox.unpackedA2[index].second)
                }
            }
            
            /*** Handshake ***/
            if testDataSet.handshake != nil {
                try channel.handshake(clientEncSec: Data(testDataSet.clientKeys.diffiSec),
                                      clientEncPub: Data(testDataSet.clientKeys.diffiPub))
                XCTAssertEqual(try channel.getRemoteSignPub(), Data(testDataSet.hostKeys.signPub))
            }
        
            /*** Data transfer ***/
            for transfer in testDataSet.transfers {
                if transfer.toHost {
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
    // Test handshake, a1 and a2
    
    func testSession1ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session1TestData, timeKeeper: NullTimeKeeper())
    }
    
    func testSession2ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session2TestData, timeKeeper: NullTimeKeeper())
    }
    
    func testSession3ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session3TestData, timeKeeper: CounterTimeKeeper(timeArray: [1, 3, 3, 5]))
    }
    
    func testSessionALongClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().sessionALong, timeKeeper: NullTimeKeeper())
    }
}
