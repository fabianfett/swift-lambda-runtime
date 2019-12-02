import Foundation
import NIO

/// https://github.com/aws/aws-lambda-go/blob/master/events/sqs.go
public struct SQS {
  
  public struct Event: Codable {
    public let records: [Message]
    
    enum CodingKeys: String, CodingKey {
      case records = "Records"
    }
  }
  
  public struct Message: Codable {
    
    /// https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_MessageAttributeValue.html
    public enum Attribute {
      case string(String)
      case binary(ByteBuffer)
      case number(AWSNumber)
    }
    
    public let messageId              : String
    public let receiptHandle          : String
    public let body                   : String
    public let md5OfBody              : String
    public let md5OfMessageAttributes : String?
    public let attributes             : [String: String]
    public let messageAttributes      : [String: Attribute]
    public let eventSourceArn         : String
    public let eventSource            : String
    public let awsRegion              : String
    
    enum CodingKeys: String, CodingKey {
      case messageId
      case receiptHandle
      case body
      case md5OfBody
      case md5OfMessageAttributes
      case attributes
      case messageAttributes
      case eventSourceArn         = "eventSourceARN"
      case eventSource
      case awsRegion
    }
  }
}

extension SQS.Message.Attribute: Equatable { }

extension SQS.Message.Attribute: Codable {
  
  enum CodingKeys: String, CodingKey {
    case dataType
    case stringValue
    case binaryValue
    
    // BinaryListValue and StringListValue are unimplemented since
    // they are not implemented as discussed here:
    // https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_MessageAttributeValue.html
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let dataType = try container.decode(String.self, forKey: .dataType)
    switch dataType {
    case "String":
      let value = try container.decode(String.self, forKey: .stringValue)
      self = .string(value)
    case "Number":
      let value = try container.decode(AWSNumber.self, forKey: .stringValue)
      self = .number(value)
    case "Binary":
      let base64encoded = try container.decode(String.self, forKey: .binaryValue)
      let bytes = try base64encoded.base64decoded()
      
      var buffer = ByteBufferAllocator().buffer(capacity: bytes.count)
      buffer.writeBytes(bytes)
      buffer.moveReaderIndex(to: bytes.count)
      
      self = .binary(buffer)
    default:
      throw DecodingError.dataCorruptedError(forKey: .dataType, in: container, debugDescription: """
        Unexpected value \"\(dataType)\" for key \(CodingKeys.dataType).
        Expected `String`, `Binary` or `Number`.
        """)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    switch self {
    case .binary(let byteBuffer):
      let base64 = byteBuffer.withUnsafeReadableBytes { (pointer) -> String in
        return String(base64Encoding: pointer)
      }
      
      try container.encode("Binary", forKey: .dataType)
      try container.encode(base64, forKey: .stringValue)
    case .string(let string):
      try container.encode("String", forKey: .dataType)
      try container.encode(string, forKey: .binaryValue)
    case .number(let number):
      try container.encode("Number", forKey: .dataType)
      try container.encode(number, forKey: .binaryValue)
    }
  }
}
