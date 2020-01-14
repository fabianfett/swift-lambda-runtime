import Foundation

// https://github.com/aws/aws-lambda-go/blob/master/events/alb.go
public struct IoT {
  
  public struct ButtonEvent: Codable {
    public let serialNumber: String
    public let clickType: String
    public let batteryVoltage: String
  }
  
}

