//
//  HeaderTests.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-10.
//

import XCTest
@testable import SaltChannel

class Channel: ByteChannel {
    func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ()) {}
    func write(_ data: [Data]) throws {}
}

class HeaderTests: XCTestCase {
    let sec = Data(bytes: [0x34, 0x11])
    let pub = Data(bytes: [0x34, 0x11])
    
    func testA1Header() {
        let channel = SaltChannel(channel: Channel(), sec: sec, pub: pub)

        let h1_a1: Data = channel.createHeader(from: PacketType.A1)
        let h2_a1: Data = channel.createHeader(from: PacketType.A1, first: true)
        let h3_a1: Data = channel.createHeader(from: PacketType.A1, last: true)
        let h4_a1: Data = channel.createHeader(from: PacketType.A1, first: true, last: true)

        XCTAssertTrue(h1_a1.count == 2)
        XCTAssertTrue(h2_a1.count == 2)
        XCTAssertTrue(h3_a1.count == 2)
        XCTAssertTrue(h4_a1.count == 2)

        XCTAssertTrue(h1_a1.first! == PacketType.A1.rawValue)
        XCTAssertTrue(h2_a1[0] == PacketType.A1.rawValue)
        XCTAssertTrue(h3_a1[0] == PacketType.A1.rawValue)
        XCTAssertTrue(h4_a1[0] == PacketType.A1.rawValue)
        
        let ha1_f_f = h1_a1.last!
        let ha1_t_f = h1_a1[1]
        let ha1_f_t = h1_a1[1]
        let ha1_t_t = h1_a1[1]
        
        XCTAssertTrue(firstBitSet(byte: ha1_f_f))
        XCTAssertTrue(lastBitSet(byte: ha1_f_f))

        XCTAssertTrue(ha1_t_f & 0b10000000 == 0)
        XCTAssertTrue(ha1_t_f & 0b00000001 != 0)
        
        XCTAssertTrue(ha1_f_t & 0b10000000 != 0)
        XCTAssertTrue(ha1_f_t & 0b00000001 == 0)
        
        XCTAssertTrue(ha1_t_t & 0b10000000 == 0)
        XCTAssertTrue(ha1_t_t & 0b00000001 == 0)
    }
    
}

func firstBitSet(byte: UInt8) -> Bool {
    return (byte & 0b10000000) != 0
}

func lastBitSet(byte: UInt8) -> Bool {
    return (byte & 0b00000001) != 0
}
