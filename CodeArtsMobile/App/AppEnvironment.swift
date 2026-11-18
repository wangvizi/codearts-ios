import SwiftUI
import Combine

final class AppEnvironment: ObservableObject {

    enum Tab: Hashable, CaseIterable {
        case chat
        case workbench
        case settings

        var title: String {
            switch self {
            case .chat: return "对话"
            case .workbench: return "工作台"
            case .settings: return "我的"
            }
        }

        var symbol: String {
            switch self {
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .workbench: return "square.grid.2x2"
            case .settings: return "person.crop.circle"
            }
        }
    }

    @Published var selectedTab: Tab = .chat
    @Published var hasCompletedOnboarding: Bool
    @Published var toast: ToastMessage?

    let engine: CodeArtsWebEngine

    private let defaults: UserDefaults
    private var toastTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: AppStorageKey.onboardingCompleted)
        self.engine = CodeArtsWebEngine()
        engine.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: AppStorageKey.onboardingCompleted)
    }

    func open(_ link: ServiceLink) {
        engine.load(link.url)
        selectedTab = .chat
    }

    func showToast(_ text: String, symbol: String = "checkmark.circle.fill") {
        toastTask?.cancel()
        let message = ToastMessage(text: text, symbol: symbol)
        toast = message
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self?.toast?.id == message.id {
                    self?.toast = nil
                }
            }
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let symbol: String
}

enum AppStorageKey {
    static let onboardingCompleted = "codearts.onboarding.completed"
    static let preferredLanding = "codearts.preferred.landing"
}

struct ServiceLink: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let url: URL
    let tint: Color

    static let all: [ServiceLink] = [
        ServiceLink(
            title: "代码托管",
            subtitle: "仓库、分支与合并请求",
            symbol: "chevron.left.forwardslash.chevron.right",
            url: URL(string: "https://devcloud.cn-north-4.huaweicloud.com/codehub/")!,
            tint: Theme.blue
        ),
        ServiceLink(
            title: "流水线",
            subtitle: "构建与部署任务状态",
            symbol: "arrow.triangle.branch",
            url: URL(string: "https://devcloud.cn-north-4.huaweicloud.com/pipeline/")!,
            tint: Theme.purple
        ),
        ServiceLink(
            title: "代码检查",
            subtitle: "静态扫描与问题清单",
            symbol: "checklist",
            url: URL(string: "https://devcloud.cn-north-4.huaweicloud.com/check/")!,
            tint: Theme.green
        ),
        ServiceLink(
            title: "编译构建",
            subtitle: "构建历史与产物",
            symbol: "hammer",
            url: URL(string: "https://devcloud.cn-north-4.huaweicloud.com/build/")!,
            tint: Theme.orange
        ),
        ServiceLink(
            title: "部署",
            subtitle: "应用发布与回滚",
            symbol: "shippingbox",
            url: URL(string: "https://devcloud.cn-north-4.huaweicloud.com/deploy/")!,
            tint: Theme.teal
        ),
        ServiceLink(
            title: "制品仓库",
            subtitle: "依赖与发布包管理",
            symbol: "archivebox",
            url: URL(string: "https://devcloud.cn-north-4.huaweicloud.com/artifact/")!,
            tint: Theme.pink
        ),
        ServiceLink(
            title: "需求管理",
            subtitle: "项目、工作项与迭代",
            symbol: "list.bullet.rectangle",
            url: URL(string: "https://devcloud.cn-north-4.huaweicloud.com/projectman/")!,
            tint: Theme.indigo
        ),
        ServiceLink(
            title: "测试计划",
            subtitle: "用例、执行与报告",
            symbol: "testtube.2",
            url: URL(string: "https://devcloud.cn-north-4.huaweicloud.com/testplan/")!,
            tint: Theme.brown
        )
    ]
}