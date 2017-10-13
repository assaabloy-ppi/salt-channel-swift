//
//  SocketChannelTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-13.
//

import XCTest
import os.log

@testable import SaltChannel

class SocketChannelTests: XCTestCase {
    let log = OSLog(subsystem: "salt.aa.st", category: "SocketTest")

     func testExtractProtocolsFromA2() {
        let host = "192.168.1.1"
        let port: UInt32 = 8080
        let channel = SocketChannel(host: host, port: port)
        XCTAssertEqual(channel.host, host)
        XCTAssertEqual(channel.port, port)
        
        os_log("Testing Socket ByteChannel for server %s:%s", log: log, type: .debug, host, port)
    }
}
