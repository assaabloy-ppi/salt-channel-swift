//
//  ByteIntegerTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-11-07.
//

import XCTest
@testable import SaltChannel

class ByteIntegerTests: XCTestCase {
    
    func testUIntToBytes() {
        let u1: UInt32 = 32767
        let b1: [Byte] = u1.toBytes()
        XCTAssertEqual(b1.toHexString(), "ff7f0000")

        let u2: UInt32 = 32768
        let b2: [Byte] = u2.toBytes()
        XCTAssertEqual(b2.toHexString(), "00800000")

        let u3: UInt32 = 2147483647
        let b3: [Byte] = u3.toBytes()
        XCTAssertEqual(b3.toHexString(), "ffffff7f")

        let u2a: UInt64 = 2147483648
        let b2a: [Byte] = u2a.toBytes()
        XCTAssertEqual(b2a.toHexString(), "0000008000000000")

        let u4a: UInt64 = 9223372036854775807
        let b4a: [Byte] = u4a.toBytes()
        XCTAssertEqual(b4a.toHexString(), "ffffffffffffff7f")
    }
    
    func testPackTime() {
        let time: TimeInterval = 345554.3212
        
        let t_bytes = packBytes(UInt64(time), parts: 4)
        let t_bytes2 = UInt32(time).toBytes()

        XCTAssertEqual(t_bytes.bytes, t_bytes2)
    }
}
