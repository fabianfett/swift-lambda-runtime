import Foundation
import XCTest
@testable import LambdaEvents
@testable import LambdaRuntime

class CloudwatchTests: XCTestCase {

  static let scheduledEventPayload = """
    {
      "id": "cdc73f9d-aea9-11e3-9d5a-835b769c0d9c",
      "detail-type": "Scheduled Event",
      "source": "aws.events",
      "account": "123456789012",
      "time": "1970-01-01T00:00:00Z",
      "region": "us-east-1",
      "resources": [
        "arn:aws:events:us-east-1:123456789012:rule/ExampleRule"
      ],
      "detail": {}
    }
    """
  
  func testScheduledEventFromJSON() {
    let data = CloudwatchTests.scheduledEventPayload.data(using: .utf8)!
    do {
      let decoder = JSONDecoder()
      let event = try decoder.decode(Cloudwatch.Event<Cloudwatch.ScheduledEvent>.self, from: data)
      
      XCTAssertEqual(event.id        , "cdc73f9d-aea9-11e3-9d5a-835b769c0d9c")
      XCTAssertEqual(event.detailType, "Scheduled Event")
      XCTAssertEqual(event.source    , "aws.events")
      XCTAssertEqual(event.accountId , "123456789012")
      XCTAssertEqual(event.time      , Date(timeIntervalSince1970: 0))
      XCTAssertEqual(event.region    , "us-east-1")
      XCTAssertEqual(event.resources , ["arn:aws:events:us-east-1:123456789012:rule/ExampleRule"])
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
