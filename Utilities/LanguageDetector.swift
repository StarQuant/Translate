import Foundation
import NaturalLanguage

/**
 * 语言检测工具类
 * 
 * 使用iOS原生的NaturalLanguage框架进行文本语言检测
 * 专门用于中英文自动切换功能的语言识别
 * 
 * 主要功能：
 * - 检测文本的主要语言
 * - 处理混合语言文本
 * - 提供置信度判断
 * - 支持中文、英文等主流语言识别
 */
class LanguageDetector {
    /// 单例实例
    static let shared = LanguageDetector()
    
    /// 私有初始化器，确保单例模式
    private init() {}
    
    /**
     * 检测文本的主要语言
     * 
     * - Parameter text: 要检测的文本
     * - Returns: 检测到的主要语言代码，如果无法确定则返回nil
     */
    func detectPrimaryLanguage(text: String) -> String? {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空文本或过短文本无法准确检测
        guard !cleanText.isEmpty && cleanText.count >= 1 else {
            return nil
        }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(cleanText)
        
        // 获取语言检测结果和置信度
        let languageHypotheses = recognizer.languageHypotheses(withMaximum: 5)
        
        // 如果没有检测结果，返回nil
        guard !languageHypotheses.isEmpty else {
            return nil
        }
        
        // 检查是否有中文检测结果
        for (language, confidence) in languageHypotheses {
            if isChineseLanguage(language) && confidence > 0.3 {
                return "zh"
            }
        }
        
        // 检查是否有英文检测结果
        for (language, confidence) in languageHypotheses {
            if language == .english && confidence > 0.3 {
                return "en"
            }
        }
        
        // 使用最高置信度的结果
        if let dominantLanguage = recognizer.dominantLanguage {
            if isChineseLanguage(dominantLanguage) {
                return "zh"
            } else if dominantLanguage == .english {
                return "en"
            }
        }
        
        // 如果都不是中英文，但有其他语言检测结果，返回"other"
        if recognizer.dominantLanguage != nil {
            return "other"
        }
        
        return nil
    }
    
    /**
     * 判断是否为中文语言
     * 
     * - Parameter language: NLLanguage语言类型
     * - Returns: 是否为中文相关语言
     */
    private func isChineseLanguage(_ language: NLLanguage) -> Bool {
        return language == .simplifiedChinese || 
               language == .traditionalChinese ||
               language.rawValue == "zh-Hans" ||
               language.rawValue == "zh-Hant" ||
               language.rawValue == "zh"
    }
    
    /**
     * 根据检测结果确定目标语言
     * 
     * - Parameter detectedLanguage: 检测到的源语言
     * - Returns: 推荐的目标语言代码
     */
    func getTargetLanguage(for detectedLanguage: String?) -> String? {
        guard let detected = detectedLanguage else {
            return nil
        }
        
        switch detected {
        case "zh":
            return "en"  // 中文 -> 英文
        case "en":
            return "zh"  // 英文 -> 中文
        case "other":
            return "zh"  // 其他语言 -> 中文
        default:
            return nil
        }
    }
} 