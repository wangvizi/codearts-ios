import Foundation
import WebKit

enum WebScripts {

    static let userAgentScript = """
    (function () {
      if (window.__codeartsHostBridgeInstalled) { return; }
      window.__codeartsHostBridgeInstalled = true;

      function post(payload) {
        try {
          window.webkit.messageHandlers.codearts.postMessage(payload);
        } catch (e) {}
      }

      window.addEventListener('error', function (event) {
        post({ type: 'js-error', message: String(event.message || '') });
      });

      document.addEventListener('click', function (event) {
        var anchor = event.target && event.target.closest ? event.target.closest('a') : null;
        if (!anchor) { return; }
        var href = anchor.getAttribute('href');
        if (!href) { return; }
        post({ type: 'link', href: href, text: (anchor.innerText || '').slice(0, 80) });
      }, true);

      post({ type: 'ready', platform: 'ios', userAgent: navigator.userAgent });
    })();
    """

    static let loginProbeScript = """
    (function () {
      var ready = document.readyState;
      var href = location.href;
      var hasLoginForm = !!document.querySelector('input[type="password"]');
      window.webkit.messageHandlers.codearts.postMessage({
        type: 'login-probe',
        href: href,
        readyState: ready,
        hasLoginForm: hasLoginForm
      });
    })();
    """

    static func userScripts() -> [WKUserScript] {
        [
            WKUserScript(source: userAgentScript, injectionTime: .atDocumentStart, forMainFrameOnly: false),
            WKUserScript(source: loginProbeScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        ]
    }
}