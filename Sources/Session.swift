//
//  Session.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-09.
//

import Foundation

public struct Session {
    private let starttime: Date
    //var time: TimeInterval { return Date().timeIntervalSince(starttime) }
    var time: TimeInterval = 0
    
    var key: Data
    var handshakeDone = false
    
    init(key: Data) {
        starttime = Date()
        self.key = key
    }
}
