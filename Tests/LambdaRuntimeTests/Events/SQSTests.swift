import Foundation
import XCTest
import NIO
@testable import LambdaRuntime
@testable import LambdaEvents

class SQSTests: XCTestCase {

  static let testPayload = """
    {
      "Records": [
        {
          "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
          "receiptHandle": "MessageReceiptHandle",
          "body": "Hello from SQS!",
          "attributes": {
            "ApproximateReceiveCount": "1",
            "SentTimestamp": "1523232000000",
            "SenderId": "123456789012",
            "ApproximateFirstReceiveTimestamp": "1523232000001"
          },
          "messageAttributes": {
            "number":{
              "stringValue":"123",
              "stringListValues":[],
              "binaryListValues":[],
              "dataType":"Number"
            },
            "string":{
              "stringValue":"abc123",
              "stringListValues":[],
              "binaryListValues":[],
              "dataType":"String"
            },
            "binary":{
              "dataType": "Binary",
              "stringListValues":[],
              "binaryListValues":[],
              "binaryValue":"YmFzZTY0"
            },

          },
          "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
          "eventSource": "aws:sqs",
          "eventSourceARN": "arn:aws:sqs:us-east-1:123456789012:MyQueue",
          "awsRegion": "us-east-1"
        }
      ]
    }
    """

  
  func testSimpleEventFromJSON() {
    let data = SQSTests.testPayload.data(using: .utf8)!
    do {
      let decoder = JSONDecoder()
      let event = try decoder.decode(SQS.Event.self, from: data)
      
      XCTAssertEqual(event.records.count, 1)
      
      guard let message = event.records.first else {
        XCTFail("Expected to have one message in the event")
        return
      }
      
      XCTAssertEqual(message.messageId       , "19dd0b57-b21e-4ac1-bd88-01bbb068cb78")
      XCTAssertEqual(message.receiptHandle   , "MessageReceiptHandle")
      XCTAssertEqual(message.body            , "Hello from SQS!")
      XCTAssertEqual(message.attributes.count, 4)
      
      var binaryBuffer = ByteBufferAllocator().buffer(capacity: 6)
      binaryBuffer.setString("base64", at: 0)
      XCTAssertEqual(message.messageAttributes, [
        "number": .number(AWSNumber(int: 123)),
        "string": .string("abc123"),
        "binary": .binary(binaryBuffer)
      ])
      XCTAssertEqual(message.md5OfBody       , "7b270e59b47ff90a553787216d55d91d")
      XCTAssertEqual(message.eventSource     , "aws:sqs")
      XCTAssertEqual(message.eventSourceArn  , "arn:aws:sqs:us-east-1:123456789012:MyQueue")
      XCTAssertEqual(message.awsRegion       , "us-east-1")
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
