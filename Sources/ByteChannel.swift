//  Channel.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

/**
 **ByteChannel** is protocol implemented at many levels for SaltChannel
 and lower levels. The main idea is that writes happens and returns, only
 client side errors will be returned as part of the Exception. Registered
 handlers for callbacks and errors will manage anything happening in the
 channel that the user need to act on.
 
 ### Usage Example for register(): ###
 ````
 channel.register(
     callback:
     { data in
         DDLogInfo("Received Callback R2 for R1")
         XCTAssertEqual(data, r2)
     },
     errorhandler:
     { error in
         DDLogError("Received error instead of R2 for R1: /(error)")
         XCTAssert(false)
     })
 ´´´´
 */
public protocol ByteChannel {
    /// Register a Callback and and Errorhandler
    func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ())
    
    /// Write data to the Channel
    func write(_ data: [Data]) throws
}
