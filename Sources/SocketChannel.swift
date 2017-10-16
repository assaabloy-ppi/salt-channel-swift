//
//  SocketChannel.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-12.

import Foundation
import os.log

public class SocketChannel: ByteChannel {
    let log = OSLog(subsystem: "salt.aa.st", category: "Socket")

    var streams: (is: InputStream, os: OutputStream)?
    var ping = Data("Hello".utf8)
    
    public let host: String
    public let port: UInt32
    
    public convenience init() {
        self.init(host: "127.0.0.1", port: 8080)
    }
    
    public init(host: String, port: UInt32) {
        self.host = host
        self.port = port
        os_log("Setting up Socket ByteChannel for server %s:%d", log: log, host, port)
    }
    
    /// Register a Callback and and Errorhandler
    public func register(callback: @escaping (Data) -> Void, errorhandler: @escaping (Error) -> Void) {
        
    }
    
    /// Write data to the Channel
    public func write(_ data: [Data]) throws {
        
    }
}
