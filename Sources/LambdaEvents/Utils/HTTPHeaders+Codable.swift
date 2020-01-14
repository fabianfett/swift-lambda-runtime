import NIOHTTP1

extension HTTPHeaders {
  
  init(awsHeaders: [String: [String]]) {
    var nioHeaders: [(String, String)] = []
    awsHeaders.forEach { (key, values) in
      values.forEach { (value) in
        nioHeaders.append((key, value))
      }
    }
    
    self = HTTPHeaders(nioHeaders)
  }
}
