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
            XCTAssert(false, "Did not receive data")
        }
    }
    
    func receiver(data: Data) {
        receivedData.append(data)
    }
    
    func errorhandler(error: Error) {
        print(error)
        XCTAssert(false, "Got error: " + error.localizedDescription)
    }
    
    func runClientHandshake(testDataSet: TestDataSet) throws {
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
    }
    
    func testVerifySession2A2Data() throws {
        let testdata = SaltTestData().session2TestData
        let sec = Data(testdata.clientKeys.signSec)
        let pub = Data(testdata.clientKeys.signPub)
        
        let saltStr  = "SCv2------"
        let blankStr = "----------"
        let echoStr  = "ECHO------"
        
        let salt  = Data(saltStr.utf8)  // "534376322d2d2d2d2d2d"
        let blank = Data(blankStr.utf8) // "2d2d2d2d2d2d2d2d2d2d"
        let echo  = Data(echoStr.utf8)  // "4543484f2d2d2d2d2d2d"
        
        guard let box = testdata.abox else {
            XCTFail("Test data without ABox")
            return
        }
        
        let a2_type0 = Data(box.a2)
        let a2_type1 = Data(box.a2long)
        
        let channel = SaltChannel(channel: DummyChannel(), sec: sec, pub: pub)
        channel.session = Session(key: Data([0x23, 0x34, 0x01]), timeKeeper: NullTimeKeeper())
        
        let protocols1: [(first: String, second: String)] = try channel.readA2(data: a2_type0) ?? []
        let protocols2: [(first: String, second: String)] = try channel.readA2(data: a2_type1) ?? []
        
        XCTAssertEqual(protocols1.count, 1)
        XCTAssertEqual(protocols2.count, 2)
        
        XCTAssertEqual(protocols1[0].first, "SCv2------")
        XCTAssertEqual(protocols1[0].second, "----------")
        
        XCTAssertEqual(protocols2[0].first, "SCv2------")
        XCTAssertEqual(protocols2[0].second, "ECHO------")
        XCTAssertEqual(protocols2[1].first, "SCv2------")
        XCTAssertEqual(protocols2[1].second, "----------")
    }
    
    func testVerifySession2A1Data() throws {
        let testdata = SaltTestData().session2TestData
        let sec = Data(testdata.clientKeys.signSec)
        let pub = Data(testdata.clientKeys.signPub)
        
        guard let box = testdata.abox else {
            XCTFail("Test data without ABox")
            return
        }
        
        let a1_type0 = Data(box.a1)
        let a1_type1 = Data(box.a1long)

        let channel = SaltChannel(channel: DummyChannel(), sec: sec, pub: pub)
        
        let data0 = try channel.writeA1(type: 0)
        let data1 = try channel.writeA1(type: 1, pubKey: pub)
        
        XCTAssertEqual(a1_type0, data0)
        XCTAssertEqual(a1_type1, data1)
        
        do {
            _ = try channel.writeA1(type: 1)
            XCTFail("Should have failed")
        } catch { }
        
        do {
            _ = try channel.writeA1(type: 0, pubKey: pub)
            XCTFail("Should have failed")
        } catch { }
        
        do {
            _ = try channel.writeA1(type: 48, pubKey: pub)
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
    
    func testSession1ClientHandshake() throws {
        try runClientHandshake(testDataSet: SaltTestData().session1TestData)
    }
    
    func testSession2ClientHandshake() throws {
        try runClientHandshake(testDataSet: SaltTestData().session2TestData)
    }
    
    func testSession3ClientHandshake() throws {
        try runClientHandshake(testDataSet: SaltTestData().session3TestData)
    }
}
