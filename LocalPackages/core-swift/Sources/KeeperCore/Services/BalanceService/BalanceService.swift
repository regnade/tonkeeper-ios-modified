import Foundation
import TonSwift
import BigInt

public protocol BalanceService {
  func loadWalletBalance(wallet: Wallet, currency: Currency) async throws -> WalletBalance
  func getBalance(wallet: Wallet) throws -> WalletBalance
}

final class BalanceServiceImplementation: BalanceService {
  private let tonBalanceService: TonBalanceService
  private let jettonsBalanceService: JettonBalanceService
  private let batteryService: BatteryService
  private let stackingService: StakingService
  private let tonProofTokenService: TonProofTokenService
  private let walletBalanceRepository: WalletBalanceRepository
  
  init(tonBalanceService: TonBalanceService, 
       jettonsBalanceService: JettonBalanceService,
       batteryService: BatteryService,
       stackingService: StakingService,
       tonProofTokenService: TonProofTokenService,
       walletBalanceRepository: WalletBalanceRepository) {
    self.tonBalanceService = tonBalanceService
    self.jettonsBalanceService = jettonsBalanceService
    self.batteryService = batteryService
    self.stackingService = stackingService
    self.tonProofTokenService = tonProofTokenService
    self.walletBalanceRepository = walletBalanceRepository
  }
 
  func loadWalletBalance(wallet: Wallet, currency: Currency) async throws -> WalletBalance {
    async let tonBalanceTask = tonBalanceService.loadBalance(wallet: wallet)
    async let jettonsBalanceTask = jettonsBalanceService.loadJettonsBalance(wallet: wallet, currency: currency)
    async let stackingBalanceTask = stackingService.loadStakingBalance(wallet: wallet)
    async let batteryBalanceTask = batteryService.loadBatteryBalance(
      wallet: wallet, 
      tonProofToken: tonProofTokenService.getWalletToken(wallet)
    )
    
    // TEST ONLY (Debug): если мок активен, ошибки сети не должны обнулять баланс
    let tonBalance: TonBalance
    let jettonsBalance: [JettonBalance]
    if TestMockData.isActive {
      let realTon = (try? await tonBalanceTask) ?? TonBalance(amount: 0)
      tonBalance = TestMockData.tonBalance(realTon)
      jettonsBalance = (try? await jettonsBalanceTask) ?? []
    } else {
      tonBalance = try await tonBalanceTask
      jettonsBalance = try await jettonsBalanceTask
    }
    let batteryBalance: BatteryBalance?
    do {
      batteryBalance = try await batteryBalanceTask
    } catch {
      batteryBalance = nil
    }
    
    let stackingBalance: [AccountStackingInfo]
    do {
      stackingBalance = try await stackingBalanceTask
    } catch {
      stackingBalance = []
    }
    
    let balance = Balance(
      tonBalance: tonBalance,
      jettonsBalance: jettonsBalance
    )
    
    let walletBalance = WalletBalance(
      date: Date(),
      balance: balance,
      stacking: stackingBalance,
      batteryBalance: batteryBalance
    )
    
    try? walletBalanceRepository.saveWalletBalance(
      walletBalance, 
      for: wallet
    )
    
    return walletBalance
  }
  
  func getBalance(wallet: Wallet) throws -> WalletBalance {
    try walletBalanceRepository.getWalletBalance(wallet: wallet)
  }
}
