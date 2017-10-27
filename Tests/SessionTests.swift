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
        let timeKeeper = CounterTimeKeeper(timeArray: [1, 2, 3, 4])
        
        XCTAssertEqual(timeKeeper.time(), 1)
        XCTAssertEqual(timeKeeper.time(), 2)
        XCTAssertEqual(timeKeeper.time(), 3)
        XCTAssertEqual(timeKeeper.time(), 4)
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
        let nullTimeKeeper = NullTimeKeeper()
        
        XCTAssertEqual(nullTimeKeeper.time(), 0)
        XCTAssertEqual(nullTimeKeeper.time(), 0)
        XCTAssertEqual(nullTimeKeeper.time(), 0)
        XCTAssertEqual(nullTimeKeeper.time(), 0)
        XCTAssertEqual(nullTimeKeeper.time(), 0)
    }
    
    func testSessionCountertime() {
        let counterTimeKeeper = CounterTimeKeeper(timeArray: [1, 2, 3, 4, 5])
        
        XCTAssertEqual(counterTimeKeeper.time(), 1)
        XCTAssertEqual(counterTimeKeeper.time(), 2)
        XCTAssertEqual(counterTimeKeeper.time(), 3)
        XCTAssertEqual(counterTimeKeeper.time(), 4)
        XCTAssertEqual(counterTimeKeeper.time(), 5)
    }
    
    func testSessionRealtime() {
        let realTimeKeeper = RealTimeKeeper()
        
        let time1 = realTimeKeeper.time()
        XCTAssertTrue(time1 >= 0)
        let time2 = realTimeKeeper.time()
        XCTAssertTrue(time2 >= time1)
        let time3 = realTimeKeeper.time()
        XCTAssertTrue(time3 >= time2)
        let time4 = realTimeKeeper.time()
        XCTAssertTrue(time4 >= time3)
    }
}
