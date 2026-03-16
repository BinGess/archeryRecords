import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var archeryStore: ArcheryStore
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showLanguageSelector = false
    @State private var showMailView = false
    @State private var activePaywallFeature: ProFeature?
    #if canImport(MessageUI)
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    #endif
    @State private var showMailAlert = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SharedStyles.Spacing.extraLarge) {
                VStack(alignment: .leading, spacing: SharedStyles.Spacing.medium) {
                    Text(L10n.Settings.language)
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                        .padding(.horizontal, SharedStyles.Spacing.small)
                    
                    SettingsSectionCard {
                        Button {
                            showLanguageSelector = true
                        } label: {
                            SettingsRowContent(
                                iconSystemName: "globe",
                                iconTint: SharedStyles.primaryColor,
                                title: L10n.Settings.language,
                                value: LocalizationManager.displayName(for: localizationManager.currentLanguage)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: SharedStyles.Spacing.medium) {
                    Text(L10n.Settings.dataSync)
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                        .padding(.horizontal, SharedStyles.Spacing.small)

                    SettingsSectionCard {
                        SettingsToggleRow(
                            iconSystemName: "icloud",
                            iconTint: SharedStyles.Accent.sky,
                            title: L10n.Settings.iCloudSync,
                            subtitle: L10n.Settings.iCloudSyncDescription,
                            showsProBadge: !purchaseManager.isProUnlocked,
                            isOn: Binding(
                                get: { archeryStore.isICloudSyncEnabled },
                                set: { newValue in
                                    handleICloudToggleChange(newValue)
                                }
                            )
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: SharedStyles.Spacing.medium) {
                    Text(L10n.Settings.about)
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                        .padding(.horizontal, SharedStyles.Spacing.small)
                    
                    SettingsSectionCard {
                        NavigationLink {
                            AboutView()
                        } label: {
                            SettingsRowContent(
                                iconSystemName: "info.circle",
                                iconTint: SharedStyles.secondaryColor,
                                title: L10n.Settings.about
                            )
                        }
                        .buttonStyle(.plain)
                        
                        SettingsDivider()
                        
                        Button {
                            #if canImport(MessageUI)
                            if MFMailComposeViewController.canSendMail() {
                                showMailView = true
                            } else {
                                showMailAlert = true
                            }
                            #else
                            showMailAlert = true
                            #endif
                        } label: {
                            SettingsRowContent(
                                iconSystemName: "paperplane",
                                iconTint: SharedStyles.primaryColor,
                                title: L10n.Settings.feedback
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                SettingsVersionCard(version: getAppVersion())
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .background(settingsBackground.ignoresSafeArea())
        .sheet(isPresented: $showLanguageSelector) {
            LanguageSelectorView(isPresented: $showLanguageSelector)
                .environmentObject(localizationManager)
        }
        .sheet(item: $activePaywallFeature) { feature in
            ProPaywallView {
                if feature == .icloudSync {
                    archeryStore.setICloudSyncEnabled(true)
                }
            }
            .environmentObject(purchaseManager)
        }
        #if canImport(MessageUI)
        .sheet(isPresented: $showMailView) {
            MailView(result: $mailResult, isShowing: $showMailView)
        }
        #endif
        .alert(isPresented: $showMailAlert) {
            Alert(
                title: Text(L10n.tr("settings_mail_unavailable_title")),
                message: Text(L10n.tr("settings_mail_unavailable_message")),
                dismissButton: .default(Text(L10n.Common.done))
            )
        }
        .customNavigationBar(
            title: L10n.Settings.title,
            leadingButton: {
                dismiss()
            },
            backgroundColor: SharedStyles.backgroundColor,
            foregroundColor: SharedStyles.primaryTextColor
        )
    }
    
    private var settingsBackground: some View {
        SharedStyles.blockGradient(SharedStyles.GradientSet.warmCanvas)
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func handleICloudToggleChange(_ enabled: Bool) {
        if enabled && !purchaseManager.isProUnlocked {
            activePaywallFeature = .icloudSync
            return
        }

        archeryStore.setICloudSyncEnabled(enabled)
    }
}

private struct SettingsToggleRow: View {
    let iconSystemName: String
    let iconTint: Color
    let title: String
    let subtitle: String
    let showsProBadge: Bool
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: SharedStyles.Spacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconTint.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: iconSystemName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(iconTint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .sharedTextStyle(SharedStyles.Text.bodyEmphasis)

                        if showsProBadge {
                            ProBadgeView(iconSize: 9, horizontalPadding: 7, verticalPadding: 4)
                        }
                    }

                    Text(subtitle)
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .toggleStyle(SwitchToggleStyle(tint: SharedStyles.primaryColor))
    }
}

private struct SettingsSectionCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .clayCard(tint: SharedStyles.Accent.sky, radius: 22)
    }
}

private struct SettingsRowContent: View {
    let iconSystemName: String
    let iconTint: Color
    let title: String
    var value: String? = nil
    
    var body: some View {
        HStack(spacing: SharedStyles.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconTint.opacity(0.12))
                    .frame(width: 42, height: 42)
                
                Image(systemName: iconSystemName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconTint)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                
                if let value {
                    Text(value)
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.secondaryTextColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(SharedStyles.Text.caption)
                .foregroundStyle(SharedStyles.tertiaryTextColor)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(SharedStyles.groupBackgroundColor)
            .frame(height: 1)
            .padding(.leading, 54)
    }
}

private struct SettingsVersionCard: View {
    let version: String
    
    var body: some View {
        HStack(spacing: SharedStyles.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(SharedStyles.primaryColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SharedStyles.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Settings.version)
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                
                Text(version)
                    .sharedTextStyle(
                        SharedStyles.Text.caption,
                        color: SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.captionLineSpacing
                    )
            }
            
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .clayCard(tint: SharedStyles.Accent.violet, radius: 20)
    }
}

// MARK: - MailView
#if canImport(MessageUI)
struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Binding var isShowing: Bool
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var result: Result<MFMailComposeResult, Error>?
        @Binding var isShowing: Bool
        
        init(result: Binding<Result<MFMailComposeResult, Error>?>, isShowing: Binding<Bool>) {
            _result = result
            _isShowing = isShowing
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                isShowing = false
            }
            
            if let error = error {
                self.result = .failure(error)
                return
            }
            self.result = .success(result)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(result: $result, isShowing: $isShowing)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["baibin1989@foxmail.com"])
        vc.setSubject(L10n.tr("settings_feedback_subject"))
        vc.setMessageBody(L10n.tr("settings_feedback_body"), isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
    }
}
#endif

// 关于页面
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // App Logo
                Image("AppIcon") // 确保您的项目中有这个图片资源
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .cornerRadius(24)
                    .padding(.top, 40)
                
                // App 名称
                Text(L10n.tr("about_app_name"))
                    .sharedTextStyle(SharedStyles.Text.screenTitle)
                
                // 版本信息
                Text(L10n.tr("about_version_format", getAppVersion()))
                    .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.secondaryTextColor)
                
                // 描述
                Text(L10n.tr("about_description"))
                    .sharedTextStyle(
                        SharedStyles.Text.body,
                        color: SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.bodyLineSpacing
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                
                // 联系信息
                VStack(spacing: 8) {
                    Text(L10n.tr("about_contact"))
                        .sharedTextStyle(SharedStyles.Text.title)
                    
                    Button(action: {
                        if let url = URL(string: "mailto:baibin1989@foxmail.com") {
                            #if os(iOS)
                            UIApplication.shared.open(url)
                            #else
                            NSWorkspace.shared.open(url)
                            #endif
                        }
                    }) {
                        Text("baibin1989@foxmail.com")
                            .sharedTextStyle(SharedStyles.Text.body, color: SharedStyles.Accent.sky)
                            .underline()
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        #if os(iOS)
        .navigationBarTitle(L10n.tr("about_title"), displayMode: .inline)
        .vibrantCanvasBackground()
        #else
        .navigationTitle(L10n.tr("about_title"))
        .vibrantCanvasBackground()
        #endif
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// 语言选择器视图
struct LanguageSelectorView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(LocalizationManager.supportedLanguages) { language in
                    Button(action: {
                        localizationManager.setLanguage(language.code)
                        isPresented = false
                    }) {
                        HStack {
                            Text(language.displayName)
                                .sharedTextStyle(SharedStyles.Text.body)
                            Spacer()
                            if localizationManager.currentLanguage == language.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(SharedStyles.primaryColor)
                            }
                        }
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitle(L10n.Settings.languageSelection, displayMode: .inline)
            .navigationBarItems(
                leading: Button(L10n.Common.cancel) {
                    isPresented = false
                },
                trailing: Button(L10n.Common.done) {
                    isPresented = false
                }
            )
            #else
            .navigationTitle(L10n.Settings.languageSelection)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        isPresented = false
                    }
                }
            }
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(ArcheryStore())
            .environmentObject(LocalizationManager())
    }
}
