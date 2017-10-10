//  SaltChannelTests.swift
//  SaltChannelTests
//
//  Created by Håkan Olsson on 2017-06-02.

import XCTest
import CocoaLumberjack
import Sodium
import Binson

@testable import SaltChannel

let sodium = Sodium()
let testDataSet = SaltTestData(name: "Basic")

class SaltChannelTests: XCTestCase {
    let sodium = Sodium()
    let css = testDataSet.get(.client_sk_sec)
    let csp = testDataSet.get(.client_sk_pub)
    let cep = testDataSet.get(.client_ek_pub)
    let ces = testDataSet.get(.client_ek_sec)
    let ssp = testDataSet.get(.host_sk_pub)
    
    let m1 = testDataSet.get(.m1)
    let m2 = testDataSet.get(.m2)
    let m3 = testDataSet.get(.m3)
    let m4 = testDataSet.get(.m4)

    let msg1 = testDataSet.get(.msg1)
    let msg2 = testDataSet.get(.msg2)
    
    let plain1 = testDataSet.get(.plain1)
    let plain2 = testDataSet.get(.plain2)
    
    var receivedData: [Data] = []
    
    override func setUp() {
        super.setUp()
        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        DDTTYLogger.sharedInstance.colorsEnabled = true
    }
    
    func waitForData(_ data: Data){
        if WaitUntil.waitUntil(10, self.receivedData.isEmpty == false) {
            XCTAssertEqual(receivedData.first, data)
            receivedData.remove(at: 0)
        }
    }
    
    func receiver(data: Data){
        receivedData.append(data)
    }
    
    func errorhandler(error: Error){
        XCTAssert(true, error.localizedDescription)
    }
    
    func testClientHandshake() throws{
        let mock = BasicHostMock(mockdata: testDataSet)
        mock.start()
        let channel = SaltChannel(channel: mock, sec: css, pub: csp)
        channel.register(callback: receiver, errorhandler: errorhandler)
        
        try channel.handshake(clientEncSec: ces, clientEncPub: cep)
        XCTAssertEqual(try channel.getRemoteSignPub(), self.ssp)
        try channel.write([self.plain1])
        waitForData(self.plain2)
    }
}
