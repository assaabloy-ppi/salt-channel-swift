//  BasicHostMock.swift
//  SaltChannel-Tests
//
//  Created by Håkan Olsson on 2017-10-05.

import XCTest
@testable import SaltChannel

class BasicHostMock: ByteChannel {
    var callbacks: [(Data) -> Void] = []
    var writeData: [Data] = []
    var isDone: Bool = false
    let mockdata: TestDataSet
    
    public init(mockdata: TestDataSet) {
        self.mockdata = mockdata
    }
    
    public func start() {
        DispatchQueue.global().async { self.run() }
    }
    
    func run() {
        if let aData = mockdata.abox {
            print("Test A")
            waitForData(aData.a1)
            send(aData.a2)
        }
        
        if let handshakeData = mockdata.handshake {
            print("Test handshake")
            waitForData(handshakeData.m1)
            send(handshakeData.m2)
            send(handshakeData.m3)
            waitForData(handshakeData.m4)
        }
        
        print("Test \(mockdata.transfers.count) transfers")
        for transfer in mockdata.transfers {
            if transfer.toHost {
                waitForData(transfer.cipher)
            } else {
                send(transfer.cipher)
            }
        }
        
        isDone = true
    }
    
    // ****** Helper functions *******
    
    func waitForData(_ data: [Byte]) {
        if WaitUntil.waitUntil(2, self.writeData.isEmpty == false) {
            XCTAssertEqual(writeData.first, Data(data))
            writeData.remove(at: 0)
        } else {
            XCTAssert(false, "Did not receive data")
        }
    }
    
    func send(_ data: [Byte]) {
        for callback in callbacks {
            print("Send data")
            callback(Data(data))
        }
    }
    
    // ****** Interface *******
    
    func write(_ data: [Data]) throws {
        print("Write is called in Mock")
        for item in data {
            writeData.append(item)
        }
    }
    
    func register(callback: @escaping (Data) -> Void, errorhandler: @escaping (Error) -> Void) {
        print("Register is called in Mock")
        self.callbacks.append(callback)
    }
}
