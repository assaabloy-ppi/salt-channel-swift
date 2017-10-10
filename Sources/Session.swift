//
//  Session.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-09.
//

import Foundation

public class Session {
    private var timeKeeper: TimeKeeper
    
    var time: TimeInterval { return timeKeeper.time() }
    
    var key: Data
    var handshakeDone = false
    
    init(key: Data, timeKeeper: TimeKeeper) {
        self.timeKeeper = timeKeeper
        self.key = key
    }
}

/// `TimeKeeper` is a protocol that is intended only for value types.
public protocol TimeKeeper {
    mutating func time() -> TimeInterval
}

public struct NullTimeKeeper: TimeKeeper {
    public func time() -> TimeInterval {
        return 0
    }
}

public struct CounterTimeKeeper: TimeKeeper {
    var counter: TimeInterval = 0
    public mutating func time() -> TimeInterval {
        counter = counter + 1
        return counter
    }
}

public struct RealTimeKeeper: TimeKeeper {
    public func time() -> TimeInterval {
        return Date().timeIntervalSince(starttime)
    }
    
    let starttime: Date = Date()
}
