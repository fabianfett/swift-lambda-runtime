import Foundation

public protocol DecodableBody {
  
  var body: String? { get }
  var isBase64Encoded: Bool { get }
  
}

public extension DecodableBody {
  
  var isBase64Encoded: Bool {
    return false
  }
  
}

public extension DecodableBody {
  
  func decodeBody<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
    
    // I would really like to not use Foundation.Data at all, but well
    // the NIOFoundationCompat just creates an internal Data as well.
    // So let's save one malloc and copy and just use Data.
    let payload = self.body ?? ""
    
    let data: Data
    if self.isBase64Encoded {
      let bytes = try payload.base64decoded()
      data = Data(bytes)
    }
    else {
      // TBD: Can this ever fail? I wouldn't think so...
      data = payload.data(using: .utf8)!
    }
    
    return try decoder.decode(T.self, from: data)
  }
}
