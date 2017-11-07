//  Array+Extension.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-13.
//  Support to go back and forth between Hex String and ByteArray

public typealias Byte = UInt8

extension Array where Element: BinaryInteger, Element.IntegerLiteralType == Byte {
    
    public init?(hex: String) {
        self = [Element]()
        self.reserveCapacity(hex.unicodeScalars.lazy.underestimatedCount)
        
        var buffer: Byte?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                self.removeAll()
                return nil
            }
            
            let v: Byte
            let c: Byte = Byte(char.value)
            
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                self.removeAll()
                return nil
            }
            
            if let b = buffer as? Element, let v = v as? Element {
                self.append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        
        if let b = buffer as? Element {
            self.append(b)
        }
    }
}

extension Array where Iterator.Element == Byte {
    
    public func toHexString(_ separator: String = "") -> String {
        return self.lazy.reduce("") {
            var str = String($1, radix: 16)
            if str.count == 1 {
                str = "0" + str
            }
            return $0 + "\(separator)\(str)"
        }
    }
    
    private func toHexRow() -> String {
        return self.lazy.reduce("") {
            var str = String($1, radix: 16)
            if str.count == 1 {
                str = "0" + str
            }
            return $0 + "0x\(str), "
        }
    }
    
    // Quick and Dirty Pretty print
    public func prettyPrint(_ columns: Int = 8) {
        for i in stride(from: 0, to: self.count, by: columns) {
            let end = Swift.min(i+columns, self.count)
            let row = [Byte](self[i ... end-1])
            print(row.toHexRow())
        }
        print()
    }
}

public func toByteArray<T>(_ value: T) -> [Byte] {
    var value = value
    return withUnsafeBytes(of: &value) { Array($0) }
}

public func fromByteArray<T>(_ value: [Byte], _: T.Type) -> T {
    return value.withUnsafeBytes {
        $0.baseAddress!.load(as: T.self)
    }
}

public func fromByteArray2<T>(_ value: [Byte], _: T.Type) -> T {
    return value.withUnsafeBufferPointer {
        $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
            $0.pointee
        }
    }
}

public func toHexArray(_ value: [Byte]) -> [String] {
    return value.map { String(format: "%02x", $0) }
}

public func toHexString(_ value: [Byte]) -> String {
    return toHexArray(value).joined()
}
