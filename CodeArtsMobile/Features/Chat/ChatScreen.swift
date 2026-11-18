import SwiftUI
import UniformTypeIdentifiers

struct ChatScreen: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var isFileImporterPresented = false
    @State private var showsShareSheet = false

    private var engine: CodeArtsWebEngine {
        app.engine
    }

    var body: some View {
        NavigationStack {
            WebSurface(engine: engine)
                .navigationTitle(engine.pageTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            engine.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!engine.canGoBack)
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            engine.reload()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }

                        Menu {
                            Button {
                                showsShareSheet = true
                            } label: {
                                Label("分享当前页面", systemImage: "square.and.arrow.up")
                            }

                            Button {
                                engine.chooseUploadFiles()
                            } label: {
                                Label("上传文件", systemImage: "paperclip")
                            }

                            Button {
                                engine.openInSafari()
                            } label: {
                                Label("在 Safari 中打开", systemImage: "safari")
                            }

                            Divider()

                            Button {
                                engine.signOut()
                                app.showToast("已退出登录", symbol: "rectangle.portrait.and.arrow.right")
                            } label: {
                                Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
        }
        .onAppear {
            engine.loadHomeIfNeeded()
            if engine.pendingUpload {
                isFileImporterPresented = true
            }
        }
        .onChange(of: engine.pendingUpload) { isPending in
            if isPending {
                isFileImporterPresented = true
            }
        }
        .onChange(of: isFileImporterPresented) { isPresented in
            if !isPresented && engine.pendingUpload {
                engine.cancelUpload()
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.item, .image, .text, .sourceCode, .data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                engine.completeUpload(with: urls)
            case .failure:
                engine.cancelUpload()
            }
        }
        .sheet(isPresented: $showsShareSheet) {
            ActivityShareSheet(items: [engine.webView.url ?? CodeArtsWebEngine.homeURL])
                .presentationDetents([.medium, .large])
        }
    }
}

private struct WebSurface: View {
    @ObservedObject var engine: CodeArtsWebEngine

    init(engine: CodeArtsWebEngine) {
        _engine = ObservedObject(initialValue: engine)
    }

    var body: some View {
        ZStack(alignment: .top) {
            CodeArtsWebView(engine: engine)

            if engine.isLoading {
                ProgressView(value: engine.progress)
                    .progressViewStyle(.linear)
                    .frame(height: 2)
                    .tint(Theme.accent)
            }

            if engine.requiresLogin {
                LoginBanner {
                    engine.loadHomeIfNeeded()
                    engine.reload()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let message = engine.errorMessage {
                ErrorOverlay(message: message) {
                    engine.reload()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: engine.requiresLogin)
        .animation(.easeInOut(duration: 0.2), value: engine.errorMessage)
    }
}

private struct LoginBanner: View {
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.badge.key")
                .foregroundStyle(Theme.accent)

            Text("请在下方使用华为云账号登录")
                .font(.footnote.weight(.medium))
                .lineLimit(1)

            Spacer(minLength: 4)

            Button("重试", action: onRetry)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

private struct ErrorOverlay: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 52))
                    .foregroundStyle(.secondary)

                Text("暂时无法加载")
                    .font(.title3.bold())

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    onRetry()
                } label: {
                    Text("重新加载")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }
}