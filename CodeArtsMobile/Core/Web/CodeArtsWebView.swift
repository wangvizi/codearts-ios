import SwiftUI
import UIKit
import WebKit

struct CodeArtsWebView: UIViewRepresentable {

    let engine: CodeArtsWebEngine

    func makeUIView(context: Context) -> WKWebView {
        engine.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}