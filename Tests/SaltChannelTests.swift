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
    
    enum ProtocolAStrings {
        static let saltStr = "SCv2------"
        static let  blankStr = "----------"
        static let  echoStr = "ECHO------"
    }
    /*
     let salt  = Data(saltStr.utf8)  // "534376322d2d2d2d2d2d"
     let blank = Data(blankStr.utf8) // "2d2d2d2d2d2d2d2d2d2d"
     let echo  = Data(echoStr.utf8)  // "4543484f2d2d2d2d2d2d"
     */
    
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
    
    func runClientHandshake(testDataSet: TestDataSet) {
        do {
            let signSec = Data(testDataSet.clientKeys.signSec)
            let signPub = Data(testDataSet.clientKeys.signPub)
        
            let mock = BasicHostMock(mockdata: testDataSet)
            mock.start()
        
            let channel = SaltChannel(channel: mock, sec: signSec, pub: signPub)
            channel.register(callback: receiver, errorhandler: errorhandler)
        
            if testDataSet.handshake != nil {
                try channel.handshake(clientEncSec: Data(testDataSet.clientKeys.diffiSec),
                                      clientEncPub: Data(testDataSet.clientKeys.diffiPub))
                XCTAssertEqual(try channel.getRemoteSignPub(), Data(testDataSet.hostKeys.signPub))
            }
        
            for transfer in testDataSet.transfers {
                if transfer.toHost {
                    try channel.write([Data(transfer.plain)])
                } else {
                    waitForData(Data(transfer.plain))
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
    
    func runVerifyA1Data(testDataSet: TestDataSet, type: Int, pubKey: Data?) {
        do {
            let a1 = Data(testDataSet.abox!.a1)
            
            let channel = SaltChannel(channel: DummyChannel(),
                                      sec: Data(testDataSet.clientKeys.signSec),
                                      pub: Data(testDataSet.clientKeys.signPub))

            let data = try channel.writeA1(type: type, pubKey: pubKey)
            XCTAssertEqual(a1, data)
        } catch {
            print(error)
            XCTFail("Got exception")
        }
    }
    
    func runVerifyA2Data(testDataSet: TestDataSet, expectedData: [(first: String, second: String)]) {
        do {
            let a2 = Data(testDataSet.abox!.a2)
            
            let channel = SaltChannel(channel: DummyChannel(),
                                      sec: Data(testDataSet.clientKeys.signSec),
                                      pub: Data(testDataSet.clientKeys.signPub))
            channel.session = Session(key: Data([0x23, 0x34, 0x01]), timeKeeper: NullTimeKeeper())
            
            let protocolA: [(first: String, second: String)] = try channel.readA2(data: a2) ?? []
            
            XCTAssertEqual(protocolA.count, expectedData.count)
            for index in 0..<protocolA.count {
                XCTAssertEqual(protocolA[index].first, expectedData[index].first)
                XCTAssertEqual(protocolA[index].second, expectedData[index].second)
            }
        } catch {
            print(error)
            XCTFail("Got exception")
        }
    }
    
    /*********************************************************/
    // Test A1
    
    func testVerifySession2A1Data() {
        runVerifyA1Data(testDataSet: SaltTestData().session2TestData,
                        type: 0,
                        pubKey: nil)
    }
    
    func testVerifySessionALongA1Data() {
        let testData = SaltTestData().sessionALong
        runVerifyA1Data(testDataSet: testData,
                        type: 1,
                        pubKey: Data(testData.clientKeys.signPub))
    }
    
    func testNegativeA1() {
        let clientKeys = SaltTestData().session1TestData.clientKeys
        let channel = SaltChannel(channel: DummyChannel(), sec: Data(clientKeys.signSec), pub: Data(clientKeys.signPub))

        do {
            _ = try channel.writeA1(type: 1)
            XCTFail("Should have failed")
        } catch { }
        
        do {
            _ = try channel.writeA1(type: 0, pubKey: Data(clientKeys.signPub))
            XCTFail("Should have failed")
        } catch { }
        
        do {
            _ = try channel.writeA1(type: 48, pubKey: Data(clientKeys.signPub))
            XCTFail("Should have failed")
        } catch { }
        
        do {
            _ = try channel.writeA1(type: 48, pubKey: Data([0x22, 0x34]))
            XCTFail("Should have failed")
        } catch { }
        
        do {
            _ = try channel.writeA1(type: 48, pubKey: nil)
            XCTFail("Should have failed")
        } catch { }
    }
    
    /*********************************************************/
    // Test A2
    
    func testVerifySession2A2Data() {
        runVerifyA2Data(testDataSet: SaltTestData().session2TestData,
                        expectedData: [
                            (first: ProtocolAStrings.saltStr, ProtocolAStrings.echoStr)
            ])
    }
    
    func testVerifySessionALongA2Data() {
        runVerifyA2Data(testDataSet: SaltTestData().sessionALong,
                        expectedData: [
                            (first: ProtocolAStrings.saltStr, ProtocolAStrings.echoStr),
                            (first: ProtocolAStrings.saltStr, ProtocolAStrings.blankStr)
            ])
    }
    
    /*********************************************************/
    // Test handshake
    
    func testSession1ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session1TestData)
    }
    
    func testSession2ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session2TestData)
    }
    
    func testSession3ClientHandshake() {
        runClientHandshake(testDataSet: SaltTestData().session3TestData)
    }
}
