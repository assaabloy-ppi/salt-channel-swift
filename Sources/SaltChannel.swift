//  SaltChannel.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-05-31.

import Foundation
import Sodium
import Binson

public class SaltChannel: ByteChannel, ChannelDelegate {
    let channel: Channel!
    let clientSignSec: Data!
    let clientSignPub: Data!
    let sodium: Sodium!
    var sendNonce = Nonce(startValue: 1)
    var receiveNonce = Nonce(startValue: 2)
    var sessionKey: Data?
    var remoteSignPub: Data?
    var bufferedM4: Data?
    var waitUntil = WaitUntil()
    var didReceiveMsg = false
    
    init (channel: Channel, clientSignSec: Data, clientSignPub: Data) {
        self.channel = channel
        self.clientSignSec = clientSignSec
        self.clientSignPub = clientSignPub
        self.sodium = Sodium.init()
        super.init()
        self.channel.register(delegate: self)
    }
    
    // Mark: ChannelDelegate
    func didReceiveMessage() {
        self.delegate?.didReceiveMessage()
        self.didReceiveMsg = true
    }
    
    // Mark: Channel
    public override func write(_ data: [Data]) throws {
        guard let key = self.sessionKey else {
            throw ChannelError.setupNotDone
        }
        
        var packages: [Data] = []
        
        if let m4 = self.bufferedM4 {
            packages.append(m4)
            self.bufferedM4 = nil
        }
        
        // Create an array of encrypted packages
        for package in data {
            let appPackage = packAppPacket(time: 0, message: package)
            packages.append(encryptMessage(sessionKey: key, message: appPackage))
        }
        
        try self.channel.write(packages)
    }
    
    /// Read and decrypt message data using a session key
    ///
    /// - returns: A Data object with read bytes
    public override func read() throws -> Data {
        guard let key = self.sessionKey else {
            throw ChannelError.setupNotDone
        }
        
        let data = try receiveAndDecryptMessage(sessionKey: key)
        let (_, message) = try unpackAppPacket(data: data)
        return message
    }
}
