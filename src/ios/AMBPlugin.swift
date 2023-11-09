
import GoogleMobileAds

@objc(AMBPlugin)
class AMBPlugin: CDVPlugin {

    var readyCallbackId: String!

    deinit {
        readyCallbackId = nil
    }

    override func pluginInitialize() {
        super.pluginInitialize()

        AMBContext.plugin = self

        if let x = self.commandDelegate.settings["disableSDKCrashReporting".lowercased()] as? String,
           x == "true" {
            GADMobileAds.sharedInstance().disableSDKCrashReporting()
        }
    }

    @objc func ready(_ command: CDVInvokedUrlCommand) {
        readyCallbackId = command.callbackId

        DispatchQueue.global(qos: .background).async {
            self.emit(AMBEvents.ready, data: ["isRunningInTestLab": false])
        }
    }

    @objc func configure(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        ctx.configure()
    }

    @objc func configRequest(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        let requestConfiguration = GADMobileAds.sharedInstance().requestConfiguration

        if let maxAdContentRating = ctx.optMaxAdContentRating() {
            requestConfiguration.maxAdContentRating = maxAdContentRating
        }

        if let tag = ctx.optChildDirectedTreatmentTag() {
            requestConfiguration.tag(forChildDirectedTreatment: tag)
        }

        if let tag = ctx.optUnderAgeOfConsentTag() {
            requestConfiguration.tagForUnderAge(ofConsent: tag)
        }

        if let testDevices = ctx.optTestDeviceIds() {
            requestConfiguration.testDeviceIdentifiers = testDevices
        }

        ctx.resolve()
    }

    @objc func start(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)

        GADMobileAds.sharedInstance().start(completionHandler: { _ in
            ctx.resolve(["version": GADMobileAds.sharedInstance().sdkVersion])
        })
    }

    @objc func adCreate(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)

        DispatchQueue.main.async {
            var ad: AMBCoreAd? = ctx.optAd()
            // i think the root of the problem is that data on the javascript side is getting cleared
            // and the javascript erroneously assumes it's data is valid
            // so it re-runs adCreate/adLoad/adShow when it really doesn't need to do anything
            // and we can't fix the javascript side if the javascript data can't be trusted
            // but making adCreate/adLoad/adShow do nothing when the ad already exists should also work 
            //
            // reference: https://github.com/admob-plus/admob-plus/issues/450#issuecomment-967061492
            // 
            // but if reusing the ad doesn't work, try the below to recreate it
            // (making sure to uncomment both cleanup definition)
            /*
            if let oldAd = ctx.optAd() as? AMBAdBase {
                oldAd.cleanup()
            }
            ad = AMBBanner(ctx)
            */

            if ad == nil {
                ad = AMBBanner(ctx)
            }

            if ad != nil {
                ctx.resolve()
            } else {
                ctx.reject("fail to create ad: \(ctx.optId() ?? "-")")
            }
        }
    }

    @objc func adIsLoaded(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)

        DispatchQueue.main.async {
            if let ad = ctx.optAdOrError() as? AMBAdBase {
                ctx.resolve(ad.isLoaded())
            }
        }
    }

    @objc func adLoad(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)

        DispatchQueue.main.async {
            if let ad = ctx.optAdOrError() as? AMBAdBase {
                ad.load(ctx)
            }
        }
    }

    @objc func adShow(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)

        DispatchQueue.main.async {
            if let ad = ctx.optAdOrError() as? AMBAdBase {
                if ad.isLoaded() {
                    ad.show(ctx)
                    ctx.resolve(true)
                } else {
                    ctx.resolve(false)
                }
            }
        }
    }

    @objc func adHide(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)

        DispatchQueue.main.async {
            if let ad = ctx.optAdOrError() as? AMBAdBase {
                ad.hide(ctx)
            }
        }
    }

    @objc func bannerConfig(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)

        DispatchQueue.main.async {
            AMBBanner.config(ctx)
        }
    }

    func emit(_ eventName: String, data: Any = NSNull()) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["type": eventName, "data": data])
        result?.setKeepCallbackAs(true)
        self.commandDelegate.send(result, callbackId: readyCallbackId)
    }

}
