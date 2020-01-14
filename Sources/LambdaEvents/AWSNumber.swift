import Foundation

public struct AWSNumber: Codable, Equatable {
  
  public let stringValue: String
  
  public var int: Int? {
    return Int(stringValue)
  }
  
  public var double: Double? {
    return Double(stringValue)
  }
  
  public init(int: Int) {
    stringValue = String(int)
  }
  
  public init(double: Double) {
    stringValue = String(double)
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    stringValue = try container.decode(String.self)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(stringValue)
  }
}
