//  ChannelError.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

public enum ChannelError: Error {
    case readTimeout
    case notImplemented
    case setupNotDone(reason: String)
    case badMessageType(reason: String)
    case signatureDidNotMatch
    case couldNotCreateSignature
    case couldNotDecrypt
    case couldNotCalculateKey
    case errorInMessage(reason: String)
    case handshakeAlreadyDone
    case invalidHandshakeSequence
}
