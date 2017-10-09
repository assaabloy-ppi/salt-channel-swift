//  BasicHostMock.swift
//  SaltChannel-Tests
//
//  Created by Håkan Ohlsson on 2017-10-05.

import XCTest

@testable import SaltChannel

class BasicHostMock : ByteChannel, MockRunner {
    var callback: [(Data) -> ()] = []
    var didReceiveMsg = false
    var readData: Data = Data()
    var writeData: [Data] = []
    
    let m1, m2, m3, m4, d1, d2: Data
    
    public init(mockdata: SaltTestData) {
        m1 = mockdata.get(.m1)
        m2 = mockdata.get(.m2)
        m3 = mockdata.get(.m3)
        m4 = mockdata.get(.m4)
        d1 = mockdata.get(.msg1)
        d2 = mockdata.get(.msg1)
    }
    
    public func start() {
        DispatchQueue.global().async { self.handShake() }
    }
    
    func handShake() {
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], m1)
            self.didReceiveMsg = false
        }
        sleep(4)
        callback.first!(m2)
        sleep(4)
        callback.first!(m3)
        
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], m4)
            self.didReceiveMsg = false
        }
        
        if WaitUntil.waitUntil(10, self.didReceiveMsg == true) {
            XCTAssertEqual(writeData[0], d1)
            self.didReceiveMsg = false
        }
        
        sleep(4)
        callback.first!(d2)
    }
    
    func write(_ data: [Data]) throws {
        print("Write is called in Mock")
        writeData = data
        didReceiveMsg = true
    }
    
    func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ()) {
        print("Register is called in Mock")
        self.callback.append(callback)
    }
}



