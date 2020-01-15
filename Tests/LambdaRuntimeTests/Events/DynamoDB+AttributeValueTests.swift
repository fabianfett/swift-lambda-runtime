import Foundation
import XCTest
import NIO
@testable import LambdaRuntime
@testable import LambdaEvents

class DynamoDBAttributeValueTests: XCTestCase {

  func testBoolDecoding() throws {
    
    let json = "{\"BOOL\": true}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)
    
    XCTAssertEqual(value, .boolean(true))
  }
  
  func testBinaryDecoding() throws {
    
    let json = "{\"B\": \"YmFzZTY0\"}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)
    
    var buffer = ByteBufferAllocator().buffer(capacity: 6)
    buffer.setString("base64", at: 0)
    XCTAssertEqual(value, .binary(buffer))
  }
  
  func testBinarySetDecoding() throws {

    let json = "{\"BS\": [\"YmFzZTY0\", \"YWJjMTIz\"]}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)

    var buffer1 = ByteBufferAllocator().buffer(capacity: 6)
    buffer1.setString("base64", at: 0)
    
    var buffer2 = ByteBufferAllocator().buffer(capacity: 6)
    buffer2.setString("abc123", at: 0)
    
    XCTAssertEqual(value, .binarySet([buffer1, buffer2]))
  }

  func testStringDecoding() throws {

    let json = "{\"S\": \"huhu\"}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(value, .string("huhu"))
  }
  
  func testStringSetDecoding() throws {

    let json = "{\"SS\": [\"huhu\", \"haha\"]}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(value, .stringSet(["huhu", "haha"]))
  }
  
  func testNullDecoding() throws {
    let json = "{\"NULL\": true}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(value, .null)
  }
  
  func testNumberDecoding() throws {
    let json = "{\"N\": \"1.2345\"}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(value, .number(AWSNumber(double: 1.2345)))
  }
  
  func testNumberSetDecoding() throws {
    let json = "{\"NS\": [\"1.2345\", \"-19\"]}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(value, .numberSet([AWSNumber(double: 1.2345), AWSNumber(int: -19)]))
  }
  
  func testListDecoding() throws {
    let json = "{\"L\": [{\"NS\": [\"1.2345\", \"-19\"]}, {\"S\": \"huhu\"}]}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(value, .list([.numberSet([AWSNumber(double: 1.2345), AWSNumber(int: -19)]), .string("huhu")]))
  }
  
  func testMapDecoding() throws {
    let json = "{\"M\": {\"numbers\": {\"NS\": [\"1.2345\", \"-19\"]}, \"string\": {\"S\": \"huhu\"}}}"
    let value = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(value, .map([
      "numbers": .numberSet([AWSNumber(double: 1.2345), AWSNumber(int: -19)]),
      "string": .string("huhu")
    ]))
  }
  
  func testEmptyDecoding() throws {
    let json = "{\"haha\": 1}"
    do {
      _ = try JSONDecoder().decode(DynamoDB.AttributeValue.self, from: json.data(using: .utf8)!)
      XCTFail("Did not expect to reach this point")
    }
    catch {
      switch error {
      case DecodingError.dataCorrupted(let context):
        // expected error
        XCTAssertEqual(context.codingPath.count, 0)
      default:
        XCTFail("Unexpected error: \(String(describing: error))")
      }
    }

  }
  
  func testEquatable() {
    XCTAssertEqual(DynamoDB.AttributeValue.boolean(true), .boolean(true))
    XCTAssertNotEqual(DynamoDB.AttributeValue.boolean(true), .boolean(false))
    XCTAssertNotEqual(DynamoDB.AttributeValue.boolean(true), .string("haha"))
  }

}
