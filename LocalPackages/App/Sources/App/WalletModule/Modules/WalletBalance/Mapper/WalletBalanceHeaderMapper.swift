import UIKit
import TKUIKit
import TKLocalize
import TKCore
import KeeperCore
import BigInt

struct WalletBalanceHeaderMapper {
  
  private let decimalAmountFormatter: DecimalAmountFormatter
  private let dateFormatter: DateFormatter
  
  init(decimalAmountFormatter: DecimalAmountFormatter,
       dateFormatter: DateFormatter) {
    self.decimalAmountFormatter = decimalAmountFormatter
    self.dateFormatter = dateFormatter
  }
  
  func makeUpdatedDate(_ date: Date) -> String {
    dateFormatter.dateFormat = "d MMM HH:mm"
    return dateFormatter.string(from: date)
  }
  
  func mapTotalBalance(totalBalance: TotalBalance?) -> String {
    if let totalBalance = totalBalance {
      let formatted = decimalAmountFormatter.format(amount: totalBalance.amount,
                                           maximumFractionDigits: totalBalance.amount > 1000 ? 0 : 2,
                                           currency: totalBalance.currency)
      return TestMockData.isActive ? TestMockData.marked(formatted) : formatted
    } else {
      return TestMockData.isActive ? "[TEST] -" : "-"
    }
  }
}
