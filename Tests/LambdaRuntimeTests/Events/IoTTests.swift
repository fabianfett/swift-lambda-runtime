import Foundation
import XCTest
@testable import LambdaRuntime

class IoTTests: XCTestCase {

  static let buttonEventPayload = """
    {
      "serialNumber": "ABCDEFG12345",
      "clickType": "SINGLE",
      "batteryVoltage": "2000 mV"
    }
    """
  
  func testScheduledEventFromJSON() {
    let data = IoTTests.buttonEventPayload.data(using: .utf8)!
    do {
      let event = try JSONDecoder().decode(IoT.ButtonEvent.self, from: data)
      
      XCTAssertEqual(event.serialNumber, "ABCDEFG12345")
      XCTAssertEqual(event.clickType, "SINGLE")
      XCTAssertEqual(event.batteryVoltage, "2000 mV")
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
