//  EchoMock.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-06.

import XCTest
import CocoaLumberjack

@testable import SaltChannel

class EchoMock : ByteChannel, MockRunner {
    var dataStore: [Data] = []
    var didReceiveMessage: Bool = false
    var callback: ((Data) -> (), (Error) -> ())? = nil

    let m1, m2, m3, m4, d1, d2: Data
    
    public init(mockdata: SaltTestData) {
        m1 = mockdata.get(.m1)
        m2 = mockdata.get(.m2)
        m3 = mockdata.get(.m3)
        m4 = mockdata.get(.m4)
        d1 = mockdata.get(.msg1)
        d2 = mockdata.get(.msg1)
    }
    
    //-- MockRunner
    func start() {
        DispatchQueue.global().async { self.handShake() }
    }
    
    //-- ByteChannel
    func write(_ data: [Data]) throws {
        print("EchoMock write is called")
        dataStore = data
        didReceiveMessage = true
    }
    
    func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ()) {
        print("EchoMock register is called")
        self.callback = (callback, errorhandler)
    }
    
    //-- Internal
    func handShake() {
        
        didReceiveMessage = false
    }
    
    //-- Exchange
    func exchange() {
        
        didReceiveMessage = false
    }
}
