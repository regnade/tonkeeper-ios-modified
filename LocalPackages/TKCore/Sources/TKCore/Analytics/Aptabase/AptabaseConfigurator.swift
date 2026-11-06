import Foundation
import Aptabase

public final class AptabaseConfigurator {
  
  public static let configurator = AptabaseConfigurator()
  
  private init() {}
  
  public func configure() {
    guard let appKey = InfoProvider.aptabaseKey(), !appKey.isEmpty else {
      return
    }
    Aptabase.shared.initialize(
      appKey: appKey,
      with: InitOptions(host: InfoProvider.aptabaseEndpoint())
    )
  }
}

public class AptabaseService: AnalyticsService {
  
  public init() {}
  
  public func logEvent(eventKey: EventKey, args: [String : Any]) {
    Aptabase.shared.trackEvent(eventKey.rawValue, with: args)
  }
}
