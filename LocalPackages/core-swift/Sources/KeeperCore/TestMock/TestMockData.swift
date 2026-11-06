import Foundation
import TonSwift

/// TEST ONLY: моковый баланс и NFT-коллекция для проверки интерфейса.
///
/// Работает ТОЛЬКО в Debug-сборке (`#if DEBUG`), в Release код вырезается компилятором.
/// Отключить без пересборки: `UserDefaults.standard.set(false, forKey: "TestMockData.enabled")`.
/// Все мок-NFT имеют префикс "[TEST]" в названии, баланс — фейковый, в блокчейне его нет.
enum TestMockData {
  #if DEBUG
  static let enabledKey = "TestMockData.enabled"
  
  static var isEnabled: Bool {
    guard UserDefaults.standard.object(forKey: enabledKey) != nil else { return true }
    return UserDefaults.standard.bool(forKey: enabledKey)
  }
  
  /// Добавляется к реальному TON-балансу, в нанотонах (100 TON).
  static let extraTonAmount: Int64 = 100_000_000_000
  static let nftsCount = 6
  static let collectionName = "[TEST] Collection"
  
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
  
  private static func previewURL(index: Int, size: Int) -> URL? {
    let colors = ["4FC3F7", "81C784", "FFB74D", "BA68C8", "E57373", "4DB6AC"]
    let color = colors[index % colors.count]
    return URL(string: "https://placehold.co/\(size)x\(size)/\(color)/FFFFFF/png?text=%23\(index)")
  }
  
  static func nfts(owner: Address) -> [NFT] {
    guard isEnabled else { return [] }
    let collection = NFTCollection(
      address: fakeAddress("test-collection"),
      name: collectionName,
      description: "Mock NFT collection for testing"
    )
    let ownerAccount = WalletAccount(address: owner, name: nil, isScam: false, isWallet: true)
    return (0..<nftsCount).map { index in
      NFT(
        address: fakeAddress("test-nft-\(index)"),
        owner: ownerAccount,
        name: "[TEST] NFT #\(index)",
        imageURL: previewURL(index: index, size: 500),
        preview: NFT.Preview(
          size5: previewURL(index: index, size: 5),
          size100: previewURL(index: index, size: 100),
          size500: previewURL(index: index, size: 500),
          size1500: previewURL(index: index, size: 1500)
        ),
        description: "Test NFT #\(index)",
        attributes: [NFT.Attribute(key: "type", value: "test")],
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
    return TonBalance(amount: real.amount + extraTonAmount)
  }
  #else
  static func nfts(owner: Address) -> [NFT] { [] }
  static func tonBalance(_ real: TonBalance) -> TonBalance { real }
  #endif
}
