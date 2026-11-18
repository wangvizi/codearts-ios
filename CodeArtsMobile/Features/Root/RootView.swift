import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppEnvironment

    var body: some View {
        Group {
            if app.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = app.toast {
                ToastView(message: toast)
                    .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.86), value: app.toast)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var app: AppEnvironment

    var body: some View {
        TabView(selection: $app.selectedTab) {
            ChatScreen()
                .tag(AppEnvironment.Tab.chat)
                .tabItem {
                    Label(AppEnvironment.Tab.chat.title, systemImage: AppEnvironment.Tab.chat.symbol)
                }

            WorkbenchScreen()
                .tag(AppEnvironment.Tab.workbench)
                .tabItem {
                    Label(AppEnvironment.Tab.workbench.title, systemImage: AppEnvironment.Tab.workbench.symbol)
                }

            SettingsScreen()
                .tag(AppEnvironment.Tab.settings)
                .tabItem {
                    Label(AppEnvironment.Tab.settings.title, systemImage: AppEnvironment.Tab.settings.symbol)
                }
        }
    }
}