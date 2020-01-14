import Foundation
import NIO
import Base64Kit

/// https://github.com/aws/aws-lambda-go/blob/master/events/sns.go
public struct SNS {
  
  public struct Event: Decodable {
    
    public struct Record: Decodable {
      public let eventVersion: String
      public let eventSubscriptionArn: String
      public let eventSource: String
      public let sns: Message
      
      public enum CodingKeys: String, CodingKey {
        case eventVersion         = "EventVersion"
        case eventSubscriptionArn = "EventSubscriptionArn"
        case eventSource          = "EventSource"
        case sns                  = "Sns"
      }
    }
    
    public let records: [Record]
    
    public enum CodingKeys: String, CodingKey {
      case records = "Records"
    }
  }
  
  public struct Message {
    
    public enum Attribute {
      case string(String)
      case binary(ByteBuffer)
    }
    
    public let signature        : String
    public let messageId        : String
    public let type             : String
    public let topicArn         : String
    public let messageAttributes: [String: Attribute]
    public let signatureVersion : String
    public let timestamp        : Date
    public let signingCertURL   : String
    public let message          : String
    public let unsubscribeUrl   : String
    public let subject          : String?
    
  }
}

extension SNS.Message: Decodable {
  
  enum CodingKeys: String, CodingKey {
    case signature         = "Signature"
    case messageId         = "MessageId"
    case type              = "Type"
    case topicArn          = "TopicArn"
    case messageAttributes = "MessageAttributes"
    case signatureVersion  = "SignatureVersion"
    case timestamp         = "Timestamp"
    case signingCertURL    = "SigningCertUrl"
    case message           = "Message"
    case unsubscribeUrl    = "UnsubscribeUrl"
    case subject           = "Subject"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    self.signature         = try container.decode(String.self, forKey: .signature)
    self.messageId         = try container.decode(String.self, forKey: .messageId)
    self.type              = try container.decode(String.self, forKey: .type)
    self.topicArn          = try container.decode(String.self, forKey: .topicArn)
    self.messageAttributes = try container.decode([String: Attribute].self, forKey: .messageAttributes)
    self.signatureVersion  = try container.decode(String.self, forKey: .signatureVersion)
    
    let dateString         = try container.decode(String.self, forKey: .timestamp)
    guard let timestamp = SNS.Message.dateFormatter.date(from: dateString) else {
      let dateFormat = String(describing: SNS.Message.dateFormatter.dateFormat)
      throw DecodingError.dataCorruptedError(forKey: .timestamp, in: container, debugDescription:
        "Expected date to be in format `\(dateFormat)`, but `\(dateFormat) does not forfill format`")
    }
    self.timestamp         = timestamp
    
    self.signingCertURL    = try container.decode(String.self, forKey: .signingCertURL)
    self.message           = try container.decode(String.self, forKey: .message)
    self.unsubscribeUrl    = try container.decode(String.self, forKey: .unsubscribeUrl)
    self.subject           = try container.decodeIfPresent(String.self, forKey: .subject)
  }

  private static let dateFormatter: DateFormatter = SNS.Message.createDateFormatter()
  private static func createDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }

}

extension SNS.Message: DecodableBody {
  
  public var body: String? {
    return self.message != "" ? self.message : nil
  }
  
  @available(*, deprecated, renamed: "decodeBody(_:decoder:)")
  public func payload<Payload: Decodable>(decoder: JSONDecoder = JSONDecoder()) throws -> Payload {
    return try self.decodeBody(Payload.self, decoder: decoder)
  }
}

extension SNS.Message.Attribute: Equatable {}

extension SNS.Message.Attribute: Codable {
  
  enum CodingKeys: String, CodingKey {
    case dataType  = "Type"
    case dataValue = "Value"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let dataType = try container.decode(String.self, forKey: .dataType)
    // https://docs.aws.amazon.com/sns/latest/dg/sns-message-attributes.html#SNSMessageAttributes.DataTypes
    switch dataType {
    case "String":
      let value = try container.decode(String.self, forKey: .dataValue)
      self = .string(value)
    case "Binary":
      let base64encoded = try container.decode(String.self, forKey: .dataValue)
      let bytes = try base64encoded.base64decoded()
      
      var buffer = ByteBufferAllocator().buffer(capacity: bytes.count)
      buffer.writeBytes(bytes)
      buffer.moveReaderIndex(to: bytes.count)
      
      self = .binary(buffer)
    default:
      throw DecodingError.dataCorruptedError(forKey: .dataType, in: container, debugDescription: """
        Unexpected value \"\(dataType)\" for key \(CodingKeys.dataType).
        Expected `String` or `Binary`.
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
      try container.encode(base64, forKey: .dataValue)
    case .string(let string):
      try container.encode("String", forKey: .dataType)
      try container.encode(string, forKey: .dataValue)
    }
  }

}
