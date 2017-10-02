//  Channel.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

protocol ChannelDelegate: class {
    func didReceiveMessage()
}

protocol Channel {
    func register(delegate: ChannelDelegate)
    func write(_ data: [Data]) throws
    func read() throws -> Data
}
