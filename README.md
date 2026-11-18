# 码道 iOS 客户端

面向 **华为云码道 CodeArts 代码智能体** 的第三方 iOS 客户端。原生 SwiftUI 外壳 + WKWebView 承载官方 Web 端，登录走华为云官方登录页，Cookie 持久化在内置浏览器中。

## 先说清楚三件事

1. **码道官方没有安卓 App。**官方形态是 IDE、VS Code / JetBrains 插件、桌面端 Beta、CLI，以及 Web 在线体验（`https://devcloud.cn-north-4.huaweicloud.com/chat/`）。因此不存在“照安卓端移植”的路径，本项目是从零构建的同类型客户端。
2. **码道没有公开的对话 API。**官方未开放“AI 编码对话 / 智能体任务”的 REST 接口，无法用原生请求复刻。要真正用上码道功能，唯一合规可行方式就是在 App 内承载官方 Web 端。
3. **本机环境是 Linux，没有 Xcode。**工程源码完整可用，但编译、签名、模拟器运行必须在 macOS + Xcode 上完成，这里无法代为验证构建结果。

## 已实现能力

| 能力 | 说明 |
| --- | --- |
| 华为云账号登录 | 走官方登录页，账号密码只提交给 `auth.huaweicloud.com`，应用不接触 |
| 登录态持久化 | `WKWebsiteDataStore.default()`，重启 App 仍保持登录 |
| 登录态感知 | 根据 URL / 页面表单检测登录状态，顶部提示条与“我的”页同步 |
| 进度与错误 | 加载进度条、失败页、重试 |
| 文件上传 | 网页触发选择文件时唤起系统文件选择器，先复制到临时目录再上传 |
| 文件下载 | 不可预览的响应自动下载到 Documents，完成后弹出系统分享 |
| 外链处理 | 非华为域链接交给系统 Safari，避免网页被劫持在壳内 |
| 新窗口 | `target=_blank` / `window.open` 在当前 WebView 内展开 |
| 研发工具入口 | 工作台直达代码托管、流水线、代码检查、构建、部署、制品仓库、需求、测试计划 |
| 会话管理 | 退出登录、清除缓存与网页数据 |

## 目录结构

```
CodeArtsMobile/
├── project.yml                        # XcodeGen 工程描述
└── CodeArtsMobile/
    ├── App/
    │   ├── CodeArtsMobileApp.swift     # 入口
    │   └── AppEnvironment.swift        # 全局状态、Tab、服务入口列表
    ├── Core/Web/
    │   ├── CodeArtsWebEngine.swift     # WKWebView 引擎、导航/登录/下载/上传
    │   ├── CodeArtsWebView.swift       # SwiftUI 包装 + 分享面板
    │   ├── DownloadCoordinator.swift   # WKDownloadDelegate
    │   ├── WebScripts.swift            # 注入脚本
    │   └── WeakScriptMessageHandler.swift
    ├── DesignSystem/Theme.swift        # 配色、卡片、行、Toast
    ├── Features/
    │   ├── Root/RootView.swift         # 引导页 / 主 Tab
    │   ├── Onboarding/OnboardingView.swift
    │   ├── Chat/ChatScreen.swift       # 对话页（WebView 主体）
    │   ├── Workbench/WorkbenchScreen.swift
    │   └── Settings/SettingsScreen.swift
    └── Resources/
        ├── Info.plist
        └── Assets.xcassets
```

## 构建步骤（在 macOS 上）

### 方式一：XcodeGen（推荐）

```bash
brew install xcodegen
cd CodeArtsMobile
xcodegen generate
open CodeArtsMobile.xcodeproj
```

在 Xcode 中选择你的开发者 Team，选中模拟器或真机运行。

### 方式二：手动新建工程

1. Xcode → File → New → Project → iOS App，名称 `CodeArtsMobile`，界面 SwiftUI，语言 Swift，最低版本 iOS 16.0。
2. 删除自动生成的 `ContentView.swift` 与 `<Name>App.swift`。
3. 把本仓库 `CodeArtsMobile/CodeArtsMobile/` 下所有 `.swift` 与 `Resources/Assets.xcassets` 拖入工程（勾选 Copy items if needed、Create groups）。
4. 用本仓库的 `Resources/Info.plist` 替换工程的 Info.plist，或在 Target → Info 中补齐 `NSPhotoLibraryUsageDescription`、`NSCameraUsageDescription`、`NSMicrophoneUsageDescription`。
5. Target → General → Minimum Deployments 设为 iOS 16.0。

## 运行后怎么用

1. 首次启动看完三页引导 → 进入“对话”。
2. 页面会重定向到华为云登录页，输入华为云账号（若已升级为华为账号，请使用为该账号创建的 IAM 用户登录）。
3. 登录后回到 `/chat/`，即可正常进行码道对话。
4. “工作台”里的卡片会把你带到对应 DevCloud 控制台页面。
5. “我的”可以退出登录、清除缓存、切到 Safari 打开。

## 已知限制

- **依赖官方 Web 页面。**华为调整 `devcloud` 域名、路径或增加页面对 WebView 的限制（例如 UA 校验、设备指纹、验证码风控）时，需要同步跟进。
- **工作台路径是控制台地址。**DevCloud 控制台改版后，卡片 URL 可能需要更新（集中在 `AppEnvironment.swift` 的 `ServiceLink.all`）。
- **无法调用原生码道 API。**因为没有公开接口，所以不存在“离线对话”“原生任务列表”这类能力。
- **未做推送。**华为云未提供移动端推送接口，长任务完成通知需要轮询或后续自建服务端中转。

## 合规边界（重要）

- 仅建议**自用或团队内部测试分发**。
- 若要上架 App Store，会面临两条审核风险：Guideline 4.2（最小功能，纯网页壳容易被拒）与 Guideline 5.2（使用他人品牌/服务内容）。届时应改为原生功能占主导，或取得华为云书面授权。
- 请勿在 App 内自行实现华为云账号密码提交逻辑、抓取 Cookie 外传或绕过官方登录风控。

## 后续可扩展方向

1. 若华为云后续开放码道 API，可新增网络层替换 WebView 承载，实现纯原生对话。
2. 增加“最近会话”本地书签（基于 URL 记录，不涉及数据抓取）。
3. 支持 iPad 分栏：左侧会话列表 + 右侧 WebView。
4. 增加长任务轮询 + 本地通知（需服务端中转，见上）。