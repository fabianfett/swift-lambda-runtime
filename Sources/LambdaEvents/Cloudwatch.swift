import Foundation

public struct Cloudwatch {
  
  public struct Event<Detail: Decodable> {
    public let id         : String
    public let detailType : String
    public let source     : String
    public let accountId  : String
    public let time       : Date
    public let region     : String
    public let resources  : [String]
    public let detail     : Detail
  }
  
  public struct ScheduledEvent: Codable {}
  
  fileprivate static let dateFormatter: DateFormatter = Cloudwatch.createDateFormatter()
  fileprivate static func createDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    formatter.timeZone   = TimeZone(secondsFromGMT: 0)
    formatter.locale     = Locale(identifier: "en_US_POSIX")
    return formatter
  }
}

extension Cloudwatch.Event: Decodable {
  
  enum CodingKeys: String, CodingKey {
    case id         = "id"
    case detailType = "detail-type"
    case source     = "source"
    case accountId  = "account"
    case time       = "time"
    case region     = "region"
    case resources  = "resources"
    case detail     = "detail"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    self.id         = try container.decode(String.self, forKey: .id)
    self.detailType = try container.decode(String.self, forKey: .detailType)
    self.source     = try container.decode(String.self, forKey: .source)
    self.accountId  = try container.decode(String.self, forKey: .accountId)
    
    let dateString  = try container.decode(String.self, forKey: .time)
    guard let time = Cloudwatch.dateFormatter.date(from: dateString) else {
      let dateFormat = String(describing: Cloudwatch.dateFormatter.dateFormat)
      throw DecodingError.dataCorruptedError(forKey: .time, in: container, debugDescription:
        "Expected date to be in format `\(dateFormat)`, but `\(dateFormat) does not forfill format`")
    }
    self.time       = time
    
    self.region     = try container.decode(String.self, forKey: .region)
    self.resources  = try container.decode([String].self, forKey: .resources)
    self.detail     = try container.decode(Detail.self, forKey: .detail)
  }
}
