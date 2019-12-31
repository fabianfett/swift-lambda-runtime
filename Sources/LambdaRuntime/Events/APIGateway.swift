import Foundation
import NIOFoundationCompat
import NIO
import NIOHTTP1

// https://github.com/aws/aws-lambda-go/blob/master/events/apigw.go

public struct APIGateway {
  
  // https://github.com/aws/aws-lambda-go/blob/master/events/apigw.go
  public struct Request: Codable {
    
    public struct Context: Codable {
      
      public struct Identity: Codable {
        public let cognitoIdentityPoolId: String?
        
        public let apiKey: String?
        public let userArn: String?
        public let cognitoAuthenticationType: String?
        public let caller: String?
        public let userAgent: String?
        public let user: String?
        
        public let cognitoAuthenticationProvider: String?
        public let sourceIp: String?
        public let accountId: String?
      }
      
      public let resourceId: String
      public let apiId: String
      public let resourcePath: String
      public let httpMethod: String
      public let requestId: String
      public let accountId: String
      public let stage: String
      
      public let identity: Identity
      public let extendedRequestId: String?
      public let path: String
    }
    
    public let resource: String
    public let path: String
    public let httpMethod: String
    
    public let queryStringParameters: String?
    public let multiValueQueryStringParameters: [String:[String]]?
    public let headers: [String: String]?
    public let multiValueHeaders: [String: [String]]?
    public let pathParameters: [String:String]?
    public let stageVariables: [String:String]?
    
    public let requestContext: Request.Context
    public let body: String?
    public let isBase64Encoded: Bool
  }
  
  public struct Response {
        
    public let statusCode     : HTTPResponseStatus
    public let headers        : HTTPHeaders?
    public let body           : String?
    public let isBase64Encoded: Bool?
        
    public init(
      statusCode: HTTPResponseStatus,
      headers: HTTPHeaders? = nil,
      body: String? = nil,
      isBase64Encoded: Bool? = nil)
    {
      self.statusCode      = statusCode
      self.headers         = headers
      self.body            = body
      self.isBase64Encoded = isBase64Encoded
    }
  }
}

// MARK: - Handler -

extension APIGateway {
  
  public static func handler(
    decoder: JSONDecoder = JSONDecoder(),
    encoder: JSONEncoder = JSONEncoder(),
    _ handler: @escaping (APIGateway.Request, Context) -> EventLoopFuture<APIGateway.Response>)
    -> ((NIO.ByteBuffer, Context) -> EventLoopFuture<ByteBuffer?>)
  {
    return { (inputBytes: NIO.ByteBuffer, ctx: Context) -> EventLoopFuture<ByteBuffer?> in
      
      let req: APIGateway.Request
      do {
        req = try decoder.decode(APIGateway.Request.self, from: inputBytes)
      }
      catch {
        return ctx.eventLoop.makeFailedFuture(error)
      }
            
      return handler(req, ctx)
        .flatMapErrorThrowing() { (error) -> APIGateway.Response in
          ctx.logger.error("Unhandled error. Responding with HTTP 500: \(error).")
          return APIGateway.Response(statusCode: .internalServerError)
        }
        .flatMapThrowing { (result: Response) -> NIO.ByteBuffer in
          return try encoder.encodeAsByteBuffer(result, allocator: ByteBufferAllocator())
        }
    }
  }
}

// MARK: - Request -

extension APIGateway.Request {
  
  public func payload<Payload: Decodable>(decoder: JSONDecoder = JSONDecoder()) throws -> Payload {
    let body = self.body ?? ""
        
    let capacity = body.lengthOfBytes(using: .utf8)

    // TBD: I am pretty sure, we don't need this buffer copy here.
    //      Access the strings buffer directly to get to the data.
    var buffer   = ByteBufferAllocator().buffer(capacity: capacity)
    buffer.setString(body, at: 0)
    buffer.moveWriterIndex(to: capacity)
    
    return try decoder.decode(Payload.self, from: buffer)
  }
}

// MARK: - Response -

extension APIGateway.Response: Encodable {
  
  enum CodingKeys: String, CodingKey {
    case statusCode
    case headers
    case body
    case isBase64Encoded
  }

  private struct HeaderKeys: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
      self.stringValue = stringValue
    }
    var intValue: Int? {
      fatalError("unexpected use")
    }
    init?(intValue: Int) {
      fatalError("unexpected use")
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(statusCode.code, forKey: .statusCode)
    
    if let headers = headers {
      var headerContainer = container.nestedContainer(keyedBy: HeaderKeys.self, forKey: .headers)
      try headers.forEach { (name, value) in
        try headerContainer.encode(value, forKey: HeaderKeys(stringValue: name)!)
      }
    }
    
    try container.encodeIfPresent(body, forKey: .body)
    try container.encodeIfPresent(isBase64Encoded, forKey: .isBase64Encoded)
  }

}

extension APIGateway.Response {
  
  public init<Payload: Encodable>(
    statusCode: HTTPResponseStatus,
    headers   : HTTPHeaders? = nil,
    payload   : Payload,
    encoder   : JSONEncoder = JSONEncoder()) throws
  {
    var headers = headers ?? HTTPHeaders()
    headers.add(name: "Content-Type", value: "application/json")
    
    self.statusCode = statusCode
    self.headers    = headers
    
    let buffer = try encoder.encodeAsByteBuffer(payload, allocator: ByteBufferAllocator())
    self.body  = buffer.getString(at: 0, length: buffer.readableBytes)
    self.isBase64Encoded = false
  }
  
  #if false
  /// Use this method to send any arbitrary byte buffer back to the API Gateway.
  /// Sadly Apple currently doesn't seem to be confident enough to advertise
  /// their base64 implementation publically. SAD. SO SAD. Therefore no
  /// ByteBuffer for you my friend.
  public init(
    statusCode: HTTPResponseStatus,
    headers   : HTTPHeaders? = nil,
    buffer    : NIO.ByteBuffer)
  {
    var headers = headers ?? HTTPHeaders()
    headers.add(name: "Content-Type", value: "application/json")
    
    self.statusCode = statusCode
    self.headers    = headers
    
    self.body       = String(base64Encoding: buffer.getBytes(at: 0, length: buffer.readableBytes))
    self.isBase64Encoded = true
  }
  #endif
  
}
