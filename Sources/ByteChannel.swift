//  ByteChannel.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

public class ByteChannel: Channel {
    weak var delegate: ChannelDelegate?
    
    func register(delegate: ChannelDelegate) {
        self.delegate = delegate
    }
    
    func write(_ data: [Data]) throws {
        throw ChannelError.notImplemented
    }
    
    func read() throws -> Data {
        throw ChannelError.notImplemented
    }
}
