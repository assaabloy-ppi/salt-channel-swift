//
//  SessionTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-09.
//

import XCTest
@testable import SaltChannel

class SessionTests: XCTestCase {

    
    func testInitSession() {
        let key = Data(bytes: [
                0x55, 0x29, 0xce, 0x8c, 0xcf, 0x68, 0xc0, 0xb8,
                0xac, 0x19, 0xd4, 0x37, 0xab, 0x0f, 0x5b, 0x32,
                0x72, 0x37, 0x82, 0x60, 0x8e, 0x93, 0xc6, 0x26,
                0x4f, 0x18, 0x4b, 0xa1, 0x52, 0xc2, 0x35, 0x7b ])
        var session = Session(key: key)
        let time = session.time
        // print(time)
        XCTAssertTrue(time > 0)
        XCTAssertFalse(session.handshakeDone)
        
        let time2 = session.time
        // print(time2)

        XCTAssertTrue(time2 > 0)
        XCTAssertTrue(time2 > time)
        XCTAssertTrue(time2 < session.time)

        session.handshakeDone = true
        XCTAssertTrue(session.handshakeDone)
    }
}
