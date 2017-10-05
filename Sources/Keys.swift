//  Keys.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-04.

import Foundation

public typealias Byte = UInt8

public enum Use {
    case clientsign
    case clientencrypt
    case serversign
    case serverencrypt
}

public protocol Key: Hashable {
    associatedtype KeyType
}

public struct KeyPair: Key {
    public typealias KeyType = KeyPair

    let sec: [Byte]
    let pub: [Byte]
    let use: Use
    
    public init?(sec: [Byte], pub: [Byte], use: Use) {
        var count: Int {
            switch use {
            case .clientsign, .serversign : return 64
            default: return 32
            }
        }
        
        guard pub.count == 32, sec.count == count else {
            return nil
        }
        
        self.sec = sec
        self.pub = pub
        self.use = use
    }
}

public struct PubKey: Key {
    public typealias KeyType = PubKey
    
    let pub: [Byte]
    let use: Use
    
    public init?(pub: [Byte], use: Use) {
        guard pub.count == 32 else {
            return nil
        }
        
        self.pub = pub
        self.use = use
    }
}

public class KeyPit {
    var keyPairs: [Use: KeyPair] = [:]
    var pubKeys: [Use: PubKey] = [:]

    public init() {}
    
    public func append(_ use: Use, pair: KeyPair) {
        keyPairs.updateValue(pair, forKey: use)
    }
    
    public func append(_ use: Use, pubkey: PubKey) {
        pubKeys.updateValue(pubkey, forKey: use)
    }
    
    public func pubkey(for use: Use) -> PubKey? {
        return pubKeys[use]
    }
    
    public func keypair(for use: Use) -> KeyPair? {
        return keyPairs[use]
    }
}

extension KeyPit {
    public func selfVerify() -> Bool {
        return true
    }
}

extension KeyPair: Hashable {
    public var hashValue: Int { return sec.reduce(5381) {
        ($0 << 5) &+ $0 &+ Int($1)
        } }
    
    public static func == (lhs: KeyPair, rhs: KeyPair) -> Bool {
        return lhs.hashValue == rhs.hashValue && lhs.sec == rhs.sec
    }
}

extension PubKey: Hashable {
    public var hashValue: Int { return pub.reduce(5381) {
        ($0 << 5) &+ $0 &+ Int($1)
        } }
    
    public static func == (lhs: PubKey, rhs: PubKey) -> Bool {
        return lhs.hashValue == rhs.hashValue && lhs.pub == rhs.pub
    }
}
