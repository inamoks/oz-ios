import UIKit
import WebKit
import AVKit

final class WebViewController: UIViewController {

    private static let entries = [
        "https://wiu1.ccsnak4i.work",
        "https://765dmf.bdjyu9ur.work",
        "https://acfansm07.com"
    ]
    private static let allowSuffix: [String] = [
        "acfan.com", "acfan.shop", "acfan.pro", "acfansm07.com",
        "ccsnak4i.work", "sy29wrn1.work", "47u3j9k8.work", "ohj0zte6.work",
        "bdjyu9ur.work", "edfj4k9d.work", "byg3e85j.work", "jgdfrpwk.work",
        "czskhb.com", "wosvoj.com", "kgjci.com", "dfgwsx.com", "dcjrsb.com", "eldtbz.com",
        "lugj0kg1.work", "9ucu0vev.work", "3xruzfy3.work"
    ]
    private static let dangerous = ["apk", "exe", "sh", "bat", "msi", "dmg", "jar", "scr", "vbs"]

    private var webView: WKWebView!
    private var bar: UIProgressView!
    private var errorBox: UIView?
    private var errorLabel: UILabel?
    private var entryIndex = 0
    private var loginInfo: [String: Any]?
    private var progressObs: NSKeyValueObservation?
    private var nativePlayDone = false

    private var currentEntry: String { Self.entries[min(entryIndex, Self.entries.count - 1)] }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.07, alpha: 1)

        let conf = WKWebViewConfiguration()
        conf.allowsInlineMediaPlayback = true
        conf.mediaTypesRequiringUserActionForPlayback = []
        if let jsURL = Bundle.main.url(forResource: "clean", withExtension: "js"),
           let js = try? String(contentsOf: jsURL, encoding: .utf8) {
            conf.userContentController.addUserScript(
                WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }

        webView = WKWebView(frame: .zero, configuration: conf)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        bar = UIProgressView(progressViewStyle: .bar)
        bar.progressTintColor = UIColor(red: 0.85, green: 0.25, blue: 0.2, alpha: 1)
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 2)
        ])
        progressObs = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
            let p = Float(wv.estimatedProgress)
            self?.bar.setProgress(p, animated: true)
            self?.bar.isHidden = p >= 1.0
        }

        loadEntry()
    }

    // MARK: - 加载与线路

    private func loadEntry() {
        nativePlayDone = false
        hideError()
        guard let u = URL(string: currentEntry) else { return }
        webView.load(URLRequest(url: u))
        refreshLogin { [weak self] in self?.injectLogin() }
    }

    private func nextEntry() {
        entryIndex = (entryIndex + 1) % Self.entries.count
        loadEntry()
    }

    private func showError(_ text: String) {
        DispatchQueue.main.async {
            if self.errorBox != nil { self.errorLabel?.text = text; return }
            let box = UIView()
            box.backgroundColor = UIColor(white: 0.1, alpha: 1)
            box.translatesAutoresizingMaskIntoConstraints = false
            let title = UILabel()
            title.text = "页面没打开"
            title.textColor = .white
            title.font = .boldSystemFont(ofSize: 20)
            title.translatesAutoresizingMaskIntoConstraints = false
            let label = UILabel()
            label.text = text
            label.textColor = UIColor(white: 0.75, alpha: 1)
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 13)
            label.translatesAutoresizingMaskIntoConstraints = false
            let retry = UIButton(type: .system)
            retry.setTitle("重新加载", for: .normal)
            retry.setTitleColor(.white, for: .normal)
            retry.backgroundColor = UIColor(red: 0.85, green: 0.25, blue: 0.2, alpha: 1)
            retry.layer.cornerRadius = 8
            retry.translatesAutoresizingMaskIntoConstraints = false
            retry.addTarget(self, action: #selector(self.onRetry), for: .touchUpInside)
            let switchLine = UIButton(type: .system)
            switchLine.setTitle("换一条线路", for: .normal)
            switchLine.setTitleColor(.white, for: .normal)
            switchLine.backgroundColor = UIColor(white: 0.25, alpha: 1)
            switchLine.layer.cornerRadius = 8
            switchLine.translatesAutoresizingMaskIntoConstraints = false
            switchLine.addTarget(self, action: #selector(self.onSwitch), for: .touchUpInside)

            box.addSubview(title); box.addSubview(label); box.addSubview(retry); box.addSubview(switchLine)
            self.view.addSubview(box)
            NSLayoutConstraint.activate([
                box.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                box.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                box.topAnchor.constraint(equalTo: self.view.topAnchor),
                box.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                title.centerXAnchor.constraint(equalTo: box.centerXAnchor),
                title.topAnchor.constraint(equalTo: box.safeAreaLayoutGuide.topAnchor, constant: 120),
                label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 28),
                label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -28),
                label.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 14),
                retry.centerXAnchor.constraint(equalTo: box.centerXAnchor),
                retry.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 26),
                retry.widthAnchor.constraint(equalToConstant: 180),
                retry.heightAnchor.constraint(equalToConstant: 44),
                switchLine.centerXAnchor.constraint(equalTo: box.centerXAnchor),
                switchLine.topAnchor.constraint(equalTo: retry.bottomAnchor, constant: 12),
                switchLine.widthAnchor.constraint(equalToConstant: 180),
                switchLine.heightAnchor.constraint(equalToConstant: 44)
            ])
            self.errorBox = box
            self.errorLabel = label
        }
    }

    private func hideError() {
        DispatchQueue.main.async {
            self.errorBox?.removeFromSuperview()
            self.errorBox = nil
            self.errorLabel = nil
        }
    }

    @objc private func onRetry() { loadEntry() }
    @objc private func onSwitch() { nextEntry() }

    // MARK: - 账号

    private func refreshLogin(_ done: @escaping () -> Void) {
        guard let url = Bundle.main.url(forResource: "account", withExtension: "json"),
              let raw = try? Data(contentsOf: url),
              let obj = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any],
              let acc = obj["account"] as? String, !acc.isEmpty,
              let pwd = obj["password"] as? String else { done(); return }

        var req = URLRequest(url: URL(string: currentEntry + "/api/user/v1/public/account/login")!)
        req.httpMethod = "POST"
        req.timeoutInterval = 12
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(currentEntry, forHTTPHeaderField: "Origin")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["account": acc, "password": pwd])

        URLSession.shared.dataTask(with: req) { data, _, _ in
            var info: [String: Any]?
            if let d = data,
               let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
               (o["code"] as? Int) == 200 {
                info = o["data"] as? [String: Any]
            }
            DispatchQueue.main.async { self.loginInfo = info; done() }
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
        setTimeout(function(){location.reload()},120);return 'set';}catch(e){return 'err';}})()
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - 原生播放兜底

    private func tryNativePlay() {
        guard !nativePlayDone else { return }
        if !webView.url!.path.hasPrefix("/play/") { return }
        let js = """
        (function(){var h=document.documentElement.innerHTML;
        var m=h.match(/"([a-z0-9]{2,6}\/[^"]{8,140}\.m3u8)"/i);
        var a=h.match(/"([0-9]{10}-[0-9a-f]{16,}-[^"]{0,140})"/);
        return JSON.stringify({p:m?m[1]:"",k:a?a[1]:""});})()
        """
        webView.evaluateJavaScript(js) { [weak self] res, _ in
            guard let self = self, let s = res as? String,
                  let d = s.data(using: .utf8),
                  let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
                  let p = o["p"] as? String, !p.isEmpty else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.webView.evaluateJavaScript("(function(){var v=document.querySelector('video');return v&&v.readyState>0?1:0})()") { r, _ in
                    let ready = (r as? NSNumber)?.intValue ?? 0
                    if ready == 1 { return }
                    self.playNative(path: p, key: o["k"] as? String ?? "")
                }
            }
        }
    }

    private func playNative(path: String, key: String) {
        guard !nativePlayDone else { return }
        var urlStr = currentEntry + "/api/m3u8/public/decode/authPath?path=" + (path.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? path)
        if !key.isEmpty {
            urlStr += "&auth_key=" + (key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
        }
        guard let u = URL(string: urlStr) else { return }
        nativePlayDone = true
        let player = AVPlayer(url: u)
        let vc = AVPlayerViewController()
        vc.player = player
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true) { player.play() }
    }

    // MARK: - 导航

    private static func allowed(_ host: String) -> Bool {
        let h = host.lowercased()
        return allowSuffix.contains { h == $0 || h.hasSuffix("." + $0) }
    }
}

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
        guard url.scheme == "http" || url.scheme == "https" else { decisionHandler(.cancel); return }
        guard let host = url.host, Self.allowed(host) else { decisionHandler(.cancel); return }
        if Self.dangerous.contains(url.pathExtension.lowercased()) { decisionHandler(.cancel); return }
        if #available(iOS 14.5, *), navigationAction.shouldPerformDownload {
            decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        nativePlayDone = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        bar.isHidden = true
        injectLogin()
        tryNativePlay()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        bar.isHidden = true
        showError(error.localizedDescription + "\n\n" + currentEntry)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        bar.isHidden = true
        showError(error.localizedDescription + "\n\n" + currentEntry)
    }
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, let h = url.host, Self.allowed(h) {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
