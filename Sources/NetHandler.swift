//
//  NetHandler.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2018-01-14.

import Foundation

class NetHandler {
    let host: String
    let port: Int
    
    init(_ host: String, _ port: Int) {
        self.host = host
        self.port = port
    }
    
    // ncat -k -l -p 4444
    func sendText(_ str: String) {
        var inputStream: InputStream?
        var outputStream: OutputStream?
        
        Stream.getStreamsToHost(withName: host, port: port,
                                inputStream: &inputStream, outputStream: &outputStream)
        
        guard let outs = outputStream else { return }
        var text = [UInt8]((str + "\n").utf8)
        
        outs.open()
        outs.write(&text, maxLength: text.count)
        outs.close()
    }
    
    // ncat -k -l -p 4444
    // and type reply
    func sendAndReceiveText(_ str: String) -> String? {
        var inputStream: InputStream?
        var outputStream: OutputStream?
        
        Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        
        guard let ins = inputStream, let outs = outputStream else { return nil }
        var text = [UInt8]((str + "\r\n").utf8)
        
        outs.open()
        outs.write(&text, maxLength: text.count)
        outs.close()
        
        ins.open()
        
        var buffer = [UInt8](repeating: 0, count: 1048576)
        var n = ins.read(&buffer, maxLength: 1024)
        var data = Data(bytes: buffer)
        
        while ins.hasBytesAvailable {
            let read = ins.read(&buffer, maxLength: 1024)
            n += read
            data.append(buffer, count: read)
        }
        
        ins.close()
        
        let bytes = Data(bytes: buffer[...(n-1)])
        return String(data: bytes, encoding: .utf8) ?? "I know nothing"
    }
}
