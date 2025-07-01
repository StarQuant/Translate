import SwiftUI
import VisionKit
import PhotosUI

/**
 * 主视图
 * 
 * 应用的主界面，集成了所有核心功能
 * 采用现代化的SwiftUI设计，支持深色主题和动态布局
 * 
 * 主要功能：
 * - 多语言翻译界面
 * - 实时流式翻译显示
 * - 图片文字识别（OCR）
 * - 语音朗读功能
 * - 文本复制粘贴
 * - 设置界面集成
 * 
 * 设计特色：
 * - 渐变背景设计
 * - 响应式布局适配
 * - 流畅的动画效果
 * - 直观的用户交互
 */
struct MainView: View {
    @StateObject private var viewModel = TranslatorViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    @AppStorage("AutoPasteTranslate") var autoPasteTranslate: Bool = false
    @State private var showSettings = false
    @State private var showFullScreen = false  // 添加全屏sheet状态
    @FocusState private var isInputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var isFullScreen = false  // 添加全屏状态
    @State private var textEditorHeight: CGFloat = 45  // 添加文本编辑器高度状态
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // 纯黑色背景
                    Color.black
                        .ignoresSafeArea()
                        .onTapGesture {
                            // 点击背景收回键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    
                    VStack(spacing: 16) {
                        // 顶部语言选择区域（完全对称布局）
                        HStack(spacing: 0) {
                            // 源语言选择框
                            Picker("", selection: $viewModel.sourceLanguage) {
                                Text(localizationManager.localizedString(for: "auto_short")).tag("auto")
                                Text(localizationManager.localizedString(for: "english")).tag("en")
                                Text(localizationManager.localizedString(for: "chinese")).tag("zh")
                                Text(localizationManager.localizedString(for: "tagalog_short")).tag("tl")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(.white)
                            .frame(width: 120, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            
                            Spacer()
                            
                            // 交换按钮
                            Button(action: {
                                let tempSource = viewModel.sourceLanguage
                                let tempTarget = viewModel.targetLanguage
                                
                                if tempSource != "auto" {
                                    viewModel.sourceLanguage = tempTarget
                                    viewModel.targetLanguage = tempSource
                                } else {
                                    viewModel.sourceLanguage = "en"
                                    viewModel.targetLanguage = "zh"
                                }
                            }) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                    )
                                    .scaleEffect(viewModel.swapButtonPressed ? 0.9 : 1.0)
                                    .rotationEffect(.degrees(viewModel.swapButtonPressed ? 180 : 0))
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.swapButtonPressed = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.swapButtonPressed = false
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // 目标语言选择框
                            Picker("", selection: $viewModel.targetLanguage) {
                                Text(localizationManager.localizedString(for: "english")).tag("en")
                                Text(localizationManager.localizedString(for: "chinese")).tag("zh")
                                Text(localizationManager.localizedString(for: "tagalog_short")).tag("tl")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(.white)
                            .frame(width: 120, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // 输入区域
                        VStack(spacing: 12) {
                            // 输入框功能按钮（扩展版）- 只在有内容时显示
                            if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                HStack {
                                    // 左侧按钮组
                                    HStack(spacing: 8) {
                                        // 复制按钮（移到左边）
                                        Button(action: {
                                            UIPasteboard.general.string = viewModel.inputText
                                            viewModel.copySuccess = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                viewModel.copySuccess = false
                                            }
                                        }) {
                                            Image(systemName: viewModel.copySuccess ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 16))
                                                .foregroundColor(viewModel.copySuccess ? .blue : .blue)
                                                .frame(width: 40, height: 32)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(viewModel.copySuccess ? Color.blue.opacity(0.2) : Color.blue.opacity(0.2))
                                                )
                                        }
                                        
                                        // 图片选择按钮（合并相机和相册）
                                        Menu {
                                            Button(action: {
                                                viewModel.imageSourceType = .camera
                                                viewModel.showImagePicker = true
                                            }) {
                                                Label(localizationManager.localizedString(for: "camera"), systemImage: "camera")
                                            }
                                            
                                            Button(action: {
                                                viewModel.imageSourceType = .photoLibrary
                                                viewModel.showImagePicker = true
                                            }) {
                                                Label(localizationManager.localizedString(for: "from_photo_library"), systemImage: "photo")
                                            }
                                        } label: {
                                            Image(systemName: "camera")
                                                .font(.system(size: 16))
                                                .foregroundColor(.blue)
                                                .frame(width: 40, height: 32)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color.blue.opacity(0.2))
                                                )
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // 粘贴按钮（移到右边）
                                    Button(action: {
                                        if let pasted = UIPasteboard.general.string {
                                            viewModel.inputText = pasted
                                            viewModel.pasteSuccess = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                viewModel.pasteSuccess = false
                                            }
                                            
                                            // 如果开启一键粘贴翻译，自动开始翻译
                                            if autoPasteTranslate {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    // 如果正在显示键盘，先收起键盘
                                                    if isInputFocused {
                                                        isInputFocused = false
                                                    }
                                                    viewModel.translate()
                                                }
                                            }
                                        }
                                    }) {
                                        Image(systemName: viewModel.pasteSuccess ? "checkmark" : "doc.on.clipboard")
                                            .font(.system(size: 16))
                                            .foregroundColor(viewModel.pasteSuccess ? .blue : .blue)
                                            .frame(width: 40, height: 32)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(viewModel.pasteSuccess ? Color.blue.opacity(0.2) : Color.blue.opacity(0.2))
                                            )
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                // 当没有内容时，显示功能按钮（图片选择、粘贴）
                                HStack {
                                    // 左侧按钮组
                                    HStack(spacing: 8) {
                                        // 图片选择按钮（合并相机和相册）
                                        Menu {
                                            Button(action: {
                                                viewModel.imageSourceType = .camera
                                                viewModel.showImagePicker = true
                                            }) {
                                                Label(localizationManager.localizedString(for: "camera"), systemImage: "camera")
                                            }
                                            
                                            Button(action: {
                                                viewModel.imageSourceType = .photoLibrary
                                                viewModel.showImagePicker = true
                                            }) {
                                                Label(localizationManager.localizedString(for: "from_photo_library"), systemImage: "photo")
                                            }
                                        } label: {
                                            Image(systemName: "camera")
                                                .font(.system(size: 16))
                                                .foregroundColor(.blue)
                                                .frame(width: 40, height: 32)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color.blue.opacity(0.2))
                                                )
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // 粘贴按钮（移到右边）
                                    Button(action: {
                                        if let pasted = UIPasteboard.general.string {
                                            viewModel.inputText = pasted
                                            viewModel.pasteSuccess = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                viewModel.pasteSuccess = false
                                            }
                                            
                                            // 如果开启一键粘贴翻译，自动开始翻译
                                            if autoPasteTranslate {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    // 如果正在显示键盘，先收起键盘
                                                    if isInputFocused {
                                                        isInputFocused = false
                                                    }
                                                    viewModel.translate()
                                                }
                                            }
                                        }
                                    }) {
                                        Image(systemName: viewModel.pasteSuccess ? "checkmark" : "doc.on.clipboard")
                                            .font(.system(size: 16))
                                            .foregroundColor(viewModel.pasteSuccess ? .blue : .blue)
                                            .frame(width: 40, height: 32)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(viewModel.pasteSuccess ? Color.blue.opacity(0.2) : Color.blue.opacity(0.2))
                                            )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // 输入框主体
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                isInputFocused ? Color.white.opacity(0.4) : Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: Color.white.opacity(0.03), radius: 5, x: 0, y: 0)
                                
                                TextEditor(text: $viewModel.inputText)
                                    .padding(8)
                                    .font(.system(size: 17))
                                    .foregroundColor(.gray)
                                    .background(Color.clear)
                                    .focused($isInputFocused)
                                
                                if viewModel.inputText.isEmpty && !viewModel.isRecognizingText {
                                    Text(localizationManager.localizedString(for: "input_placeholder"))
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.system(size: 16))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }
                                
                                // 文字识别进度指示器
                                if viewModel.isRecognizingText {
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text(localizationManager.localizedString(for: "recognizing_text"))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            }
                            .frame(minHeight: 100, maxHeight: 180)
                            .padding(.horizontal)
                        }
                        
                        // 翻译结果区域 - 键盘显示时隐藏，在开始翻译时立即显示
                        if (viewModel.isTranslating || !viewModel.translatedText.isEmpty) && keyboardHeight <= 0 {
                            VStack(spacing: 12) {
                                HStack {
                                    Spacer()
                                    
                                    HStack(spacing: 12) {
                                        // 全屏查看按钮
                                        Button(action: {
                                            showFullScreen = true
                                        }) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 16))
                                                .foregroundColor(.blue)
                                                .frame(width: 40, height: 32)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color.blue.opacity(0.2))
                                                )
                                        }
                                        
                                        // 语音朗读按钮
                                        Button(action: {
                                            viewModel.speak()
                                        }) {
                                            Image(systemName: viewModel.isSpeaking ? "speaker.wave.2.fill" : "speaker.2")
                                                .font(.system(size: 16))
                                                .foregroundColor(viewModel.isSpeaking ? .blue : .blue)
                                                .frame(width: 40, height: 32)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(viewModel.isSpeaking ? Color.blue.opacity(0.2) : Color.blue.opacity(0.2))
                                                )
                                        }
                                        
                                        Button(action: {
                                            UIPasteboard.general.string = viewModel.translatedText
                                            viewModel.resultCopySuccess = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                viewModel.resultCopySuccess = false
                                            }
                                        }) {
                                            Image(systemName: viewModel.resultCopySuccess ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 16))
                                                .foregroundColor(.blue)
                                                .frame(width: 40, height: 32)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color.blue.opacity(0.2))
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                ScrollView {
                                    VStack {
                                        if viewModel.isTranslating && viewModel.translatedText.isEmpty {
                                            // 翻译中的状态显示
                                            VStack(spacing: 8) {
                                                ProgressView()
                                                    .scaleEffect(1.2)
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                                                Text(localizationManager.localizedString(for: "translating"))
                                                    .font(.caption)
                                                    .foregroundColor(.cyan.opacity(0.8))
                                            }
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(12)
                                        } else {
                                            // 翻译结果显示
                                            Text(viewModel.translatedText.isEmpty ? "" : viewModel.translatedText)
                                                .foregroundColor(.cyan)
                                                .font(.system(size: 17))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(12)
                                                .textSelection(.enabled)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                        // 在键盘存在或无结果框存在时显示Spacer
                        if keyboardHeight > 0 || (viewModel.translatedText.isEmpty && !viewModel.isTranslating) {
                            Spacer(minLength: 1)
                        }
                        
                        // 底部操作栏 - 有内容时显示或键盘弹出时显示键盘收回按钮
                        if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isInputFocused {
                            VStack(spacing: 0) {
                                HStack(spacing: 5) {
                                    // 左侧删除按钮（仅在有内容时显示）
                                    if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Button(action: {
                                            viewModel.inputText = ""
                                            viewModel.translatedText = ""
                                        }) {
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.white)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(Color.red.opacity(0.8))
                                                )
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // 键盘收起按钮（仅在键盘显示时）
                                    if isInputFocused {
                                        Button(action: {
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }) {
                                            Image(systemName: "keyboard.chevron.compact.down")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.6))
                                                )
                                        }
                                    }
                                    
                                    // 右侧翻译/取消按钮（仅在有内容时显示）
                                    if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Button(action: {
                                            if viewModel.isTranslating {
                                                viewModel.cancelTranslation()
                                            } else {
                                                // 如果正在显示键盘，先收起键盘
                                                if isInputFocused {
                                                    isInputFocused = false
                                                }
                                                // 开始翻译
                                                viewModel.translate()
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                if viewModel.isTranslating {
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 16))
                                                } else {
                                                    Image(systemName: "arrowtriangle.right.fill")
                                                        .font(.system(size: 16))
                                                }
                                                Text(viewModel.isTranslating 
                                                     ? localizationManager.localizedString(for: "cancel")
                                                     : localizationManager.localizedString(for: "translate"))
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 22)
                                                    .fill(Color.blue)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - geometry.safeAreaInsets.bottom : 0)
                                .background(
                                    Color.black
                                )
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        keyboardHeight = keyboardFrame.height
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    keyboardHeight = 0
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 18))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(LocalizationManager.shared.localizedString(for: "done")) {
                                showSettings = false
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
            }
        }
        .sheet(isPresented: $showFullScreen) {
            NavigationView {
                ScrollView {
                    VStack {
                        if viewModel.isTranslating && viewModel.translatedText.isEmpty {
                            // 翻译中的状态显示
                            VStack(spacing: 12) {
                                                                 ProgressView()
                                     .scaleEffect(1.5)
                                     .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                                 Text(localizationManager.localizedString(for: "translating"))
                                     .font(.title3)
                                     .foregroundColor(.cyan.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(32)
                        } else {
                            // 翻译结果显示 - 支持流式更新
                                                         Text(viewModel.translatedText.isEmpty ? "" : viewModel.translatedText)
                                 .foregroundColor(.cyan)
                                .font(.system(size: 19))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .textSelection(.enabled)
                        }
                        
                        Spacer()
                    }
                }
                .background(
                    Color.blue.opacity(0.15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                        )
                        .ignoresSafeArea()
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showFullScreen = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 20))
                        }
                    }
                }
            }
            .background(Color.black)
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(
                image: $viewModel.selectedImage,
                sourceType: viewModel.imageSourceType
            )
        }
        .onChange(of: viewModel.selectedImage) { image in
            if let image = image {
                viewModel.recognizeText(from: image)
                viewModel.selectedImage = nil // 重置选中的图片
            } else {
            }
        }
    }
}
