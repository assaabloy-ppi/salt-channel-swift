//  SaltChannel.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-05-31.

import Foundation
import Sodium
import os.log

internal struct HandshakeData {
    var serverEncPub: Data?
    var m1Hash: Data?
    var m2Hash: Data?
    var clientEncSec: Data?
    var clientEncPub: Data?

    var negotiateCompleted: (([(first: String, second: String)]) -> Void)?
    var handshakeCompleted: (() -> Void)?
}

public enum HandshakeState {
    case notStarted
    case expectM2
    case expectM3
    case expectA2
    case done
}

/**
 **SaltChannel** is a ByteChannel with encryption and authorization.
 */
public class SaltChannel: ByteChannel {
    
    let log = OSLog(subsystem: "salt.aa.st", category: "Channel")
    var timeKeeper: TimeKeeper

    var callbacks: [(Data) -> Void] = []
    var errorHandlers: [(Error) -> Void] = []

    let channel: ByteChannel
    let clientSignSec: Data
    let clientSignPub: Data
    var remoteSignPub: Data?

    let sodium = Sodium()
    var session: Session?

    var sendNonce = Nonce(value: 1)
    var receiveNonce = Nonce(value: 2)
    
    var handshakeData = HandshakeData()
    public var handshakeState: HandshakeState

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
        self.handshakeState = .notStarted
        
        self.channel.register(callback: handleRead, errorhandler: handleError)
        
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
        try self.channel.write([cipherMessage])
    }
    
    public func register(callback: @escaping (Data) -> Void, errorhandler: @escaping (Error) -> Void) {
        self.errorHandlers.append(errorhandler)
        self.callbacks.append(callback)
    }
    
    // --- Callbacks -------
    
    private func handleError(_ error: Error) {
        os_log("Ended up in SaltChannel ErrorHandler: %{public}s", log: log, type: .error, error as CVarArg)

        for errorHandler in errorHandlers {
            errorHandler(error)
        }
    }
    
    private func handleRead(_ data: Data) {
        do {
            switch self.handshakeState {

            case .notStarted:
                throw ChannelError.setupNotDone(reason: "Handshake not done yet!")
            case .expectM2:
                try receiveM2(m2Raw: data)
            case .expectM3:
                try receiveM3sendM4(m3Raw: data)
            case .expectA2:
                try receiveA2(a2Raw: data)
            case .done:
                guard let session = self.session else {
                    throw ChannelError.setupNotDone(reason: "Expected a Session by now")
                }

                let raw = try decryptMessage(message: data, session: session)
                let (_, messages) = try unpackApp(raw)

                for callback in callbacks {
                    for message in messages {
                        callback(message)
                    }
                }
            }
        } catch {
            handleError(error)
        }
    }
}
