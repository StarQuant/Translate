import SwiftUI

/**
 * 设置视图
 * 
 * 应用的主要设置界面，包含以下功能：
 * - 应用语言选择（中文/英文）
 * - OpenAI API密钥配置
 * - AI模型选择（GPT-3.5/GPT-4）
 * - 使用提示信息
 * 
 * 采用深色主题设计，使用渐变背景和半透明卡片式布局
 */
struct SettingsView: View {
    /// OpenAI API密钥，存储在UserDefaults中
    @AppStorage("OpenAIKey") var apiKey: String = ""
    /// 选择的AI模型，默认为GPT-3.5 Turbo
    @AppStorage("Model") var model: String = "gpt-3.5-turbo"
    /// 是否显示API密钥帮助对话框
    @State private var showingKeyHelper = false
    /// 一键粘贴翻译开关
    @AppStorage("AutoPasteTranslate") var autoPasteTranslate: Bool = false
    /// 国际化管理器
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ZStack {
            backgroundGradient
            
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    // 应用配置
                    settingSection(
                        icon: "globe",
                        title: localizationManager.localizedString(for: "app_config"),
                        color: .white.opacity(0.8)
                    ) {
                        languageSelectionRow
                        autoSwitchRow
                        autoPasteTranslateRow
                    }
                    
                    // OpenAI 配置
                    settingSection(
                        icon: "key.fill",
                        title: localizationManager.localizedString(for: "openai_config"),
                        color: .white.opacity(0.8)
                    ) {
                        apiKeyRow
                        modelSelectionRow
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .alert(localizationManager.localizedString(for: "api_key_help"), isPresented: $showingKeyHelper) {
            Button(localizationManager.localizedString(for: "confirm")) { }
        } message: {
            Text(localizationManager.localizedString(for: "api_key_help_content"))
        }
    }
    
    // MARK: - 背景渐变
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text(localizationManager.localizedString(for: "settings_title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
    
    // MARK: - 设置分组
    private func settingSection<Content: View>(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                content()
            }
        }
        .padding(16)
        .background(sectionBackground)
    }
    
    // MARK: - 语言选择行
    private var languageSelectionRow: some View {
        HStack {
            Text(localizationManager.localizedString(for: "interface_language"))
                .foregroundColor(.white)
            
            Spacer()
            
            Picker("", selection: $localizationManager.currentLanguage) {
                ForEach(Language.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 自动切换行
    private var autoSwitchRow: some View {
        HStack {
            Text(localizationManager.localizedString(for: "smart_language_switch"))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $localizationManager.isAutoSwitchEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 一键粘贴翻译行
    private var autoPasteTranslateRow: some View {
        HStack {
            Text(localizationManager.localizedString(for: "paste_auto_translate"))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $autoPasteTranslate)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - API 密钥行
    private var apiKeyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localizationManager.localizedString(for: "api_key"))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showingKeyHelper = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                }
            }
            
            SecureField(localizationManager.localizedString(for: "enter_openai_api_key"), text: $apiKey)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(inputBackground)
            
            HStack {
                Image(systemName: apiKey.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(apiKey.isEmpty ? .orange : .green)
                    .font(.system(size: 10))
                
                Text(apiKey.isEmpty ? localizationManager.localizedString(for: "please_enter_key") : localizationManager.localizedString(for: "configured"))
                    .font(.caption)
                    .foregroundColor(apiKey.isEmpty ? .orange : .green)
            }
        }
    }
    
    // MARK: - 模型选择行
    private var modelSelectionRow: some View {
        HStack {
            Text(localizationManager.localizedString(for: "ai_model"))
                .foregroundColor(.white)
            
            Spacer()
            
            Picker("", selection: $model) {
                Text("GPT-3.5").tag("gpt-3.5-turbo")
                Text("GPT-4").tag("gpt-4")
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 通用样式
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

