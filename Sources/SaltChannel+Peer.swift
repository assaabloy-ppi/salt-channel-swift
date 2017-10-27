//  SaltChannel+Peer.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-16.

import Foundation
import os.log

extension SaltChannel: Peer {
    
    func unpackApp(_ data: Data) throws -> (time: TimeInterval, message: [Data]) {
        let header = data[..<2]
        let time = TimeInterval(unpackInteger(data, count: 4).value)
        let (type, _, _) = readHeader(from: header)
        let body = data.subdata(in: 6 ..< data.endIndex)
        if type == PacketType.app {
            return (time: time, message: [body])
        } else if type == PacketType.multi {
            return (time: time, message: readMultiApp(body))
        } else {
            throw ChannelError.badMessageType(reason: "Expected App message header")
        }
    }
    
    /**
     */
    func writeApp(time: TimeInterval, message: Data) -> Data {
        let header = createHeader(from: PacketType.app)
        return header + packBytes(UInt64(time), parts: 4) + message
    }
    
    /**
     */
    public func readApp(_ data: Data) -> Data {
        return data.subdata(in: 6 ..< data.endIndex)
    }
    
    /**
     ##MultiApp## is multiple messages batched together in the application layer protocol
     */
    func writeMultiApp(time: TimeInterval, messages: [Data]) -> Data {
        let header = createHeader(from: PacketType.multi)
        let time = packBytes(UInt64(timeKeeper.time()), parts: 4)
        let msgCount = packBytes(UInt64(messages.count), parts: 2)
        var appMessage = header + time + msgCount
        for message in messages {
            appMessage += packBytes(UInt64(message.count), parts: 2) + message
        }
        return appMessage
    }
    
    func readMultiApp(_ data: Data) -> [Data] {
        var (count, remainder) = unpackInteger(data, count: 2)
        var size: UInt64 = 0
        var messages: [Data] = []
        for _ in 1...count {
            (size, remainder) = unpackInteger(remainder, count: 2)
            messages.append(remainder.subdata(in: 0 ..< Int(size)))
            remainder = remainder.subdata(in: Int(size) ..< remainder.endIndex )
        }
        return messages
    }
}
