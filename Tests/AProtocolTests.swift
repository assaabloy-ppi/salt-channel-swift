//  ProtocolTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-12.

import XCTest
@testable import SaltChannel

class AProtocolTests: XCTestCase {
    let version1 = Data("SC2------1".utf8)
    let version2 = Data("SC2------2".utf8)
    let version3 = Data("SC2------3".utf8)
    let version4 = Data("ECHO------".utf8)

    func testExtractProtocolsFromA2() {
        let oneprotocol = Data(bytes: [0x01]) + version1
        let twoprotocols = Data(bytes: [0x02]) + version1 + version2
        let threeprotocol = Data(bytes: [0x04]) + version1 + version2 + version3 + version4

        do {
            let array1: [String] = try extractProtocols(data: oneprotocol)
            let array2: [String] = try extractProtocols(data: twoprotocols)
            let array3: [String] = try extractProtocols(data: threeprotocol)
        
            XCTAssertEqual(array1.count, 1)
            XCTAssertEqual(array2.count, 2)
            XCTAssertEqual(array3.count, 4)
        
            XCTAssertEqual(array1[0], "SC2------1")
            XCTAssertEqual(array2[0], "SC2------1")
            XCTAssertEqual(array3[0], "SC2------1")
            XCTAssertEqual(array2[1], "SC2------2")
            XCTAssertEqual(array3[1], "SC2------2")
            XCTAssertEqual(array3[2], "SC2------3")
        } catch { XCTFail() }
    }
    
    func testExtractBadProtocolsFromA2() {
        let version4 = Data("1234567890A".utf8)
        let version5 = Data("123456789".utf8)

        let oneprotocol = Data(bytes: [0x02]) + version1
        let twoprotocols = Data(bytes: [0x01]) + version1 + version2
        let threeprotocol = Data(bytes: [0x03]) + version1 + version2 + version4
        let fourprotocol = Data(bytes: [0x03]) + version5 + version4 + version3

        do {
            let _ = try extractProtocols(data: oneprotocol)
            XCTFail()
        } catch {  }

        do {
            let _ = try extractProtocols(data: twoprotocols)
            XCTFail()
        } catch {  }
        
        do {
            let _ = try extractProtocols(data: threeprotocol)
            XCTFail()
        } catch {  }
        
        do {
            let _ = try extractProtocols(data: fourprotocol)
            // No way we can know that they mixed 9 + 11 + 10
        } catch { XCTFail()
 }
    }
}
