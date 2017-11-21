//  Data+Extension.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-13.

import Foundation

extension Data {
    var bytes: [UInt8] {
        return Array(self)
    }
    
    var hex: String {
        return self.bytes.toHexString()
    }
    
    var string: String {
        return self.toString() ?? ""
    }
    
    func toHexString(_ separator: String = "") -> String {
        return self.bytes.toHexString(separator)
    }
    
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}
