import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

/**
 * 图片来源类型枚举
 * 
 * 定义图片选择的来源方式
 */
enum ImageSourceType {
    /// 相机拍照
    case camera
    /// 相册选择
    case photoLibrary
}

/**
 * 图片选择器
 * 
 * SwiftUI包装的图片选择器，支持相机拍照和相册选择
 * 集成完整的权限管理和错误处理机制
 * 
 * 主要功能：
 * - 相机拍照（需要相机权限）
 * - 相册选择（使用新的PHPickerViewController）
 * - 自动权限检查和引导
 * - 友好的错误提示界面
 * - 完整的用户体验优化
 */
struct ImagePicker: UIViewControllerRepresentable {
    /// SwiftUI环境值，用于控制视图的呈现和消失
    @Environment(\.presentationMode) private var presentationMode
    /// 选择的图片绑定值
    @Binding var image: UIImage?
    /// 图片来源类型（相机或相册）
    var sourceType: ImageSourceType

    /// 创建协调器对象，处理UIKit和SwiftUI之间的交互
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// 创建UIViewController实例，根据来源类型选择相应的控制器
    func makeUIViewController(context: Context) -> UIViewController {
        switch sourceType {
        case .camera:
            // 检查相机可用性
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                return createErrorViewController(message: "📸 设备相机不可用")
            }
            
            // 检查相机权限
            let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            switch cameraAuthStatus {
            case .authorized:
                return createCameraPicker(context: context)
            case .notDetermined:
                return createCameraPicker(context: context)
            case .denied, .restricted:
                return createPermissionInfoViewController()
            @unknown default:
                return createErrorViewController(message: "📸 相机权限状态未知")
            }

        case .photoLibrary:
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
    }
    
    /// 创建相机选择器
    private func createCameraPicker(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear // 明确指定后置摄像头
        picker.showsCameraControls = true
        return picker
    }
    
    /// 创建权限信息视图控制器，引导用户开启相机权限
    private func createPermissionInfoViewController() -> UIViewController {
        return UIHostingController(rootView:
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("需要相机权限")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("此应用需要相机权限来拍摄文档进行文字识别")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Text("请按以下步骤操作：")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. 点击下方『前往设置』按钮")
                    Text("2. 找到『相机』选项")
                    Text("3. 开启相机权限")
                    Text("4. 返回应用重新尝试")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Button("前往设置") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
            .padding()
        )
    }
    
    /// 创建错误提示视图控制器
    private func createErrorViewController(message: String) -> UIViewController {
        return UIHostingController(rootView:
            VStack(spacing: 16) {
                Text(message)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        )
    }

    /// 更新UIViewController（此处无需实现）
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    /**
     * 协调器类
     * 
     * 处理UIKit代理方法，实现SwiftUI和UIKit之间的桥接
     * 支持相机拍照和相册选择的完整流程
     */
    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate {
        /// 父级ImagePicker实例的引用
        let parent: ImagePicker

        /// 初始化协调器
        init(_ parent: ImagePicker) {
            self.parent = parent
            super.init()
        }

        // MARK: - PHPickerViewControllerDelegate
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { 
                return 
            }

            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    
                    if let uiImage = image as? UIImage {
                        self?.parent.image = uiImage
                    } else {
                    }
                }
            }
        }

        // MARK: - UIImagePickerControllerDelegate
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            } else {
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        // MARK: - UINavigationControllerDelegate
        func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        }
        
        deinit {
        }
    }
}
