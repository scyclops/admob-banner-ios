import GoogleMobileAds
import UIKit

class AMBBannerStackView: UIStackView {
    static let shared = AMBBannerStackView(frame: AMBHelper.window.frame)

    static let bottomConstraint = shared.bottomAnchor.constraint(equalTo: AMBHelper.bottomAnchor, constant: 0)

    lazy var contentView: UIView = {
        let v = UIView(frame: self.frame)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.isUserInteractionEnabled = false
        return v
    }()

    var hasBottomBanner: Bool {
        return self.initialized && self.arrangedSubviews.last is AMBBannerPlaceholder
    }

    var initialized: Bool {
        return !self.arrangedSubviews.isEmpty
    }

    func prepare() {
        if self.initialized {
            return
        }

        self.isUserInteractionEnabled = false
        self.axis = .vertical
        self.distribution = .fill
        self.alignment = .fill
        self.translatesAutoresizingMaskIntoConstraints = false

        self.addArrangedSubview(contentView)
    }
}

class AMBBanner: AMBAdBase, GADBannerViewDelegate, GADAdSizeDelegate {
    static let stackView = AMBBannerStackView.shared

    static let priority10 = UILayoutPriority(10)
    static let priority9 = UILayoutPriority(9)
    // using different priority to try to prevent constraint error crashes

    static var rootObservation: NSKeyValueObservation?

    static var rootView: UIView {
        return AMBContext.plugin.viewController.view!
    }

    static var mainView: UIView {
        return AMBContext.plugin.webView
    }

    static func config(_ ctx: AMBContext) {
        if let bgColor = ctx.optBackgroundColor() {
            Self.rootView.backgroundColor = bgColor
        }
        ctx.resolve()
    }

    private static func prepareStackView() {

        var constraints: [NSLayoutConstraint] = []

        stackView.prepare()
        rootView.insertSubview(stackView, belowSubview: mainView)
        constraints += [
            stackView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
        ]

        mainView.translatesAutoresizingMaskIntoConstraints = false
        let placeholderView = stackView.contentView
        constraints += [
            mainView.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
            mainView.topAnchor.constraint(equalTo: placeholderView.topAnchor),
            mainView.bottomAnchor.constraint(equalTo: placeholderView.bottomAnchor)
        ]

        let constraintTop = stackView.topAnchor.constraint(equalTo: rootView.topAnchor)
        let constraintBottom = stackView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
        constraintTop.priority = priority9
        constraintBottom.priority = priority10
        constraints += [
            constraintBottom,
            constraintTop
        ]
        NSLayoutConstraint.activate(constraints)

        rootObservation = rootView.observe(\.subviews, options: [.old, .new]) { (_, _) in
            updateLayout()
        }
    }

    private static func updateLayout() {
        if rootView.subviews.contains(stackView) {
            AMBBannerStackView.bottomConstraint.isActive = stackView.hasBottomBanner
        }
    }

    let adSize: GADAdSize!
    var bannerView: GADBannerView!
    let placeholder = AMBBannerPlaceholder()

    init(id: String, adUnitId: String, adSize: GADAdSize, adRequest: GADRequest) {
        self.adSize = adSize

        super.init(id: id, adUnitId: adUnitId, adRequest: adRequest)
    }

    convenience init?(_ ctx: AMBContext) {
        guard let id = ctx.optId(),
              let adUnitId = ctx.optAdUnitID()
        else {
            return nil
        }
        self.init(id: id,
                  adUnitId: adUnitId,
                  adSize: ctx.optAdSize(),
                  adRequest: ctx.optGADRequest())
    }

    deinit {
        if bannerView != nil {
            bannerView.delegate = nil
            bannerView.adSizeDelegate = nil
            Self.stackView.removeArrangedSubview(placeholder)
            bannerView.removeFromSuperview()
            bannerView = nil
        }
    }

    override func isLoaded() -> Bool {
        return bannerView != nil
    }

    override func load(_ ctx: AMBContext) {
        if bannerView == nil {
            bannerView = GADBannerView(adSize: self.adSize)
            bannerView.delegate = self
            bannerView.adSizeDelegate = self
            bannerView.rootViewController = plugin.viewController
        }

        bannerView.adUnitID = adUnitId
        bannerView.load(adRequest)

        ctx.resolve()
    }

    override func show(_ ctx: AMBContext) {
        if !Self.stackView.initialized {
            Self.prepareStackView()
            Self.stackView.addArrangedSubview(placeholder)
            Self.rootView.addSubview(bannerView)

            bannerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                placeholder.heightAnchor.constraint(equalTo: bannerView.heightAnchor),
                bannerView.centerXAnchor.constraint(equalTo: placeholder.centerXAnchor),
                bannerView.topAnchor.constraint(equalTo: placeholder.topAnchor),
                bannerView.widthAnchor.constraint(equalTo: placeholder.widthAnchor)
            ])
        }

        if bannerView.isHidden {
            bannerView.isHidden = false
        }

        Self.updateLayout()
        ctx.resolve()
    }

    /*
    func cleanup() {
        if bannerView != nil {
            // hide
            bannerView.isHidden = true
            Self.stackView.removeArrangedSubview(placeholder)
            Self.updateLayout()

            // deinit
            bannerView.delegate = nil
            bannerView.adSizeDelegate = nil
            bannerView.removeFromSuperview()
            bannerView = nil
        }
    }
    */

    override func hide(_ ctx: AMBContext) {
        if bannerView != nil {
            bannerView.isHidden = true
            Self.stackView.removeArrangedSubview(placeholder)
            Self.updateLayout()
        }
        ctx.resolve()
    }

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.emit(AMBEvents.adLoad, [
            "size": [
                "width": bannerView.frame.size.width,
                "height": bannerView.frame.size.height,
                "widthInPixels": round(bannerView.frame.size.width * UIScreen.main.scale),
                "heightInPixels": round(bannerView.frame.size.height * UIScreen.main.scale)
            ]
        ])
        self.emit(AMBEvents.bannerLoad)
        self.emit(AMBEvents.bannerSize, [
            "size": [
                "width": bannerView.frame.size.width,
                "height": bannerView.frame.size.height,
                "widthInPixels": round(bannerView.frame.size.width * UIScreen.main.scale),
                "heightInPixels": round(bannerView.frame.size.height * UIScreen.main.scale)
            ]
        ])
    }

    func bannerView(_ bannerView: GADBannerView,
                    didFailToReceiveAdWithError error: Error) {
        self.emit(AMBEvents.adLoadFail, error)
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        self.emit(AMBEvents.adImpression)
    }

    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        self.emit(AMBEvents.adClick)
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        self.emit(AMBEvents.adShow)
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        self.emit(AMBEvents.adDismiss)
    }

    func adView(_ bannerView: GADBannerView, willChangeAdSizeTo size: GADAdSize) {
        self.emit(AMBEvents.bannerSizeChange, size)
    }
}
