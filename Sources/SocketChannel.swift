//  SocketChannel.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-12.

import Foundation

public enum SocketError: Error {
    case failedToWrite(String)
    case failedToConnect(String)
    case noReply(String)
}

public struct SocketStatus {
    let input: Stream.Status
    let output: Stream.Status
}

public enum Mode {
    case sync, async
}

protocol SocketDelegate: class {
    func handle(error: Error)
    func handle(data: Data)
}

public class SocketChannel: ByteChannel, SocketDelegate {
    let socket: ClientSocket
    var callbacks: [(Data) -> Void] = []
    var errorHandlers: [(Error) -> Void] = []

    public init(_ host: String, _ port: Int) throws {
        socket = try ClientSocket(host, port).start()
        socket.delegate = self
    }
    
    public func register(callback: @escaping (Data) -> Void, errorhandler: @escaping (Error) -> Void) {
        callbacks.append(callback)
        errorHandlers.append(errorhandler)
    }
    
    public func write(_ data: [Data]) throws {
        try socket.write(data)
    }
    
    public func handle(data: Data) {
        for callback in callbacks {
            callback(data)
        }
    }
    
    public func handle(error: Error) {
        for errorHandler in errorHandlers {
            errorHandler(error)
        }
    }
}

// Set up an input stream and an output stream for the communication socket
extension Stream {
    static func streams(to host: String, port: Int) throws -> (in: InputStream, out: OutputStream) {
        var istream: InputStream?
        var ostream: OutputStream?
        
        Stream.getStreamsToHost(withName: host, port: port, inputStream: &istream, outputStream: &ostream)
        
        guard let ins = istream, let outs = ostream else { throw SocketError.failedToConnect("Streams are nil") }
        
        if case ins.streamStatus = Stream.Status.error {
            throw SocketError.failedToConnect("Input stream has errors")
        }
        
        if case outs.streamStatus = Stream.Status.error {
            throw SocketError.failedToConnect("Output stream has errors")
        }
        
        return (in: ins, out: outs)
    }
}

// A Helper class to represent the clienty socket that is also StreamDelegate
// in order to react to callbacks (see func stream(Stream, handle: Stream.Event))
class ClientSocket: NSObject, StreamDelegate {
    let streams: (in: InputStream, out: OutputStream)
    
    let host: String
    let port: Int
    
    var mode = Mode.sync
    weak var delegate: SocketDelegate?
    
    init(_ host: String, _ port: Int, mode: Mode = .sync) throws {
        self.host = host
        self.port = port
        streams = try Stream.streams(to: host, port: port)

        super.init()
        if case mode = Mode.async { _ = self.async() }
    }
    
    func async() -> ClientSocket {
        mode = Mode.async
        
        // Instead of Polling the RunLoop call stream(_, handle)
        // No need to register the output
        streams.in.schedule(in: .current, forMode: .defaultRunLoopMode)
        streams.out.schedule(in: .current, forMode: .defaultRunLoopMode)
        
        streams.in.delegate = self
        streams.out.delegate = self
        
        return self
    }
    
    func start() -> ClientSocket {
        streams.out.open()
        streams.in.open()
        return self
    }
    
    func stop() {
        if case mode = Mode.async {
            streams.in.remove(from: .current, forMode: .defaultRunLoopMode)
            streams.out.remove(from: .current, forMode: .defaultRunLoopMode)

            streams.in.delegate = nil
            streams.out.delegate = nil
        }
        
        streams.in.close()
        streams.out.close()
    }
    
    func status() -> SocketStatus {
        return SocketStatus(input: streams.in.streamStatus, output: streams.out.streamStatus)
    }

    func echo(data: Data) throws -> Data {
        guard case mode = Mode.sync else {
            throw SocketError.failedToConnect("Async should not be set for sync Echo")
        }
        
        try write([data])
        return try read()
    }

    func ping(_ string: String) throws -> (TimeInterval, String) {
        guard case mode = Mode.sync else {
            throw SocketError.failedToConnect("Async should not be set for sync Ping")
        }
        
        let start = Date()
        
        try write([Data(string.utf8)])
        let data = try read()
        
        return (Date().timeIntervalSince(start),
                String(data: data, encoding: .utf8) ?? "Pong")
    }
    
    func read() throws -> Data {
        var total = 0
        
        var buffer = [Byte](repeating: 0, count: 1048576)
        var data = Data(bytes: buffer)
        
        while streams.in.hasBytesAvailable {
            let n = streams.in.read(&buffer, maxLength: 1024)
            total += n
            data.append(buffer, count: total)
        }
        
        guard total > 0 else { throw SocketError.noReply("Could not read bytes") }
        
        return Data(bytes: buffer[...(total-1)])
    }
    
    func write(_ data: [Data]) throws {
        for entry in data {
            let count = entry.count
            
            // Funny way to create an output buffer to write to
            let length = entry.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) -> Int in
                return streams.out.write(buffer, maxLength: count)
            }
            
            switch length {
            case ..<0:
                throw SocketError.failedToWrite("Stream write: error!")
            case 0..<count:
                throw SocketError.failedToWrite("Stream write: could not write all bytes (\(length) / \(count))")
            default:
                return
            }
        }
    }
    
    func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        guard stream == streams.in || stream == streams.out else {
            print("Unknown stream for us")
            return
        }
        
        print("HHHHHHHHHHHHHHHHHHH")
        let name: String = stream.description
        
        switch eventCode {
        case .openCompleted:
            print("\(name): stream opened")
        case .hasSpaceAvailable:
            print("\(name): stream has space available")
            delegate?.handle(data: Data())
        case .errorOccurred:
            let error = streams.in.streamError! as NSError
            print("\(name): Socket stream error %@ / %d", error.domain, error.code)

            delegate?.handle(error: error)
            stop()
        default:
            return
        }
    }
}

extension SocketStatus: CustomStringConvertible {
    public var description: String {
        let intext = { () -> String in
            switch self.input {
            case .atEnd:
                return "At end of the input stream. No more data can be written."
            case .closed:
                return "The input stream is closed."
            case .error:
                return "The remote end of the connection can’t be contacted, or the connection has been severed."
            case .notOpen:
                return "The input stream is not open for writing."
            case .open:
                return "The input stream is open, but no writing is occurring."
            case .opening:
                return "The input stream is in the process of being opened for writing. This status might include the time after the stream was opened, but while network DNS resolution is happening."
            case .reading:
                return "Data is being read from the stream. This status would be returned if code on another thread were to call streamStatus on the stream while another is reading."
            case .writing:
                return "Data is being written to the stream. This status would be returned if code on another thread were to call streamStatus on the stream while"
            }
        }()
        
        let outtext = { () -> String in
            switch self.output {
            case .atEnd:
                return "At end of the output stream. No more data can be read."
            case .closed:
                return "The output stream is closed."
            case .error:
                return "The remote end of the connection can’t be contacted, or the connection has been severed."
            case .notOpen:
                return "The output stream is not open for reading."
            case .open:
                return "The output stream is open, but no reading is occurring."
            case .opening:
                return "The output stream is in the process of being opened for reading. This status might include the time after the stream was opened, but while network DNS resolution is happening."
            case .reading:
                return "Data is being read from the stream. This status would be returned if code on another thread were to call streamStatus on the stream while another is reading."
            case .writing:
                return "Data is being written to the stream. This status would be returned if code on another thread were to call streamStatus on the stream while"
            }
        }()
        
        return intext + "\n" + outtext
    }
}
