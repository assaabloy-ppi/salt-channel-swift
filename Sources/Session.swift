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
    var lastMessageReceived = false

    init(key: Data, timeKeeper: TimeKeeper) {
        self.timeKeeper = timeKeeper
        self.key = key
    }
}

public protocol TimeKeeper {
    mutating func time() -> TimeInterval
}

public struct NullTimeKeeper: TimeKeeper {
    public func time() -> TimeInterval { return 0 }
}

public class CounterTimeKeeper: TimeKeeper {
    var counter: TimeInterval = 0
    public func time() -> TimeInterval {
        counter += 1
        return counter
    }
}

public struct RealTimeKeeper: TimeKeeper {
    let starttime: Date = Date()
    public func time() -> TimeInterval {
        return Date().timeIntervalSince(starttime)
    }
}
