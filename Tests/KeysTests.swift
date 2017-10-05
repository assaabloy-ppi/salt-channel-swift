//  KeysTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-04.

import XCTest
import CocoaLumberjack
import Sodium

@testable import SaltChannel

class KeysTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        DDTTYLogger.sharedInstance.colorsEnabled = true
    }
    
    func testSodiumGeneratedKeys() {
        let keypit = TestKeyGenerator.sodiumGeneratedKeys()
        XCTAssertNotNil(keypit)
        
        XCTAssertEqual(keypit.keyPairs.count, 2)
        XCTAssertNotNil(keypit.keypair(for: .clientsign))
        XCTAssertNotNil(keypit.keypair(for: .clientencrypt))
        
        XCTAssertEqual(keypit.pubKeys.count, 2)
        XCTAssertNotNil(keypit.pubkey(for: .serversign))
        XCTAssertNotNil(keypit.pubkey(for: .serverencrypt))
        
        XCTAssertTrue(keypit.selfVerify())
    }
    
    func testGetGoodKeys() {
        let keypit = TestKeyGenerator.godKeys()
        XCTAssertNotNil(keypit)
        
        XCTAssertEqual(keypit.keyPairs.count, 2)
        XCTAssertNotNil(keypit.keypair(for: .clientsign))
        XCTAssertNotNil(keypit.keypair(for: .clientencrypt))
        
        XCTAssertEqual(keypit.pubKeys.count, 2)
        XCTAssertNotNil(keypit.pubkey(for: .serversign))
        XCTAssertNotNil(keypit.pubkey(for: .serverencrypt))
        
        XCTAssertTrue(keypit.selfVerify())
    }
    
    func testBadFormatKeys() {
        let keypit = TestKeyGenerator.badFormatKeys()
        XCTAssertNotNil(keypit)
        
        XCTAssertTrue(keypit.keyPairs.count == 0)
        XCTAssertNil(keypit.keypair(for: .clientsign))
        XCTAssertNil(keypit.keypair(for: .clientencrypt))
        XCTAssertNil(keypit.keypair(for: .serversign))
        XCTAssertNil(keypit.keypair(for: .serverencrypt))
        
        XCTAssertTrue(keypit.pubKeys.count == 0)
        XCTAssertNil(keypit.pubkey(for: .serversign))
        XCTAssertNil(keypit.pubkey(for: .serverencrypt))
        
        // XCTAssertFalse(keypit.selfVerify())
    }
    
    func testIncompatibleKeys() {
        let keypit = TestKeyGenerator.incompatibleFormatKeys()
        XCTAssertNotNil(keypit)
        
        XCTAssertEqual(keypit.keyPairs.count, 2)
        XCTAssertNotNil(keypit.keypair(for: .clientsign))
        XCTAssertNotNil(keypit.keypair(for: .clientencrypt))
        
        XCTAssertEqual(keypit.pubKeys.count, 2)
        XCTAssertNotNil(keypit.pubkey(for: .serversign))
        XCTAssertNotNil(keypit.pubkey(for: .serverencrypt))
        
        // XCTAssertFalse(keypit.selfVerify())
    }
}


