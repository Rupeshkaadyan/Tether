import Foundation

// MARK: - Legal
//
// Every URL the app must be able to show a reviewer, in one place.
//
// Apple requires the privacy policy to be reachable from inside the app
// (5.1.1(i)) as well as from the store listing, and a subscription app has to
// make the terms and the cancellation path easy to find (3.1.2). Keeping them
// here means a reviewer can find them, and so can anyone reading the code.

enum Legal {

    /// Hosted from the repository.
    ///
    /// NOTE: `raw.githubusercontent.com` serves this as plain text, so it is
    /// readable but unstyled. Turning on GitHub Pages for the repo gives
    /// `https://rupeshkaadyan.github.io/Tether/privacy.html`, which renders
    /// properly — worth switching to before submission. Either way the URL must
    /// also be entered in App Store Connect, and both must point at the same
    /// document.
    static let privacyPolicy = URL(string:
        "https://raw.githubusercontent.com/Rupeshkaadyan/Tether/main/docs/privacy.html")!

    /// Apple's standard EULA applies unless a custom one is supplied. Linking
    /// to it is honest: it is the agreement the person is actually accepting.
    static let subscriptionTerms = URL(string:
        "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// Where a subscription is actually cancelled. Sending someone to Settings
    /// in the abstract is how you get "I could not find how to cancel" reviews.
    static let manageSubscriptions = URL(string:
        "https://apps.apple.com/account/subscriptions")!

    /// Shown under the paywall's buy button, as required for auto-renewables.
    static let renewalDisclosure = """
        Payment is charged to your Apple Account at confirmation. The \
        subscription renews automatically unless cancelled at least 24 hours \
        before the period ends. Manage or cancel it in your Apple Account \
        settings.
        """
}
