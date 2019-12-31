import Foundation
import LambdaRuntime
import Dispatch
import NIO
import NIOHTTP1
#if os(Linux)
import FoundationNetworking
#endif

let session = URLSession(configuration: .default)
func sendEcho(session: URLSession, completion: @escaping (Result<HTTPResponseStatus, Error>) -> ()) {
  
  let urlRequest = URLRequest(url: URL(string: "https://postman-echo.com/get?foo1=bar1&foo2=bar2")!)
  
  let task = session.dataTask(with: urlRequest) { (data, response, error) in
    if let error = error {
      completion(.failure(error))
    }
    
    guard let response = response as? HTTPURLResponse else {
      fatalError("unexpected response type")
    }
    
    let status = HTTPResponseStatus(statusCode: response.statusCode)
    
    completion(.success(status))
  }
  task.resume()
}

func echoCall(input: ByteBuffer?, context: Context) -> EventLoopFuture<ByteBuffer?> {
  
  let promise = context.eventLoop.makePromise(of: ByteBuffer?.self)
  
  sendEcho(session: session) { (result) in
    switch result {
    case .success(let status):
      context.logger.info("HTTP call with NSURLSession success: \(status)")
      promise.succeed(nil)
    case .failure(let error):
      context.logger.error("HTTP call with NSURLSession failed: \(error)")
      promise.fail(error)
    }
  }
  
  return promise.futureResult
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer { try! group.syncShutdownGracefully() }

do {
  let runtime = try LambdaRuntime.createRuntime(eventLoopGroup: group, handler: echoCall)
  defer { try! runtime.syncShutdown() }
  
  try runtime.start().wait()
}
catch {
  print("\(error)")
}
