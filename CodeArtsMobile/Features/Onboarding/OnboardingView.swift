import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "sparkles",
            title: "码道，装进 iPhone",
            subtitle: "把华为云码道代码智能体带到手机上。随时随地继续对话，随时查看任务进展。",
            tint: Theme.accent
        ),
        OnboardingPage(
            symbol: "person.badge.key",
            title: "用华为云账号登录",
            subtitle: "登录过程与浏览器完全一致，账号密码只提交给华为云官方登录页，不会经过本应用。",
            tint: Theme.green
        ),
        OnboardingPage(
            symbol: "square.grid.2x2",
            title: "研发工具一站直达",
            subtitle: "代码托管、流水线、代码检查、部署，在工作台一键进入对应控制台页面。",
            tint: Theme.purple
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardingCard(page: item)
                        .tag(index)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button {
                    if page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            page += 1
                        }
                    } else {
                        app.completeOnboarding()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "继续" : "开始使用")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                        .foregroundStyle(.white)
                }

                Button("跳过") {
                    app.completeOnboarding()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let subtitle: String
    let tint: Color
}

private struct OnboardingCard: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.symbol)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(page.tint)
                .frame(width: 140, height: 140)
                .background(page.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 40, style: .continuous))

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            Text("本应用由第三方开发，与华为云官方无隶属关系。")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
    }
}