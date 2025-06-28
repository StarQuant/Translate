import Foundation
import UIKit
import Vision
import AVFoundation

/**
 * 翻译视图模型
 * 
 * 翻译应用的核心业务逻辑处理类，负责管理所有翻译相关功能
 * 采用MVVM架构，继承NSObject以支持Objective-C运行时特性和代理模式
 * 
 * 主要功能：
 * - 文本翻译（支持流式实时显示）
 * - 图片文字识别（OCR）
 * - 语音朗读功能（多语言支持）
 * - 语言设置持久化
 * - 翻译任务取消控制
 * - 用户交互状态管理
 * 
 * 技术特性：
 * - 集成OpenAI API进行智能翻译
 * - 使用Vision框架进行文字识别
 * - 集成AVFoundation进行语音合成
 * - 完整的错误处理和用户反馈
 * - 支持流式数据处理和实时更新
 */
class TranslatorViewModel: NSObject, ObservableObject {
    // MARK: - 发布属性
    /// 用户输入的待翻译文本
    @Published var inputText = ""
    /// 翻译结果文本
    @Published var translatedText = ""
    /// 源语言设置，支持自动保存到UserDefaults
    @Published var sourceLanguage: String {
        didSet {
            UserDefaults.standard.set(sourceLanguage, forKey: "SourceLanguage")
        }
    }
    /// 目标语言设置，支持自动保存到UserDefaults
    @Published var targetLanguage: String {
        didSet {
            UserDefaults.standard.set(targetLanguage, forKey: "TargetLanguage")
        }
    }
    /// 是否正在进行翻译
    @Published var isTranslating = false
    /// 是否正在进行语音朗读
    @Published var isSpeaking = false
    /// 语言交换按钮是否被按下
    @Published var swapButtonPressed = false
    
    // MARK: - 用户操作反馈状态
    /// 粘贴操作成功状态
    @Published var pasteSuccess = false
    /// 复制操作成功状态
    @Published var copySuccess = false
    /// 结果复制操作成功状态
    @Published var resultCopySuccess = false
    
    // MARK: - 图片识别相关属性
    /// 是否显示图片选择器
    @Published var showImagePicker = false
    /// 选中的图片
    @Published var selectedImage: UIImage?
    /// 图片来源类型（相机或相册）
    @Published var imageSourceType: ImageSourceType = .camera
    /// 是否正在进行文字识别
    @Published var isRecognizingText = false
    
    // MARK: - 私有属性
    /// 語音合成器实例
    private let synthesizer = AVSpeechSynthesizer()
    
    /// 当前进行中的翻译任务，支持取消操作
    private var currentTranslationTask: URLSessionDataTask?
    
    // MARK: - 初始化
    /**
     * 初始化翻译视图模型
     * 
     * 设置默认语言配置，初始化语音合成器并配置音频会话
     * 从UserDefaults恢复用户的语言偏好设置
     */
    override init() {
        // 从UserDefaults读取保存的语言设置
        self.sourceLanguage = UserDefaults.standard.string(forKey: "SourceLanguage") ?? "auto"
        self.targetLanguage = UserDefaults.standard.string(forKey: "TargetLanguage") ?? "zh"
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    /**
     * 配置音频会话
     * 
     * 设置音频会话类别为播放模式，优化语音朗读体验
     * 支持音频混合和自动激活
     */
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // 音频会话配置失败，忽略错误继续运行
        }
    }

    // MARK: - 计算属性
    /// 从UserDefaults获取OpenAI API密钥
    var apiKey: String {
        UserDefaults.standard.string(forKey: "OpenAIKey") ?? ""
    }

    /// 从UserDefaults获取选择的AI模型
    var model: String {
        UserDefaults.standard.string(forKey: "Model") ?? "gpt-3.5-turbo"
    }

    func translate() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return 
        }
        
        guard !apiKey.isEmpty else {
            translatedText = "❌ \(LocalizationManager.shared.localizedString(for: "api_key_required"))"
            return
        }

        // 如果开启了自动切换功能，先检测语言并自动切换目标语言
        var detectedSourceLanguage: String? = nil
        
        if LocalizationManager.shared.isAutoSwitchEnabled {
            detectedSourceLanguage = performAutoLanguageSwitch()
        }

        isTranslating = true
        translatedText = ""

        // 构建翻译提示词：如果开启了自动切换且检测到了语言，使用检测到的语言作为源语言
        let actualSourceLanguage: String
        if LocalizationManager.shared.isAutoSwitchEnabled, let detected = detectedSourceLanguage {
            actualSourceLanguage = detected
        } else {
            actualSourceLanguage = sourceLanguage
        }
        
        let to = languageName(targetLanguage)
        
        // 构建更明确的翻译提示词
        let prompt: String
        if actualSourceLanguage == "auto" {
            prompt = "Translate the following text to \(to). Only return the translation, no explanations:\n\n\(inputText)"
        } else {
            prompt = "Translate the following text from \(languageName(actualSourceLanguage)) to \(to). Only return the translation, no explanations:\n\n\(inputText)"
        }

        currentTranslationTask = APIService.shared.translateStream(
            prompt: prompt, 
            apiKey: apiKey, 
            model: model,
            onPartialResult: { [weak self] partialText in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let cleanedText = partialText.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.translatedText = self.removeQuotes(from: cleanedText)
                }
            },
            onComplete: { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isTranslating = false
                    self.currentTranslationTask = nil
                    switch result {
                    case .success(let finalText):
                        let cleanedText = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.translatedText = self.removeQuotes(from: cleanedText)
            
                    case .failure(let error):
                        // 如果是取消操作，不显示错误信息
                        if (error as NSError).code != NSURLErrorCancelled {
                            self.translatedText = "❌ \(error.localizedDescription)"
                
                        } else {
            
                        }
                    }
                }
            }
        )
        }
    
    // 取消翻译
    func cancelTranslation() {
        guard let task = currentTranslationTask else { return }
        
        task.cancel()
        currentTranslationTask = nil
        isTranslating = false

    }
    
    // MARK: - 自动语言切换
    
    /**
     * 执行自动语言切换
     * 
     * 检测输入文本的主要语言，并根据检测结果自动设置源语言和目标语言
     * 仅在自动切换功能开启时执行
     * 
     * 切换规则：
     * - 源语言为"自动"时：保持"自动"不变
     * - 源语言为其他语言时：根据检测结果自动切换源语言
     * - 目标语言：始终根据检测结果自动切换
     * 
     * - Returns: 检测到的源语言代码，用于生成翻译提示词
     */
    private func performAutoLanguageSwitch() -> String? {
        let detectedLanguage = LanguageDetector.shared.detectPrimaryLanguage(text: inputText)
        
        // 根据检测结果自动设置目标语言
        if let targetLang = LanguageDetector.shared.getTargetLanguage(for: detectedLanguage) {
            targetLanguage = targetLang
        }
        
        // 源语言切换逻辑
        if sourceLanguage != "auto" {
            // 源语言不是自动时，根据检测结果自动切换
            if let detected = detectedLanguage, detected != "other" {
                if sourceLanguage != detected {
                    sourceLanguage = detected
                }
            }
        }
        
        // 返回检测到的语言，用于翻译提示词生成
        return detectedLanguage
    }
    
    private func languageName(_ code: String) -> String {
        switch code {
        case "zh": return "Chinese"
        case "en": return "English"
        case "tl": return "Filipino"
        default: return "Auto"
        }
    }
    
    // 智能去除AI返回时包裹整个翻译结果的多余双引号
    private func removeQuotes(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 只有当文本开头和结尾都有双引号，且去除后仍有内容时才去除
        // 这样可以避免误删文本内容中的正常双引号
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count > 2 {
            let withoutQuotes = String(trimmed.dropFirst().dropLast())
            
            // 检查去除引号后的内容是否平衡（没有未配对的引号在开头/结尾）
            // 如果内容本身就是以引号开头结尾的，不应该去除外层引号
            if !withoutQuotes.hasPrefix("\"") || !withoutQuotes.hasSuffix("\"") {
                return withoutQuotes
            }
        }
        
        return trimmed
    }

    // OCR文字识别功能
    func recognizeText(from image: UIImage) {

        
        guard let cgImage = image.cgImage else { 

            DispatchQueue.main.async {
                self.translatedText = "❌ 无法处理图片"
                self.isRecognizingText = false
            }
            return 
        }
        

        isRecognizingText = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { 
    
                return 
            }
            
            do {
        
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["zh-CN", "en-US"] // 支持中英文识别
                request.usesLanguageCorrection = true
                
    
                try requestHandler.perform([request])
                
                let observations = request.results ?? []

                
                let recognizedTexts = observations.compactMap { observation in
                    let candidate = observation.topCandidates(1).first
                    
                    return candidate?.string
                }
                
                let text = recognizedTexts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                
                DispatchQueue.main.async {
                    self.isRecognizingText = false
                    if !text.isEmpty {
                        self.inputText = text
    
                        // 清空之前的翻译结果
                        self.translatedText = ""
                    } else {
                        self.translatedText = "❌ 未识别到文字，请尝试：\n• 确保图片清晰\n• 文字对比度足够\n• 重新拍摄或选择图片"
    
                    }
                }
            } catch {

                DispatchQueue.main.async {
                    self.isRecognizingText = false
                    self.translatedText = "❌ 文字识别失败: \(error.localizedDescription)"
                }
            }
        }
    }

    // 语音朗读功能
    func speak() {
        guard !translatedText.isEmpty else { 
            return 
        }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }
        
        // 重新配置音频会话（确保在朗读前音频会话是活跃的）
        setupAudioSession()
        
        let utterance = AVSpeechUtterance(string: translatedText)
        
        // 根据目标语言设置语音
        let languageCode: String
        switch targetLanguage {
        case "zh":
            languageCode = "zh-CN"
        case "en":
            languageCode = "en-US"
        case "tl":
            // 菲律宾语：iOS系统不支持原生Tagalog语音
            // 提供多种替代选择，用户可以在设置中选择偏好
            let filipinoVoiceSetting = UserDefaults.standard.string(forKey: "FilipinoVoicePreference") ?? "en-US"
            
            switch filipinoVoiceSetting {
            case "ms-MY":
                languageCode = "ms-MY"  // 马来语（地理位置相近，语言系谱相似）
            case "en-GB":
                languageCode = "en-GB"  // 英式英语
            default:
                languageCode = "en-US"  // 美式英语（默认，菲律宾广泛使用）
            }
        default:
            languageCode = "en-US"
        }
        
        // 尝试获取指定语言的语音，如果失败则使用备用方案
        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice

        } else {
            // 如果指定语言不可用，尝试备用语言
            let fallbackLanguages = ["en-US", "en-GB", "zh-CN"]
            var voiceFound = false
            
            for fallbackLang in fallbackLanguages {
                if let fallbackVoice = AVSpeechSynthesisVoice(language: fallbackLang) {
                    utterance.voice = fallbackVoice
        
                    voiceFound = true
                    break
                }
            }
            
            // 最后的备用方案：使用系统默认语音
            if !voiceFound {
                utterance.voice = AVSpeechSynthesisVoice.speechVoices().first
    
            }
        }
        
        utterance.rate = 0.45 // 稍微调慢一点
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        

        isSpeaking = true
        synthesizer.speak(utterance)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TranslatorViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
    }
}
