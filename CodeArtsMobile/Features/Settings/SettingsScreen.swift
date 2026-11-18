import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var showsSignOutConfirm = false
    @State private var showsClearConfirm = false

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    accountCard
                    generalCard
                    aboutCard
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("我的")
            .confirmationDialog("退出登录将清除本机保存的登录状态", isPresented: $showsSignOutConfirm, titleVisibility: .visible) {
                Button("退出登录", role: .destructive) {
                    app.engine.signOut()
                    app.showToast("已退出登录", symbol: "rectangle.portrait.and.arrow.right")
                }
                Button("取消", role: .cancel) {}
            }
            .confirmationDialog("将清除缓存与网页数据，登录状态也会丢失", isPresented: $showsClearConfirm, titleVisibility: .visible) {
                Button("清除全部数据", role: .destructive) {
                    app.engine.signOut()
                    app.showToast("已清除本地数据", symbol: "trash")
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private var accountCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Theme.accent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.engine.requiresLogin ? "未登录" : "已登录华为云账号")
                            .font(.headline)

                        Text(app.engine.currentURL?.host ?? "devcloud.cn-north-4.huaweicloud.com")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }

                if app.engine.requiresLogin {
                    Button {
                        app.selectedTab = .chat
                        app.engine.loadHomeIfNeeded()
                    } label: {
                        Text("去登录")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                            .foregroundStyle(.white)
                    }
                } else {
                    Button {
                        showsSignOutConfirm = true
                    } label: {
                        Text("退出登录")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private var generalCard: some View {
        CardContainer {
            VStack(spacing: 0) {
                Button {
                    app.engine.reload()
                    app.showToast("正在重新加载", symbol: "arrow.clockwise")
                } label: {
                    SettingRow(symbol: "arrow.clockwise", title: "重新加载页面", showsChevron: false)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 40)

                Button {
                    app.selectedTab = .chat
                    app.engine.chooseUploadFiles()
                } label: {
                    SettingRow(symbol: "paperclip", title: "上传文件到对话", showsChevron: false)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 40)

                Button {
                    app.engine.openInSafari()
                } label: {
                    SettingRow(symbol: "safari", title: "在 Safari 中打开", showsChevron: false)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 40)

                Button {
                    showsClearConfirm = true
                } label: {
                    SettingRow(symbol: "trash", title: "清除缓存与登录数据", tint: .red, showsChevron: false)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var aboutCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("版本")
                        .font(.subheadline)
                    Spacer()
                    Text(version)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("关于本应用")
                        .font(.subheadline.weight(.semibold))

                    Text("本应用是面向华为云码道 CodeArts 代码智能体的第三方 iOS 客户端外壳，通过内置浏览器加载官方 Web 端提供服务。应用本身不存储账号密码，不采集对话内容。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("免责声明")
                        .font(.subheadline.weight(.semibold))

                    Text("本应用与华为云官方无隶属关系。使用过程中产生的数据、额度与账号权益以华为云官方条款为准。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }
        }
    }
}