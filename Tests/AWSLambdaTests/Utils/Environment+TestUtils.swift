import NIO
import NIOHTTP1
@testable import AWSLambda

extension Environment {
  
  static func forTesting(
    lambdaRuntimeAPI: String? = nil,
    handler         : String? = nil,
    functionName    : String? = nil,
    functionVersion : String? = nil,
    logGroupName    : String? = nil,
    logStreamName   : String? = nil,
    memoryLimitInMB : String? = nil,
    accessKeyId     : String? = nil,
    secretAccessKey : String? = nil,
    sessionToken    : String? = nil)
    throws -> Environment
  {
    var env = [String: String]()
    
    env["AWS_LAMBDA_RUNTIME_API"]          = lambdaRuntimeAPI ?? "localhost"
    env["_HANDLER"]                        = handler ?? "lambda.handler"
    
    env["AWS_LAMBDA_FUNCTION_NAME"]        = functionName    ?? "TestFunction"
    env["AWS_LAMBDA_FUNCTION_VERSION"]     = functionVersion ?? "1"
    env["AWS_LAMBDA_LOG_GROUP_NAME"]       = logGroupName    ?? "TestFunctionLogGroupName"
    env["AWS_LAMBDA_LOG_STREAM_NAME"]      = logStreamName   ?? "TestFunctionLogStreamName"
    env["AWS_LAMBDA_FUNCTION_MEMORY_SIZE"] = memoryLimitInMB ?? "512"
    env["AWS_ACCESS_KEY_ID"]               = accessKeyId     ?? ""
    env["AWS_SECRET_ACCESS_KEY"]           = secretAccessKey ?? ""
    env["AWS_SESSION_TOKEN"]               = sessionToken    ?? ""
    
    return try Environment(env)
  }
  
  
}
