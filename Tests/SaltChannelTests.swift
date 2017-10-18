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
        let mock = BasicHostMock(mockdata: testDataSet)
        mock.start()
        let channel = SaltChannel(channel: mock,
                                  sec: Data(testDataSet.clientKeys.signSec),
                                  pub: Data(testDataSet.clientKeys.signPub))
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
