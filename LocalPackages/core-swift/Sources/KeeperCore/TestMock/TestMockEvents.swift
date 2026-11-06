import Foundation
import TonSwift
import BigInt

extension TestMockData {
  static func eventsIfNeeded(wallet: Wallet) -> [AccountEvent] {
    guard isActive, let owner = try? wallet.address else { return [] }
    return events(owner: owner)
  }

  static func event(id: String, wallet: Wallet) -> AccountEvent? {
    eventsIfNeeded(wallet: wallet).first { $0.eventId == id }
  }

  /// Тестовые события на тех же типах, что рисует оригинальный Tonkeeper (AccountEvent / AccountEventAction).
  static func events(owner: Address) -> [AccountEvent] {
    let ownerAccount = WalletAccount(address: owner, name: nil, isScam: false, isWallet: true)
    let now = Date()
    let usdt = testUsdtJetton()
    let giftNFT = nfts(owner: owner).first

    return [
      makeEvent(
        id: "test-event-ton-in",
        date: now.addingTimeInterval(-15 * 60),
        owner: ownerAccount,
        action: tonTransfer(
          sender: namedAccount("test-alice", "[TEST] Alice"),
          recipient: ownerAccount,
          amount: 12_500_000_000,
          comment: "[TEST] Received TON",
          previewName: "Received TON"
        )
      ),
      makeEvent(
        id: "test-event-ton-out",
        date: now.addingTimeInterval(-2 * 60 * 60),
        owner: ownerAccount,
        action: tonTransfer(
          sender: ownerAccount,
          recipient: namedAccount("test-bob", "[TEST] Bob"),
          amount: 1_250_000_000,
          comment: "[TEST] Sent TON",
          previewName: "Sent TON"
        )
      ),
      makeEvent(
        id: "test-event-jetton-in",
        date: now.addingTimeInterval(-5 * 60 * 60),
        owner: ownerAccount,
        action: jettonTransfer(
          sender: namedAccount("test-carol", "[TEST] Carol"),
          recipient: ownerAccount,
          amount: BigUInt(25_000000),
          jetton: usdt,
          comment: "[TEST] Received USD₮"
        )
      ),
      makeEvent(
        id: "test-event-swap",
        date: now.addingTimeInterval(-26 * 60 * 60),
        owner: ownerAccount,
        action: jettonSwap(owner: ownerAccount, usdt: usdt)
      ),
      makeEvent(
        id: "test-event-nft",
        date: now.addingTimeInterval(-30 * 60 * 60),
        owner: ownerAccount,
        action: nftItemTransfer(
          sender: namedAccount("test-gifts", "[TEST] Gifts"),
          recipient: ownerAccount,
          nftAddress: giftNFT?.address ?? fakeAddress("test-gift-0"),
          comment: "[TEST] NFT received"
        )
      ),
      makeEvent(
        id: "test-event-nft-buy",
        date: now.addingTimeInterval(-3 * 24 * 60 * 60),
        owner: ownerAccount,
        action: nftPurchase(owner: ownerAccount, nft: giftNFT)
      ),
      makeEvent(
        id: "test-event-stake",
        date: now.addingTimeInterval(-4 * 24 * 60 * 60),
        owner: ownerAccount,
        action: depositStake(owner: ownerAccount)
      ),
      makeEvent(
        id: "test-event-deploy",
        date: now.addingTimeInterval(-8 * 24 * 60 * 60),
        owner: ownerAccount,
        action: contractDeploy(owner: owner)
      )
    ]
  }

  private static func makeEvent(
    id: String,
    date: Date,
    owner: WalletAccount,
    action: AccountEventAction
  ) -> AccountEvent {
    AccountEvent(
      eventId: id,
      date: date,
      account: owner,
      isScam: false,
      isInProgress: false,
      extra: .Fee(5_000_000),
      actions: [action]
    )
  }

  private static func namedAccount(_ seed: String, _ name: String) -> WalletAccount {
    WalletAccount(address: fakeAddress(seed), name: name, isScam: false, isWallet: true)
  }

  private static func preview(
    name: String,
    description: String,
    value: String?,
    accounts: [WalletAccount]
  ) -> AccountEventAction.SimplePreview {
    AccountEventAction.SimplePreview(
      name: marked(name),
      description: marked(description),
      image: nil,
      value: value,
      valueImage: nil,
      accounts: accounts
    )
  }

  private static func tonTransfer(
    sender: WalletAccount,
    recipient: WalletAccount,
    amount: Int64,
    comment: String,
    previewName: String
  ) -> AccountEventAction {
    AccountEventAction(
      type: .tonTransfer(.init(
        sender: sender,
        recipient: recipient,
        amount: amount,
        comment: comment,
        encryptedComment: nil
      )),
      status: .ok,
      preview: preview(
        name: previewName,
        description: "Transfer",
        value: "\(amount / 1_000_000_000) TON",
        accounts: [sender, recipient]
      )
    )
  }

  private static func jettonTransfer(
    sender: WalletAccount,
    recipient: WalletAccount,
    amount: BigUInt,
    jetton: JettonInfo,
    comment: String
  ) -> AccountEventAction {
    AccountEventAction(
      type: .jettonTransfer(.init(
        sender: sender,
        recipient: recipient,
        senderAddress: sender.address,
        recipientAddress: recipient.address,
        amount: amount,
        jettonInfo: jetton,
        comment: comment,
        encryptedComment: nil
      )),
      status: .ok,
      preview: preview(
        name: "Received \(jetton.symbol ?? jetton.name)",
        description: "Jetton transfer",
        value: "25 \(jetton.symbol ?? "")",
        accounts: [sender, recipient]
      )
    )
  }

  private static func jettonSwap(owner: WalletAccount, usdt: JettonInfo) -> AccountEventAction {
    let router = namedAccount("test-stonfi", "[TEST] STONfi")
    return AccountEventAction(
      type: .jettonSwap(.init(
        dex: "stonfi",
        amountIn: 0,
        amountOut: BigUInt(50_000000),
        tonIn: 10_000_000_000,
        tonOut: nil,
        user: owner,
        router: router,
        jettonInfoIn: nil,
        jettonInfoOut: usdt
      )),
      status: .ok,
      preview: preview(
        name: "Swap TON to USD₮",
        description: "Swap",
        value: "50 USD₮",
        accounts: [owner, router]
      )
    )
  }

  private static func nftItemTransfer(
    sender: WalletAccount,
    recipient: WalletAccount,
    nftAddress: Address,
    comment: String
  ) -> AccountEventAction {
    AccountEventAction(
      type: .nftItemTransfer(.init(
        sender: sender,
        recipient: recipient,
        nftAddress: nftAddress,
        comment: comment,
        payload: nil,
        encryptedComment: nil
      )),
      status: .ok,
      preview: preview(
        name: "Received NFT",
        description: "NFT transfer",
        value: "NFT",
        accounts: [sender]
      )
    )
  }

  private static func nftPurchase(owner: WalletAccount, nft: NFT?) -> AccountEventAction {
    let seller = namedAccount("test-getgems", "[TEST] Getgems")
    let item = nft ?? NFT(
      address: fakeAddress("test-gift-0"),
      owner: owner,
      name: marked("Gift #0"),
      imageURL: nil,
      preview: NFT.Preview(size5: nil, size100: nil, size500: nil, size1500: nil),
      description: "TEST gift",
      attributes: [],
      collection: NFTCollection(address: fakeAddress("test-collection"), name: collectionName, description: nil),
      programmaticButtons: nil,
      dns: nil,
      sale: nil,
      trust: .whitelist,
      renderType: nil,
      lottieURL: nil
    )
    return AccountEventAction(
      type: .nftPurchase(.init(
        auctionType: "getgems",
        nft: item,
        seller: seller,
        buyer: owner,
        price: BigUInt(3_000_000_000)
      )),
      status: .ok,
      preview: preview(
        name: "NFT Purchase",
        description: "Purchase",
        value: "3 TON",
        accounts: [seller]
      )
    )
  }

  private static func depositStake(owner: WalletAccount) -> AccountEventAction {
    let pool = namedAccount("test-tonstakers", "[TEST] Tonstakers")
    return AccountEventAction(
      type: .depositStake(.init(
        amount: 20_000_000_000,
        staker: owner,
        pool: pool,
        implementation: .liquidTF
      )),
      status: .ok,
      preview: preview(
        name: "Deposit Stake",
        description: "Stake",
        value: "20 TON",
        accounts: [pool]
      )
    )
  }

  private static func contractDeploy(owner: Address) -> AccountEventAction {
    AccountEventAction(
      type: .contractDeploy(.init(address: owner)),
      status: .ok,
      preview: preview(
        name: "Wallet initialized",
        description: "Deploy",
        value: nil,
        accounts: []
      )
    )
  }

  private static func testUsdtJetton() -> JettonInfo {
    JettonInfo(
      isTransferable: true,
      hasCustomPayload: false,
      address: JettonMasterAddress.tonUSDT,
      fractionDigits: 6,
      name: marked("Tether USD"),
      symbol: "USD₮",
      verification: .whitelist,
      imageURL: URL(string: "https://placehold.co/200x200/26A17B/FFFFFF/png?text=TEST-USDT")
    )
  }
}
