//  Channel.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

public protocol ByteChannel {
    func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ())
    func write(_ data: [Data]) throws
}
