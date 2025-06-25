import SwiftUI

/**
 * AI翻译器应用入口
 * 
 * SwiftUI应用的主入口点，定义应用的基本配置
 * 采用现代化的SwiftUI App生命周期管理
 * 
 * 功能特性：
 * - 基于SwiftUI的声明式UI
 * - 支持iOS平台
 * - 集成完整的翻译功能
 */
@main
struct TranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
