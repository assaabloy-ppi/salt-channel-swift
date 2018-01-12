//
//  SocketChannelTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-13.
//

import XCTest
import os.log

@testable import SaltChannel

/*  To test versus a standard Socket server use
    % ncat -k -l -p 2033
 */

/* To test versus a Java echo server us
   % java -cp pot.jar potx.dev.echo.Server
    Cleartext echo server started on port 2033.
    Salt Channel echo server started on port 2034.
 */

class SocketChannelTests: XCTestCase {
    let log = OSLog(subsystem: "salt.aa.st", category: "SocketTest")
    
    let ping = Data("Ping".utf8)
    let echo = Data(bytes:[0x01, 0x00, 0x00, 0x00, 0x02])
    
    let hostname  = "localhost"
    let plainport = 2033
    let saltport  = 2034

    func testClientSocket() {
        let socket = ClientSocket(hostname, plainport)
        
        socket.start()
        let time = try? socket.ping(data: echo)
        XCTAssertNotEqual(time, 0)
        
        // socket.flush()
        
        let data = try? socket.echo(data: echo)
        XCTAssertEqual(echo, data)
    }
    
    func testSaltClientSocket() {
        let socket = ClientSocket(hostname, saltport)
        
        socket.start()
        let time = try? socket.ping(data: ping)
    }
}
