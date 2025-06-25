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
    /// 国际化管理器
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ZStack {
            backgroundGradient
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    languageSelectionSection
                    apiKeySection
                    modelSelectionSection

                    tipsSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.bottom, 20)
            }
        }
        .alert(localizationManager.localizedString(for: "api_key_help_title"), isPresented: $showingKeyHelper) {
            Button(localizationManager.localizedString(for: "api_key_help_ok")) { }
        } message: {
            Text(localizationManager.localizedString(for: "api_key_help_message"))
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
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(localizationManager.localizedString(for: "settings_title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(localizationManager.localizedString(for: "settings_subtitle"))
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 语言选择区域
    private var languageSelectionSection: some View {
        VStack(spacing: 16) {
            languageSelectionHeader
            languageOptions
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(sectionBackground)
        .padding(.horizontal, 20)
    }
    
    private var languageSelectionHeader: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundColor(.green)
                .font(.system(size: 18))
            
            Text(localizationManager.localizedString(for: "language_setting"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    private var languageOptions: some View {
        VStack(spacing: 12) {
            ForEach(Language.allCases, id: \.self) { language in
                LanguageOptionView(
                    isSelected: localizationManager.currentLanguage == language,
                    language: language,
                    action: {
                        localizationManager.setLanguage(language)
                    }
                )
            }
        }
    }
    
    // MARK: - API密钥配置区域
    private var apiKeySection: some View {
        VStack(spacing: 16) {
            apiKeyHeader
            apiKeyInputField
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(sectionBackground)
        .padding(.horizontal, 20)
    }
    
    private var apiKeyHeader: some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundColor(.orange)
                .font(.system(size: 18))
            
            Text(localizationManager.localizedString(for: "api_key_title"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                showingKeyHelper = true
            }) {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
        }
    }
    
    private var apiKeyInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SecureField(localizationManager.localizedString(for: "api_key_placeholder"), text: $apiKey)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(inputFieldBackground)
            
            apiKeyStatusIndicator
        }
    }
    
    private var inputFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var apiKeyStatusIndicator: some View {
        HStack {
            Image(systemName: apiKey.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(apiKey.isEmpty ? .yellow : .green)
                .font(.system(size: 12))
            
            Text(apiKey.isEmpty ? 
                 localizationManager.localizedString(for: "api_key_description") : 
                 localizationManager.localizedString(for: "api_key_configured"))
                .font(.caption)
                .foregroundColor(apiKey.isEmpty ? .yellow : .green)
        }
    }
    
    // MARK: - 模型选择区域
    private var modelSelectionSection: some View {
        VStack(spacing: 16) {
            modelSelectionHeader
            modelOptions
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(sectionBackground)
        .padding(.horizontal, 20)
    }
    
    private var modelSelectionHeader: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.blue)
                .font(.system(size: 18))
            
            Text(localizationManager.localizedString(for: "model_title"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    private var modelOptions: some View {
        VStack(spacing: 12) {
            ModelOptionView(
                isSelected: model == "gpt-3.5-turbo",
                icon: "⚡️",
                title: localizationManager.localizedString(for: "model_gpt35_title"),
                description: localizationManager.localizedString(for: "model_gpt35_description"),
                action: { model = "gpt-3.5-turbo" }
            )
            
            ModelOptionView(
                isSelected: model == "gpt-4",
                icon: "🧠",
                title: localizationManager.localizedString(for: "model_gpt4_title"),
                description: localizationManager.localizedString(for: "model_gpt4_description"),
                action: { model = "gpt-4" }
            )
        }
    }
    

    // MARK: - 使用提示区域
    private var tipsSection: some View {
        VStack(spacing: 12) {
            tipsHeader
            tipsContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(sectionBackground)
        .padding(.horizontal, 20)
    }
    
    private var tipsHeader: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 18))
            
            Text(localizationManager.localizedString(for: "tips_title"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    private var tipsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            TipRow(icon: "1.circle.fill", text: localizationManager.localizedString(for: "tip_1"), color: .orange)
            TipRow(icon: "2.circle.fill", text: localizationManager.localizedString(for: "tip_2"), color: .blue)
            TipRow(icon: "3.circle.fill", text: localizationManager.localizedString(for: "tip_3"), color: .green)
            TipRow(icon: "4.circle.fill", text: localizationManager.localizedString(for: "tip_4"), color: .purple)
        }
    }
    
    // MARK: - 通用样式
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - 语言选项视图
struct LanguageOptionView: View {
    let isSelected: Bool
    let language: Language
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(language == .chinese ? "🇨🇳" : "🇺🇸")
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(LocalizationManager.shared.localizedString(for: "language_description"))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(optionBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var optionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.green.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - 模型选项视图
struct ModelOptionView: View {
    let isSelected: Bool
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(optionBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var optionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - 提示行视图
struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}