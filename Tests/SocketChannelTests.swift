//  SocketChannelTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-13.

import XCTest

@testable import SaltChannel

/*  To test versus a standard Socket server use
    % ncat -k -l -p 4711
 */

/* To test versus a Java echo server us
   % java -cp pot.jar potx.dev.echo.Server
    Cleartext echo server started on port 2033.
    Salt Channel echo server started on port 2034.
 */
class SocketChannelTests: XCTestCase {
    let ping = "Ping\r\n"
    let echo = Data(bytes: [0x01, 0x00, 0x00, 0x00, 0x02])
    
    let hostname  = "localhost"
    
    let plainport = 2031
    let saltport  = 2032
    let potport   = 2033
    
    let pingport  = 4711
    
    var reply: Data?

    func testNetHandler() {
        let client = NetHandler()
        client.sendText("Hallå nu startar vi chatten!")
        print(client.sendAndReceiveText("Hej vad heter du?")!)
    }
    
    // Test manually versus an ncat listener (ncat -k -l -p 4711)
    // If server is not started
    // 2018-01-15 13:12:01.243011+0100 xctest[70603:3482065] []
    // nw_connection_get_connected_socket 1 Connection has no connected handler
    // and testcase is hanging
    // If we don't type a reply in the ncat terminal, the client request will
    // timeout after 70 seconds and the exception is caught
    func testClientSocketPing() {
        do {
            let socket = try ClientSocket(hostname, pingport, mode: .sync).start()
            
            sleep(2)
            
            guard case socket.status().input = Stream.Status.open,
                case socket.status().output = Stream.Status.open else {
                XCTFail("Stream not opened")
                return
            }
            
            let (time, pong) = try socket.ping(ping)
            print("It took \(time) seconds to get \(pong)")
            XCTAssertNotEqual(time, 0)
            socket.stop()
        } catch {
            XCTFail("Can not open socket: \(error)")
            return
        }
    }
    
    // Test manually versus a Java echo server us
    // % java -cp pot.jar potx.dev.echo.Server
    // Cleartext echo server started on port 2033.
    // Salt Channel echo server started on port 2034.
    func testClientSocketEcho() {
        for _ in 1...30 {
            do {
                let socket = try ClientSocket(hostname, plainport).start()
                let reply = try socket.echo(data: echo)
                XCTAssertEqual(echo, reply)
                socket.stop()
            } catch {
                XCTFail("Can not open socket: \(error)")
                return
            }
        }
    }
    
    func receiver(data: Data) {
        reply = data
        print(data.hex)
    }
    
    func errorhandler(error: Error) {
        print(error)
        XCTFail("Got error: " + error.localizedDescription)
    }
    
    func testSocketSaltByteChannel() {
        let clientKeys = SaltTestData.keysA
        let clientSignSec = Data(clientKeys.signSec)
        let clientSignPub = Data(clientKeys.signPub)
        let clientEncSec  = Data(clientKeys.diffiSec)
        let clientEncPub  = Data(clientKeys.diffiPub)
        
        let hostKeys = SaltTestData.keysB
        let serverSignPub = Data(hostKeys.signPub)

        guard let socketChannel = try? SocketChannel(hostname, saltport) else {
            XCTFail("Failed to create SocketChannel")
            return
        }
        
        let channel = SaltChannel(channel: socketChannel, sec: clientSignSec, pub: clientSignPub)
        do {
            channel.register(callback: receiver, errorhandler: errorhandler)
        
            let protocols = try channel.negotiate(pubKey: serverSignPub)
            XCTAssertEqual(protocols.count, 1)
            
            try channel.handshake(clientEncSec: clientEncSec,
                                  clientEncPub: clientEncPub,
                                  serverSignPub: serverSignPub)
            
            let hostKeySignPub = try channel.getRemoteSignPub()
            XCTAssertEqual(hostKeySignPub, serverSignPub)
        } catch {
            XCTFail("Failed to create SaltChannel")
            return
        }
        
        do {
            let plain = Data([0x01, 0x05, 0x05, 0x05, 0x05, 0x05])
            try channel.write([plain])
        
            // Wait until mock is done
            if WaitUntil.waitUntil(4, reply != nil) {
                print("Echo is done")
                XCTAssertEqual(reply, plain)
            }
        } catch {
            XCTFail("Failed to write to SaltChannel")
            return
        }
    }
}
