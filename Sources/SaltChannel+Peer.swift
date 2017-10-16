//  SaltChannel+Peer.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-16.

import Foundation
import os.log

extension SaltChannel: Peer {
    /**
     */
    func writeApp(time: TimeInterval, message: Data) -> Data {
        let header = createHeader(from: PacketType.app)
        return header + packBytes(UInt64(time), parts: 4) + message
    }
    
    /**
     */
    public func readApp(data: Data) throws -> (time: TimeInterval, message: Data) {
        let header = data[..<2]
        let (type, _, _) = readHeader(from: header)
        guard  type == PacketType.app else {
            throw ChannelError.badMessageType(reason: "Expected App message header")
        }
        
        // TODO: better unpack for Time
        let (time, _) = unpackInteger(data.subdata(in: 2 ..< 6), count: 4)
        let message = data.subdata(in: 6 ..< data.endIndex)
        return (Double(time), message)
    }
    
    /**
     ##MultiApp## is multiple messages batched together in the application layer protocol
     */
    func writeMultiApp(message: Data) throws -> (time: TimeInterval, message: Data) {
        let header = createHeader(from: PacketType.multi)
        let time = self.session!.time
        let message = header + packBytes(UInt64(time), parts: 4)
        return (time, message)
    }
    
    func readMultiApp(data: Data) throws -> [String] {
        // TODO
        return []
    }
}
