import UIKit
import WebKit

final class WebViewController: UIViewController {

    // 与 Android 版一致的白名单后缀
    private static let allowSuffix: [String] = [
        "acfan.com", "acfan.shop", "acfan.pro", "acfansm07.com",
        "ccsnak4i.work", "sy29wrn1.work", "47u3j9k8.work", "ohj0zte6.work",
        "bdjyu9ur.work", "edfj4k9d.work", "byg3e85j.work", "jgdfrpwk.work",
        "czskhb.com", "wosvoj.com", "kgjci.com", "dfgwsx.com", "dcjrsb.com", "eldtbz.com",
        "lugj0kg1.work", "9ucu0vev.work", "3xruzfy3.work"
    ]
    private static let entry = "https://wiu1.ccsnak4i.work"
    private static let dangerous = ["apk", "exe", "sh", "bat", "msi", "dmg", "jar", "scr", "vbs"]

    private var webView: WKWebView!
    private let bar = UIProgressView(progressViewStyle: .bar)
    private var loginInfo: [String: Any]?
    private var toastLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.07, alpha: 1)

        let conf = WKWebViewConfiguration()
        conf.allowsInlineMediaPlayback = false          // 交给原生全屏播放器
        conf.mediaTypesRequiringUserActionForPlayback = []
        conf.preferences.javaScriptCanOpenWindowsAutomatically = false
        if let jsURL = Bundle.main.url(forResource: "clean", withExtension: "js"),
           let js = try? String(contentsOf: jsURL, encoding: .utf8) {
            conf.userContentController.addUserScript(
                WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }

        webView = WKWebView(frame: .zero, configuration: conf)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        // 去掉 wv 标记，避免站点判定为内嵌浏览器
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        bar.progressTintColor = UIColor(red: 0.85, green: 0.25, blue: 0.2, alpha: 1)
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 2)
        ])
        observeProgress()

        refreshLogin { [weak self] in
            guard let self = self else { return }
            if let u = URL(string: Self.entry) { self.webView.load(URLRequest(url: u)) }
        }
    }

    // MARK: - 账号

    private func refreshLogin(_ done: @escaping () -> Void) {
        guard let url = Bundle.main.url(forResource: "account", withExtension: "json"),
              let raw = try? Data(contentsOf: url),
              let obj = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any],
              let acc = obj["account"] as? String,
              let pwd = obj["password"] as? String else { done(); return }

        var req = URLRequest(url: URL(string: Self.entry + "/api/user/v1/public/account/login")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Self.entry, forHTTPHeaderField: "Origin")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["account": acc, "password": pwd])

        URLSession.shared.dataTask(with: req) { data, _, _ in
            var info: [String: Any]?
            if let d = data,
               let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
               (o["code"] as? Int) == 200 {
                info = o["data"] as? [String: Any]
            }
            DispatchQueue.main.async {
                self.loginInfo = info
                done()
            }
        }.resume()
    }

    private func injectLogin() {
        guard let info = loginInfo,
              let d = try? JSONSerialization.data(withJSONObject: info),
              let s = String(data: d, encoding: .utf8) else { return }
        let js = """
        (function(){try{var d=\(s);var tk=d.token||'';
        var ct=localStorage.getItem('token')||sessionStorage.getItem('token')||'';
        if(ct&&localStorage.getItem('userInfo')&&ct===tk)return 'have';
        localStorage.setItem('userInfo',JSON.stringify(d));
        if(tk){localStorage.setItem('token',tk);sessionStorage.setItem('token',tk);}
        setTimeout(function(){location.reload()},100);return 'set';}catch(e){return 'err';}})()
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private var progressObs: NSKeyValueObservation?

    private func observeProgress() {
        progressObs = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
            let p = Float(wv.estimatedProgress)
            self?.bar.setProgress(p, animated: true)
            self?.bar.isHidden = p >= 1.0
        }
    }

    // MARK: - 工具

    private static func allowed(_ host: String) -> Bool {
        let h = host.lowercased()
        return allowSuffix.contains { h == $0 || h.hasSuffix("." + $0) }
    }

    private func toast(_ text: String) {
        toastLabel?.removeFromSuperview()
        let l = UILabel()
        l.text = "  \(text)  "
        l.font = .systemFont(ofSize: 13)
        l.textColor = .white
        l.backgroundColor = UIColor(white: 0, alpha: 0.78)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(l)
        NSLayoutConstraint.activate([
            l.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            l.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            l.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -48)
        ])
        toastLabel = l
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { l.removeFromSuperview() }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }

        guard url.scheme == "http" || url.scheme == "https" else {
            toast("已拦截外部协议跳转")
            decisionHandler(.cancel)
            return
        }
        guard let host = url.host, Self.allowed(host) else {
            toast("已拦截站外跳转")
            decisionHandler(.cancel)
            return
        }
        let ext = url.pathExtension.lowercased()
        if Self.dangerous.contains(ext) {
            toast("已拒绝安装包下载")
            decisionHandler(.cancel)
            return
        }
        if #available(iOS 14.5, *), navigationAction.shouldPerformDownload {
            decisionHandler(.cancel)
            toast("已拦截文件下载")
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        bar.isHidden = true
        injectLogin()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        bar.isHidden = true
    }
}

// MARK: - WKUIDelegate

extension WebViewController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url,
           let h = url.host, Self.allowed(h) {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "好", style: .default) { _ in completionHandler() })
        present(a, animated: true)
    }
}

