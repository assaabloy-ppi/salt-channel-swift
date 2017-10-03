//  ChannelError.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-02.

import Foundation

public enum ChannelError: Error {
    case readTimeout
    case notImplemented
    case setupNotDone
    case gotWrongMessage
    case signatureDidNotMatch
    case couldNotCreateSignature
    case couldNotDecrypt
    case couldNotCalculateSessionKey
    case errorInMessage
}
