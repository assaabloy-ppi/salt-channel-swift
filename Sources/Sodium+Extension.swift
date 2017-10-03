//  Sodium+Extend.swift
//  SaltChannel
//
//  Created by Håkan Olsson on 2017-06-09.

import Foundation
import libsodium
import Sodium

extension GenericHash {
    /**
     Computes a fixed-length sha512 fingerprint for an arbitrary long message.
     - Parameter message: The message from which to compute the fingerprint.
     - Returns: The computed fingerprint.
     */
    @objc public func hashSha512(data: Data) -> Data {
        let state = UnsafeMutablePointer<crypto_hash_sha512_state>.allocate(capacity: 1)
        let initReturn = crypto_hash_sha512_init(state)
        assert(initReturn == 0)
        let updateReturn = data.withUnsafeBytes { messagePtr in
            return crypto_hash_sha512_update(state, messagePtr, CUnsignedLongLong(data.count))
        }
        assert(updateReturn == 0)
        var output = Data(count: 64)
    
        let finalReturn = output.withUnsafeMutableBytes { outputPtr in
            return crypto_hash_sha512_final(state, outputPtr)
        }
        assert(finalReturn == 0)
        return output
    }
}

extension Box {
    /**
     Encrypts a message with the shared secret key generated from a recipient's public key and a sender's secret key using `beforenm()`.
     - Parameter message: The message to encrypt.
     - Parameter beforenm: The shared secret key.
     - Parameter nonce: The encryption nonce.
     - Returns: The authenticated ciphertext
     */
    public func seal(message: Data, beforenm: Beforenm, nonce: Nonce) -> Data? {
        if beforenm.count != BeforenmBytes {
            return nil
        }
    
        var authenticatedCipherText = Data(count: message.count + MacBytes)
    
        let result = authenticatedCipherText.withUnsafeMutableBytes { authenticatedCipherTextPtr in
            return message.withUnsafeBytes { messagePtr in
                return nonce.withUnsafeBytes { noncePtr in
                    return beforenm.withUnsafeBytes { beforenmPtr in
                        return crypto_box_easy_afternm(
                            authenticatedCipherTextPtr,
                            messagePtr,
                            CUnsignedLongLong(message.count),
                            noncePtr,
                            beforenmPtr)
                    }
                }
            }
        }
    
        if result != 0 {
            return nil
        }
    
        return authenticatedCipherText
    }
}
