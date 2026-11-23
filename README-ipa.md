# oz真神了 · iOS 工程（可编译出 .ipa）

## 先说清楚：现成的 .ipa 没有

- 官方 acfan 客户端只在 Telegram 分发 **Android APK**，没有公开的 iOS 包
- iOS 的 .ipa 编译器（Xcode / clang + iOS SDK）**只在 macOS 上运行**，当前这台是 Windows，本地产不出二进制
- 就算拿到未签名 .ipa，iOS 也强制要求签名才能安装

所以这里交付的是**能产出 ipa 的完整工程**，不是 ipa 本身。

## 工程内容

```
ios-app/
├── project.yml                  XcodeGen 工程描述（一条命令生成 .xcodeproj）
├── Sources/
│   ├── AppDelegate.swift        入口
│   ├── WebViewController.swift  WKWebView 壳（229 行）
│   ├── clean.js                 净化层，与 Android 版同一份
│   ├── account.json             预置账号（启动自动登录）
│   └── Assets.xcassets/AppIcon  11 个尺寸，学习通图标
└── .github/workflows/ios.yml   云端构建，直接出 oz-unsigned.ipa
```

功能对齐 Android 版：去广告、外链去毒、域名白名单、开箱即登录、全屏视频（原生播放器接管）、站外跳转拦截、下载拦截。

## 三条出 ipa 的路

### 路线 A：有 Mac（最快）

```bash
brew install xcodegen
cd ios-app && xcodegen generate
open oz.xcodeproj          # Xcode 里选自己设备，直接 Run
```

要 ipa 文件：

```bash
xcodebuild -project oz.xcodeproj -scheme oz -sdk iphoneos -configuration Release \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath build
mkdir -p Payload && cp -R build/Build/Products/Release-iphoneos/oz.app Payload/
zip -qry oz-unsigned.ipa Payload
```

### 路线 B：没有 Mac，用 GitHub Actions

把 `ios-app` 推到一个 GitHub 仓库，Actions 里手动跑 `build-ios-ipa`，几分钟后在 Artifacts 里下载 **oz-unsigned.ipa**（macOS runner 免费额度够用）。

### 路线 C：拿到 ipa 后自签安装

未签名 ipa 需要现场签名才能装进 iPhone：

| 工具 | 平台 | 说明 |
|---|---|---|
| Sideloadly | Win / Mac | 填 Apple ID，自动签，免费证书 7 天到期需重签 |
| AltStore | Win / Mac | 同上，支持后台自动续签（需常连同一 WiFi） |
| 爱思助手 | Win | 国内最省事，一键签名安装 |
| Apple 开发者账号 | — | $99/年，证书 1 年，可长期使用 |

签名时 Bundle ID 保持 `com.yg.oz` 或改成你自己账号下唯一的名字。

## 与 Android 版的差异

| | Android (v1.10) | iOS 工程 |
|---|---|---|
| 去广告注入 | `shouldInterceptRequest` + evaluateJavascript | `WKUserScript` atDocumentStart（更早、更稳） |
| 域名白名单 | 请求层 204 拦截 | `decidePolicyFor` 取消导航 |
| 登录注入 | SharedPreferences + 启动刷新 | 内存 + didFinish 注入 localStorage |
| 全屏视频 | onShowCustomView | `allowsInlineMediaPlayback = false` 交给系统播放器 |
| 下载 | DownloadManager + 确认弹窗 | 危险扩展名直接拒绝 |
| 图标 | 单张 192 | 11 个尺寸全套 |

## 已知限制

- 未签名工程无法在 Windows 上验证编译；Swift 代码按 iOS 13+ SDK 编写，首次在 Xcode 打开可能需要处理签名团队（Team）设置
- 站点换域名后，改 `WebViewController.swift` 里的 `entry` 常量与 `allowSuffix` 数组

---

## 本机为什么产不出 ipa（硬边界）

| 需要 | 现状 |
|---|---|
| iOS 编译器（Xcode / clang + iOS SDK） | 只在 macOS 上运行，本机是 Windows |
| 云端构建入口 | GitHub Actions 需要账号 token，本机无凭据 |
| 现成可改造的壳 ipa | PakePlus-iOS 仓库无 release，其它壳工程也无预编译 ipa |

不是藏私，是这三条路当前都断。下面两条脚本已经替你把路修到只剩「跑一条命令」。

## 路线 A：有 Mac（5 分钟）

```bash
cd ios-app && bash build-ipa.sh
```

产出 `oz-unsigned.ipa`，再签名安装。

## 路线 B：没有 Mac，但有 GitHub 账号（10 分钟）

```bash
GH_TOKEN=ghp_xxx bash push-and-build.sh oz-ios
```

脚本会自动建**私有**仓库、推送、触发 macOS runner，跑完在 Actions → Artifacts 里下 ipa。

## 签名安装（两条路之后都要做）

未签名 ipa 直接拖进 iPhone 会失败，需要现场签：

| 工具 | 平台 | 证书有效期 |
|---|---|---|
| Sideloadly | Win / Mac | 免费 Apple ID，7 天 |
| 爱思助手 | Win | 同上，一键签 |
| AltStore | Win / Mac | 同上，可后台自动续签 |
| 开发者账号 | — | 99 美元/年，1 年 |

## 如果只是想现在就用上

`oz真神了.mobileconfig`（上一轮那份）装完桌面就有图标、全屏运行，五分钟完成，不需要签名、不需要 Mac。真要 ipa 的场合（比如给别人分发），再走上面两条。
