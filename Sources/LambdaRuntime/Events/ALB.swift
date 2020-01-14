import Foundation
import NIO
import NIOHTTP1


// https://github.com/aws/aws-lambda-go/blob/master/events/alb.go

public struct ALB {
  
  /// ALBTargetGroupRequest contains data originating from the ALB Lambda target group integration
  public struct TargetGroupRequest: DecodableBody {
    
    /// ALBTargetGroupRequestContext contains the information to identify the load balancer invoking the lambda
    public struct Context: Codable {
      public let elb: ELBContext
    }
    
    public let httpMethod: HTTPMethod
    public let path: String
    public let queryStringParameters: [String: [String]]
    public let headers: HTTPHeaders
    public let requestContext: Context
    public let isBase64Encoded: Bool
    public let body: String?
  }
  
  /// ELBContext contains the information to identify the ARN invoking the lambda
  public struct ELBContext: Codable {
    public let targetGroupArn: String
  }
  
  public struct TargetGroupResponse {
    
    public let statusCode       : HTTPResponseStatus
    public let statusDescription: String?
    public let headers          : HTTPHeaders?
    public let body             : String
    public let isBase64Encoded  : Bool
        
    public init(
      statusCode: HTTPResponseStatus,
      statusDescription: String? = nil,
      headers: HTTPHeaders? = nil,
      body: String = "",
      isBase64Encoded: Bool = false)
    {
      self.statusCode        = statusCode
      self.statusDescription = statusDescription
      self.headers           = headers
      self.body              = body
      self.isBase64Encoded   = isBase64Encoded
    }    
  }
}

// MARK: - Handler -

extension ALB {
  
  public static func handler(
    multiValueHeadersEnabled: Bool = false,
    _ handler: @escaping (ALB.TargetGroupRequest, Context) -> EventLoopFuture<ALB.TargetGroupResponse>)
    -> ((NIO.ByteBuffer, Context) -> EventLoopFuture<ByteBuffer?>)
  {
    // reuse as much as possible
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    encoder.userInfo[ALB.TargetGroupResponse.MultiValueHeadersEnabledKey] = multiValueHeadersEnabled
    
    return { (inputBytes: NIO.ByteBuffer, ctx: Context) -> EventLoopFuture<ByteBuffer?> in
      
      let req: ALB.TargetGroupRequest
      do {
        req = try decoder.decode(ALB.TargetGroupRequest.self, from: inputBytes)
      }
      catch {
        return ctx.eventLoop.makeFailedFuture(error)
      }
            
      return handler(req, ctx)
        .flatMapErrorThrowing() { (error) -> ALB.TargetGroupResponse in
          ctx.logger.error("Unhandled error. Responding with HTTP 500: \(error).")
          return ALB.TargetGroupResponse(statusCode: .internalServerError)
        }
        .flatMapThrowing { (result: ALB.TargetGroupResponse) -> NIO.ByteBuffer in
          return try encoder.encodeAsByteBuffer(result, allocator: ByteBufferAllocator())
        }
    }
  }
}

// MARK: - Request -

extension ALB.TargetGroupRequest: Decodable {
  
  enum CodingKeys: String, CodingKey {
    case httpMethod                      = "httpMethod"
    case path                            = "path"
    case queryStringParameters           = "queryStringParameters"
    case multiValueQueryStringParameters = "multiValueQueryStringParameters"
    case headers                         = "headers"
    case multiValueHeaders               = "multiValueHeaders"
    case requestContext                  = "requestContext"
    case isBase64Encoded                 = "isBase64Encoded"
    case body                            = "body"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    let method = try container.decode(String.self, forKey: .httpMethod)
    self.httpMethod = HTTPMethod(rawValue: method)
    
    self.path = try container.decode(String.self, forKey: .path)
    
    // crazy multiple headers
    // https://docs.aws.amazon.com/elasticloadbalancing/latest/application/lambda-functions.html#multi-value-headers
    
    if let multiValueQueryStringParameters =
      try container.decodeIfPresent([String: [String]].self, forKey: .multiValueQueryStringParameters)
    {
      self.queryStringParameters = multiValueQueryStringParameters
    }
    else {
      let singleValueQueryStringParameters = try container.decode(
        [String: String].self,
        forKey: .queryStringParameters)
      self.queryStringParameters = singleValueQueryStringParameters.mapValues { [$0] }
    }
    
    if let multiValueHeaders =
      try container.decodeIfPresent([String: [String]].self, forKey: .multiValueHeaders)
    {
      self.headers   = HTTPHeaders(awsHeaders: multiValueHeaders)
    }
    else {
      let singleValueHeaders = try container.decode(
        [String: String].self,
        forKey: .headers)
      let multiValueHeaders = singleValueHeaders.mapValues { [$0] }
      self.headers   = HTTPHeaders(awsHeaders: multiValueHeaders)
    }
    
    self.requestContext  = try container.decode(Context.self, forKey: .requestContext)
    self.isBase64Encoded = try container.decode(Bool.self, forKey: .isBase64Encoded)
    
    let body = try container.decode(String.self, forKey: .body)
    self.body = body != "" ? body : nil
  }
  
}

// MARK: - Response -

extension ALB.TargetGroupResponse: Encodable {
  
  internal static let MultiValueHeadersEnabledKey =
    CodingUserInfoKey(rawValue: "ALB.TargetGroupResponse.MultiValueHeadersEnabledKey")!
  
  enum CodingKeys: String, CodingKey {
    case statusCode
    case statusDescription
    case headers
    case multiValueHeaders
    case body
    case isBase64Encoded
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(statusCode.code, forKey: .statusCode)
    
    let multiValueHeaderSupport =
      encoder.userInfo[ALB.TargetGroupResponse.MultiValueHeadersEnabledKey] as? Bool ?? false
    
    switch (multiValueHeaderSupport, headers) {
    case (true, .none):
      try container.encode([String:String](), forKey: .multiValueHeaders)
    case (false, .none):
      try container.encode([String:[String]](), forKey: .headers)
    case (true, .some(let headers)):
      var multiValueHeaders: [String: [String]] = [:]
      headers.forEach { (name, value) in
        var values = multiValueHeaders[name] ?? []
        values.append(value)
        multiValueHeaders[name] = values
      }
      try container.encode(multiValueHeaders, forKey: .multiValueHeaders)
    case (false, .some(let headers)):
      var singleValueHeaders: [String: String] = [:]
      headers.forEach { (name, value) in
        singleValueHeaders[name] = value
      }
      try container.encode(singleValueHeaders, forKey: .headers)
    }
        
    try container.encodeIfPresent(statusDescription, forKey: .statusDescription)
    try container.encodeIfPresent(body, forKey: .body)
    try container.encodeIfPresent(isBase64Encoded, forKey: .isBase64Encoded)
  }

}

extension ALB.TargetGroupResponse {
  
  public init<Payload: Encodable>(
    statusCode       : HTTPResponseStatus,
    statusDescription: String? = nil,
    headers          : HTTPHeaders? = nil,
    payload          : Payload,
    encoder          : JSONEncoder = JSONEncoder()) throws
  {
    var headers = headers ?? HTTPHeaders()
    headers.add(name: "Content-Type", value: "application/json")
    
    self.statusCode        = statusCode
    self.statusDescription = statusDescription
    self.headers           = headers
    
    let buffer = try encoder.encodeAsByteBuffer(payload, allocator: ByteBufferAllocator())
    self.body  = buffer.getString(at: 0, length: buffer.readableBytes) ?? ""
    self.isBase64Encoded = false
  }
  
  /// Use this method to send any arbitrary byte buffer back to the API Gateway.
  /// Sadly Apple currently doesn't seem to be confident enough to advertise
  /// their base64 implementation publically. SAD. SO SAD. Therefore no
  /// ByteBuffer for you my friend.
  public init(
    statusCode       : HTTPResponseStatus,
    statusDescription: String? = nil,
    headers          : HTTPHeaders? = nil,
    buffer           : NIO.ByteBuffer)
  {
    let headers = headers ?? HTTPHeaders()
    
    self.statusCode        = statusCode
    self.statusDescription = statusDescription
    self.headers           = headers
    self.body              = buffer.withUnsafeReadableBytes { (ptr) -> String in
      return String(base64Encoding: ptr)
    }
    self.isBase64Encoded = true
  }
  
}

