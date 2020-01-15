import Foundation
import XCTest
@testable import LambdaRuntime
@testable import LambdaEvents

class AWSNumberTests: XCTestCase {
  
  // MARK: - Int -
  
  func testInteger() {
    let number = AWSNumber(int: 5)
    XCTAssertEqual(number.stringValue, "5")
    XCTAssertEqual(number.int, 5)
    XCTAssertEqual(number.double, 5)
  }
  
  func testIntCoding() {
    do {
      let number = AWSNumber(int: 3)
      struct TestStruct: Codable {
        let number: AWSNumber
      }
      
      // Test: Encoding
      
      let test = TestStruct(number: number)
      let data = try JSONEncoder().encode(test)
      let json = String(data: data, encoding: .utf8)
      XCTAssertEqual(json, "{\"number\":\"3\"}")
      
      // Test: Decoding
      
      let decoded = try JSONDecoder().decode(TestStruct.self, from: data)
      XCTAssertEqual(decoded.number.int, 3)
    }
    catch {
      XCTFail("unexpected error: \(error)")
    }
  }
  
  // MARK: - Double -
  
  func testDouble() {
    let number = AWSNumber(double: 3.14)
    XCTAssertEqual(number.stringValue, "3.14")
    XCTAssertEqual(number.int, nil)
    XCTAssertEqual(number.double, 3.14)
  }
  
  func testDoubleCoding() {
    do {
      let number = AWSNumber(double: 6.25)
      struct TestStruct: Codable {
        let number: AWSNumber
      }
      
      // Test: Encoding

      let test = TestStruct(number: number)
      let data = try JSONEncoder().encode(test)
      let json = String(data: data, encoding: .utf8)
      XCTAssertEqual(json, "{\"number\":\"6.25\"}")
      
      // Test: Decoding
      
      let decoded = try JSONDecoder().decode(TestStruct.self, from: data)
      XCTAssertEqual(decoded.number.int, nil)
      XCTAssertEqual(decoded.number.double, 6.25)
    }
    catch {
      XCTFail("unexpected error: \(error)")
    }
  }

}
