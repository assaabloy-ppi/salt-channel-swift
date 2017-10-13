//  WaitUntil.swift
//
//  Copyright © 2017 Assa Abloy. All rights reserved.

import Foundation

public class WaitUntil {
    private var didHappend: Bool = false
    
    public func reportHappend() {
        self.didHappend = true
    }
    
    public func hasHappend() -> Bool {
        return self.didHappend
    }
    
    public func waitFor() -> Bool {
        return WaitUntil.waitUntil(self.hasHappend())
    }
    
    public func waitFor(_ timeout: Double) -> Bool {
        return WaitUntil.waitUntil(timeout, self.hasHappend())
    }
    
    // Utility function to wait for any kind of event using a closure,
    // default timeout 4 seconds
    public static func waitUntil(_ checkSuccess: @autoclosure () -> Bool) -> Bool {
        return waitUntil(4.0, checkSuccess)
    }
    
    // Utility function to wait for any kind of event using a closure,
    // with provided timeout
    public static func waitUntil(_ timeout: Double, _ checkSuccess: @autoclosure () -> Bool) -> Bool {
        let startDate = Date()
        var success = false
        while !success && abs(startDate.timeIntervalSinceNow) < timeout {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
            success = checkSuccess()
        }
        return success
    }
}
