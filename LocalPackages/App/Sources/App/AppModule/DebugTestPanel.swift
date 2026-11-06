import UIKit
import KeeperCore

/// TEST ONLY: плавающая красная кнопка «TEST MODE» поверх приложения.
/// Нажатие открывает панель управления тестовым балансом TON и NFT-подарками.
public final class DebugTestPanel: NSObject {
  
  public static let shared = DebugTestPanel()
  
  private weak var window: UIWindow?
  private let button = UIButton(type: .system)
  
  public static func install(in window: UIWindow) {
    shared.install(in: window)
  }
  
  private func install(in window: UIWindow) {
    guard button.superview == nil else { return }
    self.window = window
    
    // Без UIButton.Configuration: проект поддерживает iOS 14
    button.setTitle("TEST MODE", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .bold)
    button.backgroundColor = .systemRed
    button.layer.cornerRadius = 11
    button.clipsToBounds = true
    button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    button.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(_:))))
    button.sizeToFit()
    button.frame.origin = CGPoint(
      x: window.bounds.width - button.bounds.width - 8,
      y: window.safeAreaInsets.top + 4
    )
    button.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
    window.addSubview(button)
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(bringToFront),
      name: UIWindow.didBecomeVisibleNotification,
      object: nil
    )
  }
  
  @objc private func bringToFront() {
    window?.bringSubviewToFront(button)
  }
  
  @objc private func didPan(_ gesture: UIPanGestureRecognizer) {
    guard let superview = button.superview else { return }
    let translation = gesture.translation(in: superview)
    button.center = CGPoint(x: button.center.x + translation.x, y: button.center.y + translation.y)
    gesture.setTranslation(.zero, in: superview)
  }
  
  @objc private func didTapButton() {
    presentMenu()
  }
  
  // MARK: - Menu
  
  private func presentMenu() {
    let gifts = TestMockData.gifts
    let message = """
    TEST
    Мок: \(TestMockData.isEnabled ? "ВКЛ" : "ВЫКЛ")
    Добавка к балансу: \(format(TestMockData.extraTon)) TON [TEST]
    Подарков: \(gifts.count) [TEST]
    
    Данные фейковые, в блокчейне их нет.
    """
    let alert = UIAlertController(title: "TEST MODE", message: message, preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "TEST: задать баланс TON", style: .default) { [weak self] _ in
      self?.presentBalanceInput()
    })
    alert.addAction(UIAlertAction(title: "TEST: добавить подарок", style: .default) { [weak self] _ in
      self?.presentGiftInput()
    })
    alert.addAction(UIAlertAction(title: "TEST: добавить 5 подарков", style: .default) { _ in
      (0..<5).forEach { _ in TestMockData.addGift(name: nil) }
    })
    alert.addAction(UIAlertAction(title: "TEST: удалить все подарки", style: .destructive) { _ in
      TestMockData.removeAllGifts()
    })
    alert.addAction(UIAlertAction(title: TestMockData.isEnabled ? "TEST: выключить мок" : "TEST: включить мок", style: .default) { _ in
      TestMockData.isEnabled.toggle()
    })
    alert.addAction(UIAlertAction(title: "TEST: сбросить к умолчанию", style: .default) { _ in
      TestMockData.resetToDefaults()
    })
    alert.addAction(UIAlertAction(title: "Закрыть", style: .cancel))
    present(alert)
  }
  
  private func presentBalanceInput() {
    let alert = UIAlertController(
      title: "TEST: баланс TON",
      message: "Тестовая сумма, которая прибавляется к реальному балансу. На блокчейне её нет.",
      preferredStyle: .alert
    )
    alert.addTextField { field in
      field.keyboardType = .decimalPad
      field.placeholder = "например 100"
      field.text = self.format(TestMockData.extraTon)
    }
    alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
    alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak alert] _ in
      let raw = alert?.textFields?.first?.text?.replacingOccurrences(of: ",", with: ".") ?? ""
      if let value = Double(raw) {
        TestMockData.extraTon = value
      }
    })
    present(alert)
  }
  
  private func presentGiftInput() {
    let alert = UIAlertController(
      title: "TEST: новый подарок",
      message: "Название тестового NFT. В списке будет префикс [TEST].",
      preferredStyle: .alert
    )
    alert.addTextField { field in
      field.placeholder = "например Plush Pepe"
    }
    alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
    alert.addAction(UIAlertAction(title: "Добавить", style: .default) { [weak alert] _ in
      TestMockData.addGift(name: alert?.textFields?.first?.text)
    })
    present(alert)
  }
  
  // MARK: - Helpers
  
  private func format(_ value: Double) -> String {
    value == value.rounded() ? String(Int64(value)) : String(value)
  }
  
  private func present(_ alert: UIAlertController) {
    guard var top = window?.rootViewController else { return }
    while let presented = top.presentedViewController {
      top = presented
    }
    top.present(alert, animated: true)
  }
}
