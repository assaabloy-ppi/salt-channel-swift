//  SaltChannel.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-05-31.

import Foundation
import Sodium
import os.log

/**
 **SaltChannel** is a ByteChannel with encryption and authorization.
 */
public class SaltChannel: ByteChannel {
    let log = OSLog(subsystem: "salt.aa.st", category: "Channel")
    var timeKeeper: TimeKeeper

    var callbacks: [(Data) -> Void] = []
    var errorHandlers: [(Error) -> Void] = []
    var receiveData: [Data] = []

    let channel: ByteChannel
    let clientSignSec: Data
    let clientSignPub: Data
    var remoteSignPub: Data?

    let sodium = Sodium()
    var session: Session?

    var sendNonce = Nonce(value: 1)
    var receiveNonce = Nonce(value: 2)
    
    var bufferedM4: Data?
    var handshakeDone = false
    
    public convenience init (channel: ByteChannel, sec: Data, pub: Data) {
        self.init(channel: channel, sec: sec, pub: pub, timeKeeper: RealTimeKeeper())
    }
    
    /// Create a SaltChannel with channel to wrap plus the clients signing
    /// keypair.
    public init (channel: ByteChannel, sec: Data, pub: Data, timeKeeper: TimeKeeper) {
        self.timeKeeper = timeKeeper
        self.channel = channel
        self.clientSignSec = sec
        self.clientSignPub = pub
        
        self.channel.register(callback: read, errorhandler: error)
        
        os_log("Created SaltChannel %{public}s", log: log, type: .debug, pub as CVarArg)
    }
    
    // MARK: Channel
    public func write(_ data: [Data]) throws {
        guard let session = self.session else {
            throw ChannelError.setupNotDone(reason: "Expected a Session by now")
        }
        
        var appMessage = Data()
        if data.count == 1 {
            appMessage = writeApp(time: timeKeeper.time(), message: data.first!)
        } else {
            appMessage = writeMultiApp(time: timeKeeper.time(), messages: data)
        }
        
        let cipherMessage = encryptMessage(session: session, message: appMessage)
        if let m4 = self.bufferedM4 {
            try self.channel.write([m4, cipherMessage])
        } else {
            try self.channel.write([cipherMessage])
        }
    }
    
    public func register(callback: @escaping (Data) -> Void, errorhandler: @escaping (Error) -> Void) {
        self.errorHandlers.append(errorhandler)
        self.callbacks.append(callback)
    }
    
    // --- Callbacks -------
    
    func error(_ error: Error) {
        os_log("Ended up in SaltChannel ErrorHandler: %{public}s", log: log, type: .error, error as CVarArg)

        for errorHandler in errorHandlers {
            errorHandler(error)
        }
    }
    
    func read(_ data: Data) {
        if !self.handshakeDone {
            receiveData.append(data)
        } else {
            if let session = self.session,
                let raw = try? decryptMessage(message: data, session: session),
                let (_, messages) = try? unpackApp(raw) {
                for callback in callbacks {
                    for message in messages {
                        callback(message)
                    }
                }
            } else {
                error(ChannelError.setupNotDone(reason: "Failed in read"))
            }
        }
    }
}
