//  ProtocolTests.swift
//  SaltChannel-Tests
//
//  Created by Kenneth Pernyer on 2017-10-12.

import XCTest
@testable import SaltChannel

class AProtocolTests: XCTestCase {
    let salt  = Data("SCv2------".utf8)
    let blank = Data("----------".utf8)
    let echo  = Data("ECHO------".utf8)

    func testExtractProtocolsFromA2() {
        do {
            
            let protocols1: [(first: String, second: String)] = try extractProtocols(n: 1, data: salt + blank)
            let protocols2: [(first: String, second: String)] = try extractProtocols(n: 2, data: salt + echo + salt + blank)
            let protocols3: [(first: String, second: String)] = try extractProtocols(n: 3, data: salt + echo + salt + salt + salt + blank)
        
            XCTAssertEqual(protocols1.count, 1)
            XCTAssertEqual(protocols2.count, 2)
            XCTAssertEqual(protocols3.count, 3)
        
            XCTAssertEqual(protocols1[0].first, "SCv2------")
            XCTAssertEqual(protocols1[0].second, "----------")

            XCTAssertEqual(protocols2[0].first, "SCv2------")
            XCTAssertEqual(protocols2[0].second, "ECHO------")
            XCTAssertEqual(protocols2[1].first, "SCv2------")
            XCTAssertEqual(protocols2[1].second, "----------")
            
            XCTAssertEqual(protocols3[0].first, "SCv2------")
            XCTAssertEqual(protocols3[0].second, "ECHO------")
            XCTAssertEqual(protocols3[1].first, "SCv2------")
            XCTAssertEqual(protocols3[1].second, "SCv2------")
            XCTAssertEqual(protocols3[2].first, "SCv2------")
            XCTAssertEqual(protocols3[2].second, "----------")
        } catch {
            print(error)
            XCTFail("Protocols malformated")
        }
    }
    
    func testExtractBadProtocolsFromA2() {
        let long = Data("1234567890A".utf8)
        let short = Data("123456789".utf8)

        do {
            _ = try extractProtocols(n: 2, data: salt)
            XCTFail("Protocols malformated")
        } catch {  }

        do {
            _ = try extractProtocols(n: 0, data: salt + echo)
            XCTFail("Protocols malformated")
        } catch {  }
        
        do {
            _ = try extractProtocols(n: 1, data: salt + echo + salt + blank)
            XCTFail("Protocols malformated")
        } catch {  }
        
        do {
            _ = try extractProtocols(n: 2, data: salt + salt + salt + salt + salt)
            XCTFail("Protocols malformated")
        } catch {  }
        
        do {
            _ = try extractProtocols(n: 2, data: salt + salt + salt + short)
            XCTFail("Protocols malformated")
        } catch {  }
        
        do {
            _ = try extractProtocols(n: 2, data: salt + short + salt + long)
            // No way we can know that they mixed 9 + 11 + 10
        } catch { XCTFail("Protocols malformated")
 }
    }
}
