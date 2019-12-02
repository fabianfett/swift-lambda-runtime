import Foundation
import NIO
import Base64Kit

extension DynamoDB {
  
  public enum AttributeValue {
    case boolean(Bool)
    case binary(NIO.ByteBuffer)
    case binarySet([NIO.ByteBuffer])
    case string(String)
    case stringSet([String])
    case null
    case number(AWSNumber)
    case numberSet([AWSNumber])
    
    case list([AttributeValue])
    case map([String: AttributeValue])
  }
  
}

extension DynamoDB.AttributeValue: Decodable {
  
  enum CodingKeys: String, CodingKey {
    case binary = "B"
    case bool = "BOOL"
    case binarySet = "BS"
    case list = "L"
    case map = "M"
    case number = "N"
    case numberSet = "NS"
    case null = "NULL"
    case string = "S"
    case stringSet = "SS"
  }
  
  public init(from decoder: Decoder) throws {
    
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let allocator = ByteBufferAllocator()
    
    guard container.allKeys.count == 1, let key = container.allKeys.first else {
      let context = DecodingError.Context(
        codingPath: container.codingPath,
        debugDescription: "Expected exactly one key, but got \(container.allKeys.count)")
      throw DecodingError.dataCorrupted(context)
    }
    
    switch key {
    case .binary:
      let encoded = try container.decode(String.self, forKey: .binary)
      let bytes = try encoded.base64decoded()
      var buffer = allocator.buffer(capacity: bytes.count)
      buffer.setBytes(bytes, at: 0)
      self = .binary(buffer)
      
    case .bool:
      let value = try container.decode(Bool.self, forKey: .bool)
      self = .boolean(value)
      
    case .binarySet:
      let values = try container.decode([String].self, forKey: .binarySet)
      let buffers = try values.map { (encoded) -> ByteBuffer in
        let bytes = try encoded.base64decoded()
        var buffer = allocator.buffer(capacity: bytes.count)
        buffer.setBytes(bytes, at: 0)
        return buffer
      }
      self = .binarySet(buffers)
      
    case .list:
      let values = try container.decode([DynamoDB.AttributeValue].self, forKey: .list)
      self = .list(values)
      
    case .map:
      let value = try container.decode([String: DynamoDB.AttributeValue].self, forKey: .map)
      self = .map(value)
      
    case .number:
      let value = try container.decode(AWSNumber.self, forKey: .number)
      self = .number(value)
      
    case .numberSet:
      let values = try container.decode([AWSNumber].self, forKey: .numberSet)
      self = .numberSet(values)
      
    case .null:
      self = .null
      
    case .string:
      let value = try container.decode(String.self, forKey: .string)
      self = .string(value)
      
    case .stringSet:
      let values = try container.decode([String].self, forKey: .stringSet)
      self = .stringSet(values)
    }
  }
}

extension DynamoDB.AttributeValue: Equatable {
  
  static public func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.boolean(let lhs), .boolean(let rhs)):
      return lhs == rhs
    case (.binary(let lhs), .binary(let rhs)):
      return lhs == rhs
    case (.binarySet(let lhs), .binarySet(let rhs)):
      return lhs == rhs
    case (.string(let lhs), .string(let rhs)):
      return lhs == rhs
    case (.stringSet(let lhs), .stringSet(let rhs)):
      return lhs == rhs
    case (.null, .null):
      return true
    case (.number(let lhs), .number(let rhs)):
      return lhs == rhs
    case (.numberSet(let lhs), .numberSet(let rhs)):
      return lhs == rhs
    case (.list(let lhs), .list(let rhs)):
      return lhs == rhs
    case (.map(let lhs), .map(let rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}
