//  SodiumExtedTest.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-06-09.
//  Copyright © 2017 Håkan Olsson. All rights reserved.

import XCTest
import Sodium

@testable import SaltChannel

class SodiumExtensionTest: XCTestCase {
    let sodium = Sodium()

    func testSha512() {
        let trueHash = sodium.utils.hex2bin("cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e")
        let hash = sodium.genericHash.hashSha512(data: Data())
        
        XCTAssertEqual(hash, trueHash)
    }
    
    func testSealWithNonce() {
        let message = sodium.utils.hex2bin("deadbeaf")!
        let sessionKey = sodium.utils.hex2bin("1b27556473e985d462cd51197a9a46c76009549eac6474f206c4ee0844f68389")!
        
        var nonce = Data(count: sodium.box.NonceBytes)
        nonce[0] = 5
        let encryptedMessageBeforenm: Data = sodium.box.seal(message: message, beforenm: sessionKey, nonce: nonce)!
        let decryptedBeforenm = sodium.box.open(authenticatedCipherText: encryptedMessageBeforenm, beforenm: sessionKey, nonce: nonce)
        
        XCTAssertEqual(decryptedBeforenm, message)
    }
}
