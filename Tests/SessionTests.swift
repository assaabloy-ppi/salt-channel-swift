//
//  SessionTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-09.
//

import XCTest
@testable import SaltChannel

class SessionTests: XCTestCase {

    let key = Data(bytes: [
        0x55, 0x29, 0xce, 0x8c, 0xcf, 0x68, 0xc0, 0xb8,
        0xac, 0x19, 0xd4, 0x37, 0xab, 0x0f, 0x5b, 0x32,
        0x72, 0x37, 0x82, 0x60, 0x8e, 0x93, 0xc6, 0x26,
        0x4f, 0x18, 0x4b, 0xa1, 0x52, 0xc2, 0x35, 0x7b ])
    
    func testNullTimeKeeper() {
        let timeKeeper = NullTimeKeeper()
        XCTAssertTrue(timeKeeper.time() == 0)
        XCTAssertTrue(timeKeeper.time() == 0)
    }
    
    func testCounterTimeKeeper() {
        var timeKeeper = CounterTimeKeeper()
        XCTAssertTrue(timeKeeper.time() == 1)
        XCTAssertTrue(timeKeeper.time() == 2)
        XCTAssertTrue(timeKeeper.time() == 3)
        XCTAssertTrue(timeKeeper.time() == 4)
    }
    
    func testRealTimeKeeper() {
        let timeKeeper = RealTimeKeeper()
        
        let time = timeKeeper.time()
        XCTAssertTrue(time > 0.0)
        
        let time2 = timeKeeper.time()        
        XCTAssertTrue(time2 > 0)
        XCTAssertTrue(time2 > time)
        XCTAssertTrue(time2 < timeKeeper.time())
    }
    
    func testSessionNulltime() {
        let session = Session(key: key, timeKeeper: NullTimeKeeper())
        
        let time = session.time
        // print(time)
        XCTAssertTrue(time == 0)
        XCTAssertFalse(session.handshakeDone)
        
        let time2 = session.time
        // print(time2)
        
        XCTAssertTrue(time2 == 0)
        XCTAssertTrue(session.time == 0)
        XCTAssertTrue(session.time == 0)
        
        session.handshakeDone = true
        XCTAssertTrue(session.handshakeDone)
    }
    
    func testSessionCountertime() {
        let session = Session(key: key, timeKeeper: CounterTimeKeeper())
        
        let time = session.time
        // print(time)
        XCTAssertTrue(time == 1)
        XCTAssertFalse(session.handshakeDone)
        
        let time2 = session.time
        // print(time2)
        
        XCTAssertTrue(time2 == 2)
        XCTAssertTrue(session.time == 3)
        XCTAssertTrue(session.time == 4)

        session.handshakeDone = true
        XCTAssertTrue(session.handshakeDone)
    }
    
    func testSessionRealtime() {
        let session = Session(key: key, timeKeeper: RealTimeKeeper())
        
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
