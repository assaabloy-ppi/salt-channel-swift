//  Nonce.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-06-08.

import Foundation
import Sodium

public class Nonce {
    private var value: UInt64!
    private let bytesInUInt64 = 8
    private let bytesInNonce = 24
    
    init (startValue: UInt64) {
        value = startValue
    }
    
    func getNextNonce() -> Data {
        let nonce = getNonceFromInteger(value: value)
        value = value + 2
        return nonce
    }
    
    func getNonceFromInteger(value: UInt64) -> Data {
        return
            Data(packBytes(value, parts: bytesInUInt64).reversed()) +
            Data(count: bytesInNonce-bytesInUInt64)
    }
}
