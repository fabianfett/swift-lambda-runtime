import Foundation
import NIO

// https://github.com/aws/aws-lambda-go/blob/master/events/s3.go
public struct S3 {
  
  public struct Event: Decodable {
    public struct Record {
      public let eventVersion: String
      public let eventSource: String
      public let awsRegion: String
      public let eventTime: Date
      public let eventName: String
      public let userIdentity: UserIdentity
      public let requestParameters: RequestParameters
      public let responseElements: [String: String]
      public let s3: Entity
    }
    
    public let records: [Record]
    
    public enum CodingKeys: String, CodingKey {
      case records = "Records"
    }
  }
  
  public struct RequestParameters: Codable, Equatable {
    public let sourceIPAddress: String
  }
  
  public struct UserIdentity: Codable, Equatable {
    public let principalId: String
  }
  
  public struct Entity: Codable {
    public let configurationId : String
    public let schemaVersion   : String
    public let bucket          : Bucket
    public let object          : Object
    
    enum CodingKeys: String, CodingKey {
      case configurationId = "configurationId"
      case schemaVersion   = "s3SchemaVersion"
      case bucket          = "bucket"
      case object          = "object"
    }
  }
  
  public struct Bucket: Codable {
    public let name         : String
    public let ownerIdentity: UserIdentity
    public let arn          : String
  }
  
  public struct Object: Codable {
    public let key          : String
    public let size         : UInt64
    public let urlDecodedKey: String?
    public let versionId    : String?
    public let eTag         : String
    public let sequencer    : String
  }
}

extension S3.Event.Record: Decodable {
  
  enum CodingKeys: String, CodingKey {
    case eventVersion
    case eventSource
    case awsRegion
    case eventTime
    case eventName
    case userIdentity
    case requestParameters
    case responseElements
    case s3
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    self.eventVersion      = try container.decode(String.self, forKey: .eventVersion)
    self.eventSource       = try container.decode(String.self, forKey: .eventSource)
    self.awsRegion         = try container.decode(String.self, forKey: .awsRegion)
    
    let dateString         = try container.decode(String.self, forKey: .eventTime)
    guard let timestamp = S3.Event.Record.dateFormatter.date(from: dateString) else {
      let dateFormat = String(describing: S3.Event.Record.dateFormatter.dateFormat)
      throw DecodingError.dataCorruptedError(forKey: .eventTime, in: container, debugDescription:
        "Expected date to be in format `\(dateFormat)`, but `\(dateFormat) does not forfill format`")
    }
    self.eventTime         = timestamp
    
    self.eventName         = try container.decode(String.self, forKey: .eventName)
    self.userIdentity      = try container.decode(S3.UserIdentity.self, forKey: .userIdentity)
    self.requestParameters = try container.decode(S3.RequestParameters.self, forKey: .requestParameters)
    self.responseElements  = try container.decodeIfPresent([String:String].self, forKey: .responseElements) ?? [:]
    self.s3                = try container.decode(S3.Entity.self, forKey: .s3)
  }

  private static let dateFormatter: DateFormatter = S3.Event.Record.createDateFormatter()
  private static func createDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }
}
