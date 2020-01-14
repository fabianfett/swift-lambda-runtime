import Foundation
import XCTest
import Base64Kit
@testable import LambdaRuntime

class DecodableBodyTests: XCTestCase {

  struct TestEvent: DecodableBody {
    let body: String?
    let isBase64Encoded: Bool
  }
  
  struct TestPayload: Codable {
    let hello: String
  }
  
  func testSimplePayloadFromEvent() {
    do {
      let event = TestEvent(body: "{\"hello\":\"world\"}", isBase64Encoded: false)
      let payload = try event.decodeBody(TestPayload.self)
      
      XCTAssertEqual(payload.hello, "world")
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testBase64PayloadFromEvent() {
    do {
      let event = TestEvent(body: "eyJoZWxsbyI6IndvcmxkIn0=", isBase64Encoded: true)
      let payload = try event.decodeBody(TestPayload.self)
      
      XCTAssertEqual(payload.hello, "world")
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func testNoDataFromEvent() {
    do {
      let event = TestEvent(body: "", isBase64Encoded: false)
      _ = try event.decodeBody(TestPayload.self)
      
      XCTFail("Did not expect to reach this point")
    }
    catch DecodingError.dataCorrupted(_) {
      return // expected error
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }

  }

}
