//  Session.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-09.

import Foundation

public class Session {
    var key: Data
    var lastMessageReceived = false

    init(key: Data) {
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
    let timeArray: [TimeInterval]
    var counter: Int = 0
    init(timeArray: [TimeInterval]) {
        self.timeArray = timeArray
    }
    public func time() -> TimeInterval {
        let time = timeArray[counter]
        counter += 1
        return time
    }
}

public struct RealTimeKeeper: TimeKeeper {
    let starttime: Date = Date()
    public func time() -> TimeInterval {
        return Date().timeIntervalSince(starttime)
    }
}
