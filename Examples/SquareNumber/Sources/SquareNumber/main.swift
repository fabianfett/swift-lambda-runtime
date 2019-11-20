import AWSLambda
import NIO

struct Input: Codable {
  let number: Double
}

struct Output: Codable {
  let result: Double
}

func squareNumber(input: Input, context: Context) -> Output {
  let squaredNumber = input.number * input.number
  return Output(result: squaredNumber)
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
  try! group.syncShutdownGracefully()
}

do {
  let runtime = try Runtime.createRuntime(eventLoopGroup: group)
  defer { try! runtime.syncShutdown() }
  
  runtime.register(for: "squareNumber", handler: Runtime.codable(squareNumber))
  try runtime.start().wait()
}
catch {
  print(String(describing: error))
}


