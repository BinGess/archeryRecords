import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLanguageSelector = false
    @State private var selectedLanguage = L10n.getCurrentLanguage()
    @State private var showMailView = false
    #if canImport(MessageUI)
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    #endif
    @State private var showMailAlert = false
    
    var body: some View {
        List {
            Section {
                // 语言设置行
                Button(action: {
                    showLanguageSelector = true
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(SharedStyles.primaryColor)
                            .frame(width: 24, height: 24)
                        
                        Text(L10n.Settings.language)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(getLanguageDisplayName(selectedLanguage))
                            .foregroundColor(.gray)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .sheet(isPresented: $showLanguageSelector) {
                    LanguageSelectorView(
                        selectedLanguage: $selectedLanguage,
                        isPresented: $showLanguageSelector
                    )
                }
                
                // 关于页面
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(SharedStyles.primaryColor)
                            .frame(width: 24, height: 24)
                        
                        Text(L10n.Settings.about)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Image(systemName: "chevron.right")
                        //     .font(.system(size: 14))
                        //     .foregroundColor(.gray.opacity(0.5))
                    }
                }
                
                // 反馈页面
                Button(action: {
                    #if canImport(MessageUI)
                    if MFMailComposeViewController.canSendMail() {
                        showMailView = true
                    } else {
                        showMailAlert = true
                    }
                    #else
                    showMailAlert = true
                    #endif
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(SharedStyles.primaryColor)
                            .frame(width: 24, height: 24)
                        
                        Text(L10n.Settings.feedback)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                #if canImport(MessageUI)
                .sheet(isPresented: $showMailView) {
                    MailView(result: $mailResult, isShowing: $showMailView)
                }
                #endif
                .alert(isPresented: $showMailAlert) {
                    Alert(
                        title: Text("无法发送邮件"),
                        message: Text("您的设备未设置邮件账户，请设置后再试或直接发送邮件至baibin1989@foxmail.com"),
                        dismissButton: .default(Text("确定"))
                    )
                }
                
                // 版本信息
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(SharedStyles.primaryColor)
                        .frame(width: 24, height: 24)
                    
                    Text(L10n.Settings.version)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(getAppVersion())
                        .foregroundColor(.gray)
                }
            }
            .listRowBackground(Color.white)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        #else
        .listStyle(PlainListStyle())
        #endif
        .background(SharedStyles.backgroundColor)
        .customNavigationBar(
            title: L10n.Settings.title,
            leadingButton: {
                dismiss()
            }
        )
    }
    
    private func getLanguageDisplayName(_ code: String) -> String {
        switch code {
        case "zh":
            return "简体中文"
        case "en":
            return "English"
        default:
            return code
        }
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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
        vc.setSubject("射箭记录App反馈")
        vc.setMessageBody("请在此处输入您的反馈内容：\n\n", isHTML: false)
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
                Text("射箭记录")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                
                // 版本信息
                Text("版本 \(getAppVersion())")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                // 描述
                Text("一款专为射箭爱好者设计的成绩记录和分析工具")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                
                // 联系信息
                VStack(spacing: 8) {
                    Text("联系我们")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                    
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
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
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
        .navigationBarTitle("关于", displayMode: .inline)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .navigationTitle("关于")
        .background(Color.gray.opacity(0.1))
        #endif
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// 语言选择器视图
struct LanguageSelectorView: View {
    @Binding var selectedLanguage: String
    @Binding var isPresented: Bool
    
    private let languages = [
        ("en", "English"),
        ("zh", "简体中文")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.0) { code, name in
                    Button(action: {
                        selectedLanguage = code
                        L10n.setLanguage(code)
                        isPresented = false
                    }) {
                        HStack {
                            Text(name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedLanguage == code {
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
    }
}
