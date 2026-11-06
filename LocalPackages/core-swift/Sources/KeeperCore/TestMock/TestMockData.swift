import Foundation
import TonSwift

/// TEST ONLY: моковый баланс TON и NFT-«подарки» для проверки интерфейса.
///
/// Работает ТОЛЬКО в Debug-сборке (`#if DEBUG`), в Release код вырезается компилятором.
/// Управляется из Debug-панели (кнопка «TEST MODE» поверх приложения).
/// Все мок-NFT имеют префикс "[TEST]", баланс фейковый — в блокчейне его нет.
public enum TestMockData {
  #if DEBUG
  public static let didChangeNotification = Notification.Name("TestMockData.didChange")
  
  public struct Gift: Codable, Equatable {
    public let id: Int
    public let name: String
  }
  
  private enum Keys {
    static let enabled = "TestMockData.enabled"
    static let extraTonNano = "TestMockData.extraTonNano"
    static let gifts = "TestMockData.gifts"
    static let nextGiftId = "TestMockData.nextGiftId"
  }
  
  private static let defaults = UserDefaults.standard
  private static let nanoPerTon: Double = 1_000_000_000
  public static let collectionName = "[TEST] Gifts"
  
  // MARK: - Public controls (используются Debug-панелью)
  
  public static var isEnabled: Bool {
    get {
      guard defaults.object(forKey: Keys.enabled) != nil else { return true }
      return defaults.bool(forKey: Keys.enabled)
    }
    set {
      defaults.set(newValue, forKey: Keys.enabled)
      notifyChanged()
    }
  }
  
  /// Сумма, прибавляемая к реальному балансу, в TON. По умолчанию 100.
  public static var extraTon: Double {
    get {
      guard let nano = defaults.object(forKey: Keys.extraTonNano) as? NSNumber else { return 100 }
      return nano.doubleValue / nanoPerTon
    }
    set {
      let nano = Int64((max(newValue, 0) * nanoPerTon).rounded())
      defaults.set(NSNumber(value: nano), forKey: Keys.extraTonNano)
      notifyChanged()
    }
  }
  
  public static var gifts: [Gift] {
    if let data = defaults.data(forKey: Keys.gifts),
       let gifts = try? JSONDecoder().decode([Gift].self, from: data) {
      return gifts
    }
    return (0..<6).map { Gift(id: $0, name: "Gift #\($0)") }
  }
  
  public static func addGift(name: String?) {
    var current = gifts
    let nextId = max(defaults.integer(forKey: Keys.nextGiftId), (current.map { $0.id }.max() ?? -1) + 1)
    let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let giftName = trimmed.isEmpty ? "Gift #\(nextId)" : trimmed
    current.append(Gift(id: nextId, name: giftName))
    defaults.set(nextId + 1, forKey: Keys.nextGiftId)
    saveGifts(current)
  }
  
  public static func removeAllGifts() {
    saveGifts([])
  }
  
  public static func resetToDefaults() {
    defaults.removeObject(forKey: Keys.gifts)
    defaults.removeObject(forKey: Keys.extraTonNano)
    defaults.removeObject(forKey: Keys.nextGiftId)
    notifyChanged()
  }
  
  // MARK: - Internal (используется сервисами KeeperCore)
  
  static var isActive: Bool { isEnabled }
  
  static func nfts(owner: Address) -> [NFT] {
    guard isEnabled else { return [] }
    let collection = NFTCollection(
      address: fakeAddress("test-collection"),
      name: collectionName,
      description: "Mock gifts collection for testing"
    )
    let ownerAccount = WalletAccount(address: owner, name: nil, isScam: false, isWallet: true)
    return gifts.map { gift in
      NFT(
        address: fakeAddress("test-gift-\(gift.id)"),
        owner: ownerAccount,
        name: "[TEST] \(gift.name)",
        imageURL: previewURL(gift: gift, size: 500),
        preview: NFT.Preview(
          size5: previewURL(gift: gift, size: 5),
          size100: previewURL(gift: gift, size: 100),
          size500: previewURL(gift: gift, size: 500),
          size1500: previewURL(gift: gift, size: 1500)
        ),
        description: "Test gift: \(gift.name)",
        attributes: [NFT.Attribute(key: "type", value: "test gift")],
        collection: collection,
        programmaticButtons: nil,
        dns: nil,
        sale: nil,
        trust: .whitelist,
        renderType: nil,
        lottieURL: nil
      )
    }
  }
  
  static func tonBalance(_ real: TonBalance) -> TonBalance {
    guard isEnabled else { return real }
    return TonBalance(amount: real.amount + Int64((extraTon * nanoPerTon).rounded()))
  }
  
  // MARK: - Private
  
  private static func saveGifts(_ gifts: [Gift]) {
    if let data = try? JSONEncoder().encode(gifts) {
      defaults.set(data, forKey: Keys.gifts)
    }
    notifyChanged()
  }
  
  private static func notifyChanged() {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
  }
  
  private static func fakeAddress(_ seed: String) -> Address {
    var hash: UInt64 = 14695981039346656037
    var hex = ""
    var i = 0
    while hex.count < 64 {
      for byte in "\(seed)-\(i)".utf8 {
        hash = (hash ^ UInt64(byte)) &* 1099511628211
      }
      hex += String(format: "%016llx", hash)
      i += 1
    }
    return try! Address.parse("0:" + hex.prefix(64))
  }
  
  private static func previewURL(gift: Gift, size: Int) -> URL? {
    let colors = ["4FC3F7", "81C784", "FFB74D", "BA68C8", "E57373", "4DB6AC"]
    let color = colors[gift.id % colors.count]
    let text = gift.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "gift"
    return URL(string: "https://placehold.co/\(size)x\(size)/\(color)/FFFFFF/png?text=\(text)")
  }
  #else
  static var isActive: Bool { false }
  static func nfts(owner: Address) -> [NFT] { [] }
  static func tonBalance(_ real: TonBalance) -> TonBalance { real }
  #endif
}
