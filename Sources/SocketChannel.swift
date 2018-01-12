//
//  SocketChannel.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-12.

import Foundation

public class SocketChannel: ByteChannel {
    let socket: ClientSocket
    
    public init(_ host: String, _ port: Int) {
        socket = ClientSocket(host, port)
        socket.start()
    }
    
    public func register(callback: @escaping (Data) -> Void, errorhandler: @escaping (Error) -> Void) {
        
    }
    
    public func write(_ data: [Data]) throws {
        try socket.write(data)
    }
}

public enum SocketError: Error {
    case failedConnection
    case noReply
}

extension Stream {
    static func streamsToHost(name hostname: String, port: Int) -> (in: InputStream, out: OutputStream) {
        var inStream: InputStream? = nil
        var outStream: OutputStream? = nil
        Stream.getStreamsToHost(withName: hostname, port: port, inputStream: &inStream, outputStream: &outStream)
        return (in: inStream!, out: outStream!)
    }
}

public class ClientSocket: NSObject, StreamDelegate {
    let streams: (in: InputStream, out: OutputStream)
    
    let host: String
    let port: Int
    
    public init(_ host: String, _ port: Int) {
        self.host = host
        self.port = port
        streams = Stream.streamsToHost(name: host, port: port)
    }
    
    func start() {
        streams.in.schedule(in: .current, forMode: .defaultRunLoopMode)
        streams.out.schedule(in: .current, forMode: .defaultRunLoopMode)

        streams.in.open()
        streams.out.open()
    }
    
    public func write(_ data: [Data]) throws {
        for entry in data {
            let count = entry.count
        
            let length = entry.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) -> Int in
                return streams.out.write(buffer, maxLength: count)
            }
        
            if length < 0 {
                print("Stream write: error!")
            } else if length < count {
                print("Stream write: could not write all bytes (\(length) / \(count))")
            } else {
                print("Stream write: \(entry.hex)")
            }
        }
    }
    
    func flush() {
        streams.in.close()
        streams.out.close()
        
        streams.in.open()
        streams.out.open()
    }
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
    }

    func echo(data: Data) throws -> Data {
        try? write([data])
        // sleep(1)
        
        var buffer = [UInt8](repeating: 0, count: 128)
        let n = streams.in.read(&buffer, maxLength: buffer.count)
        guard n > 0 else { throw SocketError.noReply }
        
        return Data(buffer[...(n-1)])
    }

    func ping(data: Data) throws -> TimeInterval {
        let start = Date()
        try? write([data])
        
        // sleep(1)
        
        var buffer = [UInt8](repeating: 0, count: 128)
        let bytesRead = streams.in.read(&buffer, maxLength: buffer.count)
        guard bytesRead > 0 else { throw SocketError.noReply }
        
        return Date().timeIntervalSince(start)
    }
    
    func stop() {
        streams.in.close()
        streams.out.close()
    }
}
