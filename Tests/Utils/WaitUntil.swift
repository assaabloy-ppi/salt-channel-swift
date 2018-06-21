//  WaitUntil.swift
//
//  Copyright © 2017 Assa Abloy. All rights reserved.

import Foundation

class WaitUntil {
    private var didHappend: Bool = false
    
    func reportHappend() {
        self.didHappend = true
    }
    
    func hasHappend() -> Bool {
        return self.didHappend
    }
    
    func waitFor() -> Bool {
        return WaitUntil.waitUntil(self.hasHappend())
    }
    
    func waitFor(_ timeout: Double) -> Bool {
        return WaitUntil.waitUntil(timeout, self.hasHappend())
    }
    
    // Utility function to wait for any kind of event using a closure,
    // default timeout 4 seconds
    static func waitUntil(_ checkSuccess: @autoclosure () -> Bool) -> Bool {
        return waitUntil(4.0, checkSuccess)
    }
    
    // Utility function to wait for any kind of event using a closure,
    // with provided timeout
    static func waitUntil(_ timeout: Double, _ checkSuccess: @autoclosure () -> Bool) -> Bool {
        let startDate = Date()
        var success = false
        while !success && abs(startDate.timeIntervalSinceNow) < timeout {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
            success = checkSuccess()
        }
        return success
    }
}
