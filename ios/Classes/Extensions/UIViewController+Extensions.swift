import UIKit

extension UIViewController {
    static func topMostViewController() -> UIViewController? {
        var topVc = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow })?.rootViewController

        while let presented = topVc?.presentedViewController {
            topVc = presented
        }

        return topVc
    }
}
