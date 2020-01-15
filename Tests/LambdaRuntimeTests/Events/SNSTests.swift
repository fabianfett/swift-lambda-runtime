import Foundation
import XCTest
import NIO
@testable import LambdaRuntime
@testable import LambdaEvents

class SNSTests: XCTestCase {

  static let eventPayload = """
    {
      "Records": [
        {
          "EventSource": "aws:sns",
          "EventVersion": "1.0",
          "EventSubscriptionArn": "arn:aws:sns:eu-central-1:079477498937:EventSources-SNSTopic-1NHENSE2MQKF5:6fabdb7f-b27e-456d-8e8a-14679db9e40c",
          "Sns": {
            "Type": "Notification",
            "MessageId": "bdb6900e-1ae9-5b4b-b7fc-c681fde222e3",
            "TopicArn": "arn:aws:sns:eu-central-1:079477498937:EventSources-SNSTopic-1NHENSE2MQKF5",
            "Subject": null,
            "Message": "{\\\"hello\\\": \\\"world\\\"}",
            "Timestamp": "2020-01-08T14:18:51.203Z",
            "SignatureVersion": "1",
            "Signature": "LJMF/xmMH7A1gNy2unLA3hmzyf6Be+zS/Yeiiz9tZbu6OG8fwvWZeNOcEZardhSiIStc0TF7h9I+4Qz3omCntaEfayzTGmWN8itGkn2mfn/hMFmPbGM8gEUz3+jp1n6p+iqP3XTx92R0LBIFrU3ylOxSo8+SCOjA015M93wfZzwj0WPtynji9iAvvtf15d8JxPUu1T05BRitpFd5s6ZXDHtVQ4x/mUoLUN8lOVp+rs281/ZdYNUG/V5CwlyUDTOERdryTkBJ/GO1NNPa+6m04ywJFa5d+BC8mDcUcHhhXXjpTEbt8AHBmswK3nudHrVMRO/G4zmssxU2P7ii5+gCfA==",
            "SigningCertUrl": "https://sns.eu-central-1.amazonaws.com/SimpleNotificationService-6aad65c2f9911b05cd53efda11f913f9.pem",
            "UnsubscribeUrl": "https://sns.eu-central-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-central-1:079477498937:EventSources-SNSTopic-1NHENSE2MQKF5:6fabdb7f-b27e-456d-8e8a-14679db9e40c",
            "MessageAttributes": {
              "binary":{
                "Type": "Binary",
                "Value": "YmFzZTY0"
              },
              "string":{
                "Type": "String",
                "Value": "abc123"
              }
            }
          }
        }
      ]
    }
    """
  
  struct TestStruct: Decodable {
    let hello: String
  }
  
  func testSimpleEventFromJSON() {
    let data = SNSTests.eventPayload.data(using: .utf8)!
    do {
      let event = try JSONDecoder().decode(SNS.Event.self, from: data)
      
      guard let record = event.records.first else {
        XCTFail("Expected to have one record"); return
      }
      
      XCTAssertEqual(record.eventSource, "aws:sns")
      XCTAssertEqual(record.eventVersion, "1.0")
      XCTAssertEqual(record.eventSubscriptionArn, "arn:aws:sns:eu-central-1:079477498937:EventSources-SNSTopic-1NHENSE2MQKF5:6fabdb7f-b27e-456d-8e8a-14679db9e40c")
      
      XCTAssertEqual(record.sns.type, "Notification")
      XCTAssertEqual(record.sns.messageId, "bdb6900e-1ae9-5b4b-b7fc-c681fde222e3")
      XCTAssertEqual(record.sns.topicArn, "arn:aws:sns:eu-central-1:079477498937:EventSources-SNSTopic-1NHENSE2MQKF5")
      XCTAssertEqual(record.sns.message, "{\"hello\": \"world\"}")
      XCTAssertEqual(record.sns.timestamp, Date(timeIntervalSince1970: 1578493131.203))
      XCTAssertEqual(record.sns.signatureVersion, "1")
      XCTAssertEqual(record.sns.signature, "LJMF/xmMH7A1gNy2unLA3hmzyf6Be+zS/Yeiiz9tZbu6OG8fwvWZeNOcEZardhSiIStc0TF7h9I+4Qz3omCntaEfayzTGmWN8itGkn2mfn/hMFmPbGM8gEUz3+jp1n6p+iqP3XTx92R0LBIFrU3ylOxSo8+SCOjA015M93wfZzwj0WPtynji9iAvvtf15d8JxPUu1T05BRitpFd5s6ZXDHtVQ4x/mUoLUN8lOVp+rs281/ZdYNUG/V5CwlyUDTOERdryTkBJ/GO1NNPa+6m04ywJFa5d+BC8mDcUcHhhXXjpTEbt8AHBmswK3nudHrVMRO/G4zmssxU2P7ii5+gCfA==")
      XCTAssertEqual(record.sns.signingCertURL, "https://sns.eu-central-1.amazonaws.com/SimpleNotificationService-6aad65c2f9911b05cd53efda11f913f9.pem")
      XCTAssertEqual(record.sns.unsubscribeUrl, "https://sns.eu-central-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-central-1:079477498937:EventSources-SNSTopic-1NHENSE2MQKF5:6fabdb7f-b27e-456d-8e8a-14679db9e40c")
      
      XCTAssertEqual(record.sns.messageAttributes.count, 2)
      
      var binaryBuffer = ByteBufferAllocator().buffer(capacity: 6)
      binaryBuffer.setString("base64", at: 0)
      XCTAssertEqual(record.sns.messageAttributes["binary"], .binary(binaryBuffer))
      XCTAssertEqual(record.sns.messageAttributes["string"], .string("abc123"))
      
      let payload = try record.sns.decodeBody(TestStruct.self)
      XCTAssertEqual(payload.hello, "world")
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
