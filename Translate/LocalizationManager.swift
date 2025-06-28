import Foundation
import SwiftUI

/**
 * 国际化本地化管理系统
 * 
 * 提供完整的多语言支持，包含语言类型定义、本地化管理类和SwiftUI扩展
 * 支持中文和英文两种语言，提供完整的应用界面本地化
 * 
 * 主要组件：
 * - Language: 语言类型枚举
 * - LocalizationManager: 本地化管理单例类
 * - View扩展: SwiftUI视图本地化支持
 * - String扩展: 字符串本地化支持
 */

// MARK: - 语言类型
/**
 * 支持的语言类型枚举
 * 
 * 定义应用支持的所有语言选项
 * 包含语言代码和显示名称的映射
 */
enum Language: String, CaseIterable {
    /// 简体中文
    case chinese = "zh-Hans"
    /// 英语
    case english = "en"
    
    /// 语言的显示名称
    var displayName: String {
        switch self {
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }
}

// MARK: - 国际化管理类
/**
 * 国际化本地化管理器
 * 
 * 单例模式的本地化管理类，负责：
 * - 当前语言状态管理
 * - 本地化字典的维护
 * - 本地化字符串的获取
 * - 语言设置的持久化存储
 */
class LocalizationManager: ObservableObject {
    /// 单例实例
    static let shared = LocalizationManager()
    
    /// 当前选择的语言，支持自动保存到UserDefaults
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
    }
    
    /// 中英自动切换开关状态，支持自动保存到UserDefaults
    @Published var isAutoSwitchEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAutoSwitchEnabled, forKey: "auto_switch_enabled")
        }
    }
    
    /// 私有初始化器，确保单例模式
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? Language.chinese.rawValue
        self.currentLanguage = Language(rawValue: savedLanguage) ?? .chinese
        self.isAutoSwitchEnabled = UserDefaults.standard.bool(forKey: "auto_switch_enabled")
    }
    
    /**
     * 获取本地化字符串
     * 
     * - Parameter key: 本地化键值
     * - Returns: 对应当前语言的本地化字符串，如果未找到则返回键值本身
     */
    func localizedString(for key: String) -> String {
        return getLocalizedText(for: key, language: currentLanguage)
    }
    
    /**
     * 设置当前语言
     * 
     * - Parameter language: 要设置的语言类型
     */
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }
    
    /**
     * 获取指定语言的本地化文本
     * 
     * - Parameter key: 本地化键值
     * - Parameter language: 目标语言
     * - Returns: 本地化字符串，如果未找到则返回键值本身
     */
    private func getLocalizedText(for key: String, language: Language) -> String {
        let localizations = language == .chinese ? chineseLocalizations : englishLocalizations
        return localizations[key] ?? key
    }
    
    // MARK: - 中文本地化
    /// 中文本地化字典，包含所有界面文字的中文翻译
    private let chineseLocalizations: [String: String] = [
        // 通用按钮
        "done": "完成",
        "settings": "设置",
        
        // 主界面
        "ai_translator": "AI 翻译器",
        
        // 语言选项
        "auto_detect": "自动检测",
        "auto_short": "自动",
        "english": "英语",
        "chinese": "中文", 
        "tagalog": "菲律宾语",
        "tagalog_short": "菲语",
        
        // 主界面文字
        "input_text": "输入文本",
        "input_placeholder": "在此输入要翻译的文本...",
        "recognizing_text": "正在识别文字...",
        "read_aloud": "朗读",
        "api_key_required": "请先在设置中配置API密钥",
        "translate": "翻译",
        "image_recognition": "图片识别",
        "select_image_source": "选择图片来源",
        "camera": "拍照",
        "from_photo_library": "从相册选择",
        
        // 按钮文字（对话框使用）
        "cancel": "取消",
        "stop": "停止",
        
        // 语言选择
        "language_chinese": "中文",
        "language_english": "English",
        "language_setting": "语言设置",
        "language_description": "选择应用显示语言",
        
        // 设置页面
        "settings_title": "设置",
        "settings_subtitle": "配置您的翻译偏好",
        
        // API密钥区域
        "api_key_title": "OpenAI API 密钥",
        "api_key_placeholder": "输入您的 OpenAI API 密钥",
        "api_key_configured": "API 密钥已配置",
        "api_key_description": "需要 API 密钥才能使用翻译功能",
        "api_key_help_title": "获取 API 密钥",
        "api_key_help_message": "1. 访问 openai.com\n2. 登录或注册账户\n3. 进入 API Keys 页面\n4. 创建新的 API 密钥\n5. 复制并粘贴到此处",
        "api_key_help_ok": "好的",
        
        // AI模型区域
        "model_title": "AI 模型",
        "model_gpt35_title": "GPT-3.5 Turbo",
        "model_gpt35_description": "快速、经济的选择",
        "model_gpt4_title": "GPT-4",
        "model_gpt4_description": "更强大、更准确的翻译",
        
        // 使用提示区域
        "tips_title": "使用提示",
        "tip_1": "在 OpenAI 官网注册并获取 API 密钥",
        "tip_2": "选择适合的模型：GPT-3.5 更快，GPT-4 更准确",
        "tip_3": "支持拍照或从相册选择图片进行文字识别",
        "tip_4": "可复制翻译结果或使用语音朗读",
        
        // 菲律宾语语音设置
        "filipino_voice_title": "菲律宾语语音选择",
        "filipino_voice_description": "iOS系统不支持菲律宾语原生语音，请选择替代语音",
        "voice_american_english": "美式英语（推荐）",
        "voice_british_english": "英式英语", 
        "voice_malay": "马来语",
        
        // 中英自动切换功能
        "auto_switch_title": "中英自动切换",
        "auto_switch_description": "根据输入文本自动切换目标语言",
        "auto_switch_enabled": "已开启自动切换",
        "auto_switch_disabled": "已关闭自动切换"
    ]
    
    // MARK: - 英文本地化
    /// 英文本地化字典，包含所有界面文字的英文翻译
    private let englishLocalizations: [String: String] = [
        // Common Buttons
        "done": "Done",
        "settings": "Settings",
        
        // Main Interface
        "ai_translator": "AI Translator",
        
        // Language Options
        "auto_detect": "Auto Detect",
        "auto_short": "Auto",
        "english": "English",
        "chinese": "Chinese",
        "tagalog": "Tagalog",
        "tagalog_short": "Tagalog",
        
        // Main Interface Text
        "input_text": "Input Text",
        "input_placeholder": "Enter text to translate...",
        "recognizing_text": "Recognizing text...",
        "read_aloud": "Read Aloud",
        "api_key_required": "Please configure API key in settings first",
        "translate": "Translate",
        "image_recognition": "Image Recognition",
        "select_image_source": "Select Image Source",
        "camera": "Camera",
        "from_photo_library": "From Photo Library",
        
        // Button Text (for dialogs)
        "cancel": "Cancel",
        "stop": "Stop",
        
        // Language Selection
        "language_chinese": "中文",
        "language_english": "English",
        "language_setting": "Language Settings",
        "language_description": "Choose the app display language",
        
        // Settings Page
        "settings_title": "Settings",
        "settings_subtitle": "Configure your translation preferences",
        
        // API Key Section
        "api_key_title": "OpenAI API Key",
        "api_key_placeholder": "Enter your OpenAI API key",
        "api_key_configured": "API key configured",
        "api_key_description": "API key required for translation functionality",
        "api_key_help_title": "Get API Key",
        "api_key_help_message": "1. Visit openai.com\n2. Login or register an account\n3. Go to API Keys page\n4. Create a new API key\n5. Copy and paste it here",
        "api_key_help_ok": "OK",
        
        // AI Model Section
        "model_title": "AI Model",
        "model_gpt35_title": "GPT-3.5 Turbo",
        "model_gpt35_description": "Fast and economical choice",
        "model_gpt4_title": "GPT-4",
        "model_gpt4_description": "More powerful and accurate translation",
        
        // Tips Section
        "tips_title": "Usage Tips",
        "tip_1": "Register at OpenAI website and get API key",
        "tip_2": "Choose the right model: GPT-3.5 is faster, GPT-4 is more accurate",
        "tip_3": "Supports text input, photo recognition and album selection",
        "tip_4": "Copy translation results or use voice reading",
        
        // Filipino voice settings
        "filipino_voice_title": "Filipino Voice Selection",
        "filipino_voice_description": "iOS doesn't support native Filipino voice, please choose alternative",
        "voice_american_english": "American English (Recommended)",
        "voice_british_english": "British English",
        "voice_malay": "Malay",
        
        // Auto language switch feature
        "auto_switch_title": "Auto Chinese-English Switch",
        "auto_switch_description": "Automatically switch target language based on input text",
        "auto_switch_enabled": "Auto switch enabled",
        "auto_switch_disabled": "Auto switch disabled"
    ]
}

// MARK: - SwiftUI 扩展
/**
 * SwiftUI View 扩展
 * 
 * 为SwiftUI视图提供便捷的本地化方法
 */
extension View {
    /**
     * 本地化视图修饰符
     * 
     * - Parameter key: 本地化键值
     * - Returns: 显示本地化文本的Text视图
     */
    func localized(_ key: String) -> some View {
        Text(LocalizationManager.shared.localizedString(for: key))
    }
}

// MARK: - String 扩展
/**
 * String 扩展
 * 
 * 为字符串提供便捷的本地化属性
 */
extension String {
    /**
     * 本地化字符串属性
     * 
     * 将当前字符串作为键值获取对应的本地化文本
     * 使用方式：`"key".localized`
     */
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
} 