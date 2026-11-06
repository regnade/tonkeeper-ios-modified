import Foundation
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics
import FirebasePerformance

public final class FirebaseConfigurator: NSObject {
  
  public static let configurator = FirebaseConfigurator()
  
  private override init() {}
  
  public func configure() {
    guard Self.hasValidGoogleServiceInfo else {
      return
    }
    FirebaseApp.configure()
  }

  public static var hasValidGoogleServiceInfo: Bool {
    guard let options = FirebaseOptions.defaultOptions() else {
      return false
    }
    let apiKey = options.apiKey ?? ""
    let projectId = options.projectID ?? ""
    if apiKey.isEmpty || apiKey == "placeholder" || apiKey.contains("AIzaSyAAA") {
      return false
    }
    if projectId.isEmpty || projectId.contains("placeholder") {
      return false
    }
    let appId = options.googleAppID
    if appId.isEmpty || appId == "1:0:ios:0" || appId.contains("123456789012") {
      return false
    }
    return true
  }
}
