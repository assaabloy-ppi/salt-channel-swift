//  TestKeyGenerator.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-04.

import SaltChannel

typealias Byte = UInt8

class TestKeyGenerator {
    
    static func godKeys() -> KeyPit {
        let keypit = KeyPit()
        
        let clientSignSec = [Byte](hex: "55f4d1d198093c84de9ee9a6299e0f6891c2e1d0b369efb592a9e3f169fb0f795529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b")!
        let clientEncSec = [Byte](hex: "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")!

        
        let clientSignPub = [Byte](hex: "5529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b")!
        let clientEncPub  = [Byte](hex: "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a")!
        
        let serverSignPub = [Byte](hex: "07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b")!
        let serverEncPub  = [Byte](hex: "07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b")!

        guard
            let p1 = KeyPair(sec: clientSignSec, pub: clientSignPub, use: .clientsign),
            let p2 = KeyPair(sec: clientEncSec, pub: clientEncPub, use: .clientencrypt),
            
            let p3 = PubKey(pub: serverSignPub, use: .serversign),
            let p4 = PubKey(pub: serverEncPub, use: .serverencrypt) else {
                print("Bad input")
                return keypit
        }
        
        keypit.append(.clientsign, pair: p1)
        keypit.append(.clientencrypt, pair: p2)
        
        keypit.append(.serversign, pubkey: p3)
        keypit.append(.serverencrypt, pubkey: p4)

        return keypit
    }
    
    static func badFormatKeys() -> KeyPit {
        let keypit = KeyPit()
        
        let badClientSignSec = [Byte](hex: "f4d1d198093c84de9ee9a6299e0f6891c2e1d0b369efb592a9e3f169fb0f795529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b")!
        let clientEncSec = [Byte](hex: "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")!
        
        
        let clientSignPub = [Byte](hex: "5529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b")!
        let clientEncPub  = [Byte](hex: "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a")!
        
        let serverSignPub = [Byte](hex: "07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b")!
        let serverEncPub  = [Byte](hex: "07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b")!
        
        guard
            let p1 = KeyPair(sec: badClientSignSec, pub: clientSignPub, use: .clientsign),
            let p2 = KeyPair(sec: clientEncSec, pub: clientEncPub, use: .clientencrypt),
            
            let p3 = PubKey(pub: serverSignPub, use: .serversign),
            let p4 = PubKey(pub: serverEncPub, use: .serverencrypt) else {
                print("Bad input")
                return keypit
        }
        
        keypit.append(.clientsign, pair: p1)
        keypit.append(.clientencrypt, pair: p2)
        
        keypit.append(.serversign, pubkey: p3)
        keypit.append(.serverencrypt, pubkey: p4)
        
        return keypit
    }
    
    static func incompatibleFormatKeys() -> KeyPit {
        let keypit = KeyPit()
        
        let modClientSignSec = [Byte](hex: "fff4d1d198093c84de9ee9a6299e0f6891c2e1d0b369efb592a9e3f169fb0f795529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b")!
        let clientEncSec = [Byte](hex: "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")!
        
        
        let clientSignPub = [Byte](hex: "5529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b")!
        let clientEncPub  = [Byte](hex: "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a")!
        
        let serverSignPub = [Byte](hex: "07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b")!
        let serverEncPub  = [Byte](hex: "07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b")!
        
        guard
            let p1 = KeyPair(sec: modClientSignSec, pub: clientSignPub, use: .clientsign),
            let p2 = KeyPair(sec: clientEncSec, pub: clientEncPub, use: .clientencrypt),
            
            let p3 = PubKey(pub: serverSignPub, use: .serversign),
            let p4 = PubKey(pub: serverEncPub, use: .serverencrypt) else {
                print("Bad input")
                return keypit
        }
        
        keypit.append(.clientsign, pair: p1)
        keypit.append(.clientencrypt, pair: p2)
        
        keypit.append(.serversign, pubkey: p3)
        keypit.append(.serverencrypt, pubkey: p4)
        
        return keypit
    }
    
    static func sodiumGeneratedKeys() -> KeyPit {
        let keypit = KeyPit()
        
        let clientSign = sodium.sign.keyPair()!
        let clientEnc  = sodium.box.keyPair()!
        
        let serverSign = sodium.sign.keyPair()!
        let serverEnc = sodium.box.keyPair()!
        
        guard
            let p1 = KeyPair(sec: clientSign.secretKey.bytes,
                             pub: clientSign.publicKey.bytes, use: .clientsign),
            let p2 = KeyPair(sec: clientEnc.secretKey.bytes,
                             pub: clientEnc.publicKey.bytes, use: .clientencrypt),
            let p3 = PubKey(pub: serverSign.publicKey.bytes, use: .serversign),
            let p4 = PubKey(pub: serverEnc.publicKey.bytes, use: .serverencrypt)
        else {
            print("Bad input")
            return keypit
        }
        
        keypit.append(.clientsign, pair: p1)
        keypit.append(.clientencrypt, pair: p2)
        
        keypit.append(.serversign, pubkey: p3)
        keypit.append(.serverencrypt, pubkey: p4)
        
        return keypit
    }
}
