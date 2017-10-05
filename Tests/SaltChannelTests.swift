//  SaltChannelTests.swift
//  SaltChannelTests
//
//  Created by Håkan Olsson on 2017-06-02.
//  Copyright © 2017 Håkan Olsson. All rights reserved.

import XCTest
import Sodium
import Binson
import CocoaLumberjack

@testable import SaltChannel

let sodium = Sodium()

class SaltChannelHostMock : ByteChannel {

    var callback: [(Data) -> ()] = []
    var didReceiveMsg = false
    var readData: Data = Data()
    var writeData: [Data] = []
    
    let m1 = sodium.utils.hex2bin("534376320100000000008520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a")
    let m2 = sodium.utils.hex2bin("020000000000de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f")!
    
    let m3 = sodium.utils.hex2bin("0600669544da0d2ec8a03766f53e0580bc3cc6cddb69b86e299a47a9b1f1c18666e5cf8b000742bad609bfd9bf2ef2798743ee092b07eb329899ab741476448b5f34e6513e1d3cec7469fbf03112a098acd397ab933c61a2319eb6e0b4561ed9ce010d998f5bc10d6d17f88cebf961d1377faccc8a781c2c")!
    let m4: Data = sodium.utils.hex2bin("0600a342f9538471d266100bfc3b9e794f40b32ffd053d58a54bdcc8eef60a47d0bf53057418b6054eb260cca4d827c068edff9efb48f0eb6856903f7f1006e43d7e21915f72e729a26bf6bc5f59bc7ed2e1456a8a5fc9ecc6e2cd3c48e0103769ccd6faa87e45b8b256207a2e341cd068d433c7296fb374")!
    let d1 = sodium.utils.hex2bin("06005089769da0def9f37289f9e5ff6e78710b9747d8a0971591abf2e4fb")!
    let d2 = sodium.utils.hex2bin("060082eb9d3660b82984f3c1c1051f8751ab5585b7d0ad354d9b5c56f755")!
    
    func start() {

        DispatchQueue.global().async {
            self.handShake()
        }
    }
    
    func handShake() {
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], m1)
            self.didReceiveMsg = false
        }
        sleep(4)
        
        callback.first!(m2)
        
        sleep(4)
        callback.first!(m3)
        
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], m4)
            self.didReceiveMsg = false
        }
        
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], d1)
            self.didReceiveMsg = false
        }
        
        sleep(4)
        callback.first!(d2)
    }
    
    func write(_ data: [Data]) throws {
        print("write is called")
        writeData = data
        didReceiveMsg = true
    }
    
    func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ()) {
        print("register is called")
        self.callback.append(callback)
    }
}

class SaltChannelTests: XCTestCase {
    let sodium = Sodium()
    
    override func setUp() {
        super.setUp()
        
        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        DDTTYLogger.sharedInstance.colorsEnabled = true
    }
    
    func testHandshake() {
        let keypit = TestKeyGenerator.godKeys()
        // let keypit = TestKeyGenerator.sodiumGeneratedKeys()
        XCTAssertNotNil(keypit)

        let clientSignSec = Data(keypit.keypair(for: .clientsign)!.sec)
        let clientSignPub = Data(keypit.keypair(for: .clientsign)!.pub)
        let clientEncSec =  Data(keypit.keypair(for: .clientencrypt)!.sec)
        let clientEncPub =  Data(keypit.keypair(for: .clientencrypt)!.pub)
        let serverSignPub = Data(keypit.pubkey(for: .serversign)!.pub)
        
        let r1 = sodium.utils.hex2bin("010505050505")!
        let r2 = sodium.utils.hex2bin("010505050505")!
        
        let mock = SaltChannelHostMock()
        mock.start()
        let channel = SaltChannel(channel: mock, sec: clientSignSec, pub: clientSignPub)
        
        XCTAssertThrowsError(try channel.getRemoteSignPub()) { error in
            XCTAssertEqual(error as? ChannelError, ChannelError.setupNotDone)
        }
        
        do {
            try channel.handshake(clientEncSec: clientEncSec, clientEncPub: clientEncPub)
        
            XCTAssertEqual(try channel.getRemoteSignPub(), serverSignPub)
        
            channel.register(callback:
                { data in
                    DDLogInfo("Received Callback R2 for R1")
                    XCTAssertEqual(data, r2)
                }, errorhandler:
                { error in
                    DDLogError("Received error instead of R2 for R1: /(error)")
                    XCTAssert(false)
            })
            
            try channel.write([r1])
            sleep(8)

        } catch {
            print(error)
            XCTAssertTrue(false)
        }
    }
}
