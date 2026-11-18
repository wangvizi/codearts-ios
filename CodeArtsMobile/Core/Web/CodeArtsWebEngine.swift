import Foundation
import WebKit
import UIKit

final class CodeArtsWebEngine: NSObject, ObservableObject {

    static let homeURL = URL(string: "https://devcloud.cn-north-4.huaweicloud.com/chat/")!

    let webView: WKWebView

    @Published private(set) var isLoading = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var pageTitle = "码道"
    @Published private(set) var currentURL: URL?
    @Published var requiresLogin = false
    @Published var errorMessage: String?
    @Published var shareURL: URL?
    @Published var pendingUpload = false
    @Published var statusMessage: String?

    private let downloader = DownloadCoordinator()
    private var observers: [NSKeyValueObservation] = []
    private var didLoadHome = false
    private var pendingPanelHandler: (([URL]?) -> Void)?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let controller = WKUserContentController()
        for script in WebScripts.userScripts() {
            controller.addUserScript(script)
        }
        configuration.userContentController = controller

        self.webView = WKWebView(frame: .zero, configuration: configuration)

        super.init()

        controller.add(WeakScriptMessageHandler(delegate: self), name: "codearts")

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.customUserAgent = Self.userAgent

        installObservers()
        downloader.begin(onFinish: { [weak self] url in
            self?.shareURL = url
            self?.statusMessage = "下载完成：\(url.lastPathComponent)"
        }, onFailure: { [weak self] message in
            self?.statusMessage = "下载失败：\(message)"
        })
    }

    deinit {
        observers.forEach { $0.invalidate() }
    }

    static var userAgent: String {
        let base = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        return base + " CodeArtsMobile/1.0"
    }

    func loadHomeIfNeeded() {
        guard !didLoadHome else { return }
        didLoadHome = true
        load(Self.homeURL)
    }

    func load(_ url: URL) {
        didLoadHome = true
        errorMessage = nil
        webView.load(URLRequest(url: url))
    }

    func reload() {
        errorMessage = nil
        if webView.url == nil {
            load(Self.homeURL)
        } else {
            webView.reload()
        }
    }

    func goBack() {
        guard webView.canGoBack else { return }
        webView.goBack()
    }

    func goForward() {
        guard webView.canGoForward else { return }
        webView.goForward()
    }

    func openInSafari() {
        let target = webView.url ?? Self.homeURL
        UIApplication.shared.open(target)
    }

    func share(_ url: URL?) {
        guard let url else { return }
        shareURL = url
    }

    func chooseUploadFiles() {
        pendingUpload = true
    }

    func completeUpload(with urls: [URL]) {
        pendingUpload = false
        let staged = urls.compactMap(stageFile)
        pendingPanelHandler?(staged.isEmpty ? nil : staged)
        pendingPanelHandler = nil
    }

    func cancelUpload() {
        pendingUpload = false
        pendingPanelHandler?(nil)
        pendingPanelHandler = nil
    }

    func clearWebData(completion: @escaping () -> Void) {
        let store = webView.configuration.websiteDataStore
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        store.removeData(ofTypes: types, modifiedSince: .distantPast) {
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func signOut() {
        clearWebData { [weak self] in
            guard let self else { return }
            self.requiresLogin = false
            self.productSignOutHook()
            self.load(Self.homeURL)
        }
    }

    private func productSignOutHook() {
        didLoadHome = true
    }

    private func stageFile(_ url: URL) -> URL? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("codearts-upload", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    private func installObservers() {
        observers.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.progress = webView.estimatedProgress
        })
        observers.append(webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
            self?.canGoBack = webView.canGoBack
        })
        observers.append(webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
            self?.canGoForward = webView.canGoForward
        })
        observers.append(webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
            self?.currentURL = webView.url
            if let url = webView.url {
                self?.updateAuthState(for: url)
            }
        })
        observers.append(webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
            guard let title = webView.title, !title.isEmpty else { return }
            self?.pageTitle = title
        })
    }

    private func updateAuthState(for url: URL) {
        guard let host = url.host ?? url.absoluteString.removingPercentEncoding, !host.isEmpty else { return }
        let lowercased = host.lowercased()
        if lowercased.contains("auth.huaweicloud.com") || lowercased.contains("account.huaweicloud.com") {
            requiresLogin = true
        } else if lowercased.contains("huaweicloud.com") {
            requiresLogin = false
        }
    }

    private func isInternal(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return true }
        if url.scheme == "about" { return true }
        return host.hasSuffix("huaweicloud.com") || host.hasSuffix("huawei.com")
    }

    private func openExternally(_ url: URL) {
        guard url.scheme == "http" || url.scheme == "https" else { return }
        UIApplication.shared.open(url)
    }
}

extension CodeArtsWebEngine: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        errorMessage = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        progress = 1
        if let url = webView.url {
            currentURL = url
            updateAuthState(for: url)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        handleNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        handleNavigationError(error)
    }

    private func handleNavigationError(_ error: Error) {
        let code = (error as NSError).code
        if code == NSURLErrorCancelled { return }
        errorMessage = "页面加载失败：\(error.localizedDescription)"
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if navigationAction.targetFrame == nil {
            decisionHandler(.cancel)
            webView.load(URLRequest(url: url))
            return
        }

        if isInternal(url) {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            openExternally(url)
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if !navigationResponse.canShowMIMEType {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        downloader.attach(download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        downloader.attach(download)
    }
}

extension CodeArtsWebEngine: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if isInternal(url) {
                webView.load(URLRequest(url: url))
            } else {
                openExternally(url)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView,
                 runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping ([URL]?) -> Void) {
        pendingPanelHandler = completionHandler
        pendingUpload = true
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}

extension CodeArtsWebEngine: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "codearts",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }

        switch type {
        case "login-probe":
            if let href = body["href"] as? String, let url = URL(string: href) {
                updateAuthState(for: url)
            }
            if body["hasLoginForm"] as? Bool == true {
                requiresLogin = true
            }
        case "js-error":
            if let text = body["message"] as? String, !text.isEmpty {
                statusMessage = text
            }
        default:
            break
        }
    }
}