//  SaltChannel.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-05-31.

import Foundation
import Sodium
import Binson
import CocoaLumberjack

/**
 **SaltChannel** is a ByteChannel with encryption and authorization.
 */
public class SaltChannel: ByteChannel {
    var callback: [(Data) -> ()] = []
    var errorhandler: [(Error) -> ()] = []

    let channel: ByteChannel!
    let clientSignSec: Data!
    let clientSignPub: Data!
    var remoteSignPub: Data?

    let sodium = Sodium()
    var session: Session?

    var sendNonce = Nonce(startValue: 1)
    var receiveNonce = Nonce(startValue: 2)
    
    var bufferedM4: Data?
    var didReceiveMsg = false
    var lastMessage: Data?
    var handshakeDone = false
    
    /// Create a SaltChannel with channel to wrap plus the clients signing
    /// keypair.
    public init (channel: ByteChannel, sec: Data, pub: Data) {
        self.channel = channel
        self.clientSignSec = sec
        self.clientSignPub = pub
    }
    
    // Mark: Channel
    public func write(_ data: [Data]) throws {
        guard let session = self.session else {
            throw ChannelError.setupNotDone
        }
        
        var packages: [Data] = []
        
        if let m4 = self.bufferedM4 {
            packages.append(m4)
            self.bufferedM4 = nil
        }
        
        // Create an array of encrypted packages
        for package in data {
            let msg = a1(time: session.time, message: package)
            packages.append(encryptMessage(session: session, message: msg))
        }
        
        try self.channel.write(packages)
    }
    
    public func register(callback: @escaping (Data) -> (), errorhandler: @escaping (Error) -> ()) {
        self.errorhandler.append(errorhandler)
        self.callback.append(callback)
    }
    
    // --- Callbacks -------
    
    func error(_ error: Error) {
        DDLogError("Got error: /(error)")
    }
    
    func read(_ data: Data) {
        if !self.handshakeDone {
            gotHandshakeMessage(message: data)
            return
        }
        else {
            if let session = self.session,
                let raw = try? receiveAndDecryptMessage(message: data, session: session),
                let (_, message) = try? a2(data: raw) {
                self.callback.first!(message)
            } else {
                self.errorhandler.first!(ChannelError.setupNotDone)
            }
        }
    }
}
