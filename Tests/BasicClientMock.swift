//
//  BasicClientMock.swift
//  SaltChannel-Tests
//
//  Created by Anders Tidbeck on 2020-04-24.
//

import XCTest
@testable import SaltChannel

class BasicClientMock: ByteChannel {
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
        /*
        if let aData = mockdata.abox {
            print("Test A")
            send(aData.a1)
            waitForData(aData.a2)
        }
        */
        
        if let handshakeData = mockdata.handshake {
            print("Test handshake")
            send(handshakeData.m1)
            waitForData(handshakeData.m2)
            waitForData(handshakeData.m3)
            send(handshakeData.m4)
        }
        
        print("Test \(mockdata.transfers.count) transfers")
        for transfer in mockdata.transfers {
            if transfer.direction == .toHost {
                send(transfer.cipher)
            } else {
                waitForData(transfer.cipher)
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
            XCTFail("Did not receive data")
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
        self.writeData.append(contentsOf: data)
    }
    
    func register(callback: @escaping (Data) -> Void, errorhandler: @escaping (Error) -> Void) {
        print("Register is called in Mock")
        self.callbacks.append(callback)
    }
}
