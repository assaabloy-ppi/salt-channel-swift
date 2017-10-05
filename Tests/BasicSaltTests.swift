//  BasicSaltTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-03.

import XCTest
import Sodium
import Binson
import CocoaLumberjack

@testable import SaltChannel

let testdata = [
    "clientsec": "55f4d1d198093c84de9ee9a6299e0f6891c2e1d0b369efb592a9e3f169fb0f795529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b",
    "clientpub": "5529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b"]

class MyChannel : ByteChannel {
    var callback: [(Data) -> ()] = []
    var errors: [(Error) -> ()] = []
    
    var sink = [Data]()
    
    public init() {
        
    }
    
    func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ()) {
        self.callback.append(callback)
        self.errors.append(errorhandler)
    }
    
    func write(_ data: [Data]) throws {
        sink.append(contentsOf: data)
    }
}

class BasicSaltTests: XCTestCase {
    let sodium = Sodium()
    
    override func setUp() {
        super.setUp()
        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        DDTTYLogger.sharedInstance.colorsEnabled = true
    }

    func testExample() {
        _ = MyChannel()
        // _ = SaltChannel(channel: bytechannel, sec: signSec, pub: signPub)

    }
}
