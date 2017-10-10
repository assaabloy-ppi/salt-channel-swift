//  BasicHostMock.swift
//  SaltChannel-Tests
//
//  Created by Håkan Olsson on 2017-10-05.

import XCTest

@testable import SaltChannel

class BasicHostMock : ByteChannel, MockRunner {
    var callbacks: [(Data) -> ()] = []
    var writeData: [Data] = []
    let mockdata: SaltTestData
    
    public init(mockdata: SaltTestData) {
        self.mockdata = mockdata
    }
    
    public func start() {
        DispatchQueue.global().async { self.handshake() }
    }
    
    func handshake() {
        waitForData(mockdata.get(.m1))
        send(mockdata.get(.m2))
        send(mockdata.get(.m3))
        waitForData(mockdata.get(.m4))
        waitForData(mockdata.get(.msg1))
        send(mockdata.get(.msg2))
    }
    
    // ****** Helper functions *******
    
    func waitForData(_ data: Data){
        if WaitUntil.waitUntil(10, self.writeData.isEmpty == false) {
            XCTAssertEqual(writeData.first, data)
            writeData.remove(at: 0)
        }
    }
    
    func send(_ data: Data){
        sleep(1)
        for callback in callbacks{
            print("Send data")
            callback(data)
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
