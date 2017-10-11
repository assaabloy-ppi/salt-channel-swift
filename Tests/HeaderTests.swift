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
    
    func testPackeTypeToData() {
        let u =   Data(bytes: [0x00])
        let m1 =  Data(bytes: [0x01])
        let m2 =  Data(bytes: [0x02])
        let m3 =  Data(bytes: [0x03])
        let m4 =  Data(bytes: [0x04])
        let app = Data(bytes: [0x05])
        let enc = Data(bytes: [0x06])
        let a1 =  Data(bytes: [0x08])
        let a2 =  Data(bytes: [0x09])
        let tt =  Data(bytes: [0x0A])
        let ma =  Data(bytes: [0x0B])

        XCTAssert(u == PacketType.Unknown.data)
        XCTAssert(m1 == PacketType.M1.data)
        XCTAssert(m2 == PacketType.M2.data)
        XCTAssert(m3 == PacketType.M3.data)
        XCTAssert(m4 == PacketType.M4.data)
        XCTAssert(app == PacketType.App.data)
        XCTAssert(enc == PacketType.Encrypted.data)
        XCTAssert(a1 == PacketType.A1.data)
        XCTAssert(a2 == PacketType.A2.data)
        XCTAssert(tt == PacketType.TT.data)
        XCTAssert(ma == PacketType.MultiApp.data)
        
        XCTAssertFalse(tt == PacketType.Unknown.data)
    }
    
    func testPackeTypeToHex() {
        let u =   "0x00"
        let m1 =  "0x01"
        let m2 =  "0x02"
        let m3 =  "0x03"
        let m4 =  "0x04"
        let app = "0x05"
        let enc = "0x06"
        let a1 =  "0x08"
        let a2 =  "0x09"
        let tt =  "0x0a"
        let ma =  "0x0b"
        
        XCTAssertEqual(u, PacketType.Unknown.hex)
        XCTAssertEqual(m1, PacketType.M1.hex)
        XCTAssertEqual(m2, PacketType.M2.hex)
        XCTAssertEqual(m3, PacketType.M3.hex)
        XCTAssertEqual(m4, PacketType.M4.hex)
        XCTAssertEqual(app, PacketType.App.hex)
        XCTAssertEqual(enc, PacketType.Encrypted.hex)
        XCTAssertEqual(a1, PacketType.A1.hex)
        XCTAssertEqual(a2, PacketType.A2.hex)
        XCTAssertEqual(tt, PacketType.TT.hex)
        XCTAssertEqual(ma, PacketType.MultiApp.hex)
        
        XCTAssertFalse(tt == PacketType.Unknown.hex)
    }
    
    func testReadBadHeader() {
        let channel = SaltChannel(channel: Channel(), sec: sec, pub: pub)

        let bad1 = Data(bytes: [0xFF, 0x00])
        let bad2 = Data(bytes: [0x08, 0x80, 0x80])
        let bad3 = Data(bytes: [0x08])
        let bad4 = Data(bytes: [0xFF])
        let bad5 = Data(bytes: [0x00, 0x81])
        
        let (t1, f1, l1) = channel.readHeader(from: bad1)
        let (t2, f2, l2) = channel.readHeader(from: bad2)
        let (t3, f3, l3) = channel.readHeader(from: bad3)
        let (t4, f4, l4) = channel.readHeader(from: bad4)
        let (t5, f5, l5) = channel.readHeader(from: bad5)

        XCTAssertFalse(l1 && l2 && l3 && l4 && l5)
        XCTAssertFalse(f1 && f2 && f3 && f4 && f5)
        
        XCTAssertTrue(t1 == PacketType.Unknown)
        XCTAssertTrue(t2 == PacketType.Unknown)
        XCTAssertTrue(t3 == PacketType.Unknown)
        XCTAssertTrue(t4 == PacketType.Unknown)
        XCTAssertTrue(t5 == PacketType.Unknown)
    }

    func testReadA1Header() {
        let channel = SaltChannel(channel: Channel(), sec: sec, pub: pub)

        let h1_a1 = Data(bytes: [0x08, 0x00])
        let h2_a1 = Data(bytes: [0x08, 0x80])
        let h3_a1 = Data(bytes: [0x08, 0x01])
        let h4_a1 = Data(bytes: [0x08, 0x81])

        print("A1 plain: \(h1_a1.hex)") // 0x0800
        print("A1 first: \(h2_a1.hex)") // 0x0880
        print("A1 last: \(h3_a1.hex)")  // 0x0801
        print("A1 both: \(h4_a1.hex)")  // 0x0881
        
        let (t1, f1, l1) = channel.readHeader(from: h1_a1)
        let (t2, f2, l2) = channel.readHeader(from: h2_a1)
        let (t3, f3, l3) = channel.readHeader(from: h3_a1)
        let (t4, f4, l4) = channel.readHeader(from: h4_a1)

        XCTAssertTrue(f2 && f4 && l3 && l4)
        XCTAssertFalse(f1 && f3 && l1 && l2)

        XCTAssertTrue(t1 == PacketType.A1)
        XCTAssertTrue(t2 == PacketType.A1)
        XCTAssertTrue(t3 == PacketType.A1)
        XCTAssertTrue(t4 == PacketType.A1)
    }
    
    func testCreateBadHeader() {
        let channel = SaltChannel(channel: Channel(), sec: sec, pub: pub)
        
        let unknown: Data = channel.createHeader(from: PacketType.Unknown)
        XCTAssertTrue(unknown.count == 2)
        XCTAssertTrue(unknown[0] == PacketType.Unknown.rawValue)

        XCTAssertFalse(firstBitSet(byte: unknown[1]))
        XCTAssertFalse(lastBitSet(byte: unknown[1]))
    }
    
    func testCreateA1Header() {
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
        
        print("A1 plain: \(h1_a1.hex)") // 0x0800
        print("A1 first: \(h2_a1.hex)") // 0x0880
        print("A1 last: \(h3_a1.hex)")  // 0x0801
        print("A1 both: \(h4_a1.hex)")  // 0x0881

        let ha1_f_f = h1_a1[1]
        let ha1_t_f = h2_a1[1]
        let ha1_f_t = h3_a1[1]
        let ha1_t_t = h4_a1[1]
        
        XCTAssertFalse(firstBitSet(byte: ha1_f_f))
        XCTAssertFalse(lastBitSet(byte: ha1_f_f))

        XCTAssertTrue(firstBitSet(byte: ha1_t_f))
        XCTAssertFalse(lastBitSet(byte: ha1_t_f))
        
        XCTAssertFalse(firstBitSet(byte: ha1_f_t))
        XCTAssertTrue(lastBitSet(byte: ha1_f_t))
        
        XCTAssertTrue(firstBitSet(byte: ha1_t_t))
        XCTAssertTrue(lastBitSet(byte: ha1_t_t))
    }
    
}

func firstBitSet(byte: UInt8) -> Bool {
    return (byte & 0b10000000) != 0
}

func lastBitSet(byte: UInt8) -> Bool {
    return (byte & 0b00000001) != 0
}
