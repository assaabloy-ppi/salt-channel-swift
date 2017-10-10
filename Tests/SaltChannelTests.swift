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

    let a1 = testDataSet.get(.a1)
    let a2 = testDataSet.get(.a2)

    let msg1 = testDataSet.get(.msg1)
    let msg2 = testDataSet.get(.msg2)
    let msg3 = testDataSet.get(.msg3)
    let msg4 = testDataSet.get(.msg4)

    let plain1 = testDataSet.get(.plain1)
    let plain2 = testDataSet.get(.plain2)
    let plain3 = testDataSet.get(.plain3)
    let plain4 = testDataSet.get(.plain4)

    override func setUp() {
        super.setUp()
        DDLog.add(DDTTYLogger.sharedInstance)
        DDTTYLogger.sharedInstance.colorsEnabled = true
    }
    
    func testM1Validity() {
        
        
    }
    
    func testClientHandshake() {
        let mock = BasicHostMock(mockdata: testDataSet)
        
        var status = "Starting"
        defer { print("When leaving scope status is \(status)") }
        
        mock.start()
        let channel = SaltChannel(channel: mock, sec: css, pub: csp)
        
        /*
        XCTAssertThrowsError(try channel.getRemoteSignPub()) { error in
            XCTAssertEqual(error as? ChannelError, ChannelError.setupNotDone)
        }
         */
        
        do {
            try channel.handshake(clientEncSec: ces, clientEncPub: cep)
            XCTAssertEqual(try channel.getRemoteSignPub(), ssp)
        
            channel.register(callback:
                { data in
                    DDLogInfo("Received Callback R2 for R1")
                    status = "Received Callback"
                    XCTAssertEqual(data, self.plain2)
                }, errorhandler:
                { error in
                    print(error.localizedDescription)
                    DDLogError("Received error instead of R2 for R1:")
                    status = "Error"
                    XCTAssert(false)
            })
            
            try channel.write([self.plain1])
            sleep(8)

        } catch {
            print(error)
            XCTAssertTrue(false)
        }
    }
    
    func testEcho() {
        /*
        let mock = EchoMock(mockdata: testDataSet)
        
        let css = testDataSet.get(.client_sk_sec)
        let csp = testDataSet.get(.client_sk_pub)
        let cep = testDataSet.get(.client_ek_pub)
        let ces = testDataSet.get(.client_ek_sec)
        let ssp = testDataSet.get(.host_sk_pub)
        
        let m1 = testDataSet.get(.m1)
        
        let channel = SaltChannel(channel: mock, sec: css, pub: csp)
        let m1Hash = try? channel.m1(time: 0, myEncPub: cep)
        */
    }
}
