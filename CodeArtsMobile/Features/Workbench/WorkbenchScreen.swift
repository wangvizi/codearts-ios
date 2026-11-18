import SwiftUI

struct WorkbenchScreen: View {
    @EnvironmentObject private var app: AppEnvironment

    private let columns = [GridItem(.adaptive(minimum: 156), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("研发工具")
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ServiceLink.all) { link in
                                Button {
                                    app.open(link)
                                } label: {
                                    ServiceCard(link: link)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    disclaimer
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("工作台")
        }
    }

    private var statusCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(app.engine.requiresLogin ? Theme.orange : Theme.green)
                        .frame(width: 8, height: 8)

                    Text(app.engine.requiresLogin ? "未登录" : "已连接码道")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(app.engine.requiresLogin ? "登录华为云账号后即可使用全部功能" : "可以直接开始对话，或进入下面的研发工具")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    app.selectedTab = .chat
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                        Text("打开码道对话")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var disclaimer: some View {
        Text("以上入口会打开华为云 DevCloud 控制台页面，功能与网页端保持一致；若页面结构调整，入口可能需要更新。")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.top, 4)
    }
}

private struct ServiceCard: View {
    let link: ServiceLink

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: link.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(link.tint)
                .frame(width: 38, height: 38)
                .background(link.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(link.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(link.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}