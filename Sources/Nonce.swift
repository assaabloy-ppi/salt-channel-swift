//  Nonce.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-06-08.

import Foundation
import Sodium

enum NonceConstants {
    static let bytesInUInt64 = 8
    static let bytesInNonce = 24
    static let bytesDiff = bytesInNonce - bytesInUInt64
    static let step = UInt64(2)
}

public class Nonce {
    private var value: UInt64
    private let bytesInNonce = 24
    
    public init(value: UInt64) {
        self.value = value
    }
    
    func next() -> Data {
        let nonce = getNonceFromInteger(value: value)
        value += NonceConstants.step
        return nonce
    }
    
    private func getNonceFromInteger(value: UInt64) -> Data {
        return
            Data(packBytes(value, parts: NonceConstants.bytesInUInt64).reversed()) +
            Data(count: NonceConstants.bytesDiff)
    }
}
