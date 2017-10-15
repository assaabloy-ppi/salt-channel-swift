//  BasicHostMock.swift
//  SaltChannel-Tests
//
//  Created by Håkan Olsson on 2017-10-05.

import XCTest

@testable import SaltChannel

class BasicHostMock : ByteChannel, MockRunner {
    var callbacks: [(Data) -> ()] = []
    var writeData: [Data] = []
    let mockdata: TestDataSet
    
    public init(mockdata: TestDataSet) {
        self.mockdata = mockdata
    }
    
    public func start() {
        DispatchQueue.global().async { self.handshake() }
    }
    
    func handshake() {
        if let handshakeData = mockdata.handshake{
            waitForData(handshakeData.m1)
            send(handshakeData.m2)
            send(handshakeData.m3)
            waitForData(handshakeData.m4)
        }
        for transfer in mockdata.transfers{
            if transfer.toHost{
                waitForData(transfer.cipher)
            }
            else {
                send(transfer.plain)
            }
        }
    }
    
    // ****** Helper functions *******
    
    func waitForData(_ data: [Byte]){
        if WaitUntil.waitUntil(10, self.writeData.isEmpty == false) {
            XCTAssertEqual(writeData.first, Data(data))
            writeData.remove(at: 0)
        }
    }
    
    func send(_ data: [Byte]){
        for callback in callbacks{
            print("Send data")
            callback(Data(data))
        }
    }
    
    // ****** Interface *******
    
    func write(_ data: [Data]) throws {
        print("Write is called in Mock")
        for item in data{
            writeData.append(item)
        }
    }
    
    func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ()) {
        print("Register is called in Mock")
        self.callbacks.append(callback)
    }
}
