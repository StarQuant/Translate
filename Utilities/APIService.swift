import Foundation

/**
 * API错误枚举
 * 
 * 定义翻译服务可能出现的各种错误类型
 * 实现了LocalizedError协议，提供本地化的错误描述
 */
enum APIError: LocalizedError {
    case invalidAPIKey
    case networkError
    case responseError
    case quotaExceeded
    case modelNotFound
    case timeout
    
    /// 本地化错误描述
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API 密钥无效，请检查设置"
        case .networkError:
            return "网络连接失败，请检查网络"
        case .responseError:
            return "服务器响应错误"
        case .quotaExceeded:
            return "API 使用配额已用完"
        case .modelNotFound:
            return "所选模型不可用"
        case .timeout:
            return "请求超时，请重试"
        }
    }
}

/**
 * 流式数据处理代理
 * 
 * 实现URLSessionDataDelegate协议，用于处理OpenAI流式API响应
 * 支持实时解析Server-Sent Events (SSE) 格式数据
 */
class StreamingDelegate: NSObject, URLSessionDataDelegate {
    /// 部分结果回调，每次接收到新内容时调用
    private let onPartialResult: (String) -> Void
    /// 完成回调，成功或失败时调用
    private let onComplete: (Result<String, Error>) -> Void
    /// 数据缓冲区，用于处理不完整的数据包
    private var dataBuffer = Data()
    /// 累积的完整内容
    private var fullContent = ""
    /// 是否已经完成（避免重复调用完成回调）
    private var hasCompleted = false
    
    /**
     * 初始化流式代理
     */
    init(onPartialResult: @escaping (String) -> Void, onComplete: @escaping (Result<String, Error>) -> Void) {
        self.onPartialResult = onPartialResult
        self.onComplete = onComplete
        super.init()
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                completionHandler(.allow)
            case 401:
                onComplete(.failure(APIError.invalidAPIKey))
                completionHandler(.cancel)
            case 429:
                onComplete(.failure(APIError.quotaExceeded))
                completionHandler(.cancel)
            case 404:
                onComplete(.failure(APIError.modelNotFound))
                completionHandler(.cancel)
            default:
                onComplete(.failure(APIError.responseError))
                completionHandler(.cancel)
            }
        } else {
            onComplete(.failure(APIError.responseError))
            completionHandler(.cancel)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataBuffer.append(data)
        processBuffer()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            if !hasCompleted {
                hasCompleted = true
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled {
                    onComplete(.failure(error))
                } else if error.localizedDescription.contains("timeout") {
                    onComplete(.failure(APIError.timeout))
                } else {
                    onComplete(.failure(APIError.networkError))
                }
            }
        } else {
            if !hasCompleted {
                hasCompleted = true
                onComplete(.success(fullContent.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
    }
    
    private func processBuffer() {
        guard let dataString = String(data: dataBuffer, encoding: .utf8) else { return }
        
        let lines = dataString.components(separatedBy: .newlines)
        var processedLength = 0
        
        for (index, line) in lines.enumerated() {
            if index == lines.count - 1 && !dataString.hasSuffix("\n") {
                break
            }
            
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if jsonString == "[DONE]" {
                    if !hasCompleted {
                        hasCompleted = true
                        onComplete(.success(fullContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                    return
                }
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    
                    if let errorInfo = json["error"] as? [String: Any],
                       let errorMessage = errorInfo["message"] as? String {
                        if !hasCompleted {
                            hasCompleted = true
                            let error = NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                            onComplete(.failure(error))
                        }
                        return
                    }
                    
                    if let choices = json["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any],
                       let content = delta["content"] as? String {
                        fullContent += content
                        onPartialResult(fullContent)
                    }
                }
            }
            
            processedLength += line.utf8.count + 1
        }
        
        if processedLength > 0 {
            let remainingData = dataBuffer.advanced(by: min(processedLength, dataBuffer.count))
            dataBuffer = Data(remainingData)
        }
    }
}

/**
 * API服务类
 * 
 * 提供与OpenAI API通信的服务，支持流式和非流式翻译
 * 采用单例模式，确保全局统一的API配置和状态管理
 */
class APIService {
    /// 单例实例
    static let shared = APIService()
    
    /// 私有初始化器，确保只能通过单例访问
    private init() {}

    // MARK: - 流式翻译方法
    
    /**
     * 流式翻译方法
     * 
     * 发送翻译请求到OpenAI API并实时接收结果
     * 使用Server-Sent Events (SSE) 格式进行流式数据传输
     * 
     * - Parameter prompt: 翻译提示词
     * - Parameter apiKey: OpenAI API密钥
     * - Parameter model: 使用的AI模型（gpt-3.5-turbo 或 gpt-4）
     * - Parameter onPartialResult: 部分结果回调，实时接收翻译内容
     * - Parameter onComplete: 完成回调，返回最终结果或错误
     * - Returns: 可取消的URLSessionDataTask，用于中断请求
     */
    func translateStream(prompt: String, apiKey: String, model: String, 
                        onPartialResult: @escaping (String) -> Void,
                        onComplete: @escaping (Result<String, Error>) -> Void) -> URLSessionDataTask? {
        guard !apiKey.isEmpty else {
            onComplete(.failure(APIError.invalidAPIKey))
            return nil
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            onComplete(.failure(APIError.networkError))
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a professional translator. Provide accurate, natural translations while preserving the original meaning and tone."
                ],
                [
                    "role": "user", 
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 1000,
            "stream": true
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            onComplete(.failure(APIError.responseError))
            return nil
        }

        // 创建带有流式代理的 URLSession
        let delegate = StreamingDelegate(onPartialResult: onPartialResult, onComplete: onComplete)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        let task = session.dataTask(with: request)
        task.resume()
        return task
    }
    
    // MARK: - 非流式翻译方法
    
    /**
     * 非流式翻译方法
     * 
     * 发送翻译请求到OpenAI API并等待完整响应
     * 适用于不需要实时显示的场景，作为流式方法的备用选择
     * 
     * - Parameter prompt: 翻译提示词
     * - Parameter apiKey: OpenAI API密钥
     * - Parameter model: 使用的AI模型（gpt-3.5-turbo 或 gpt-4）
     * - Parameter completion: 完成回调，返回翻译结果或错误
     */
    func translate(prompt: String, apiKey: String, model: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(APIError.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(APIError.networkError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a professional translator. Provide accurate, natural translations while preserving the original meaning and tone."
                ],
                [
                    "role": "user", 
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 1000
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(APIError.responseError))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if error.localizedDescription.contains("timeout") {
                    completion(.failure(APIError.timeout))
                } else {
                    completion(.failure(APIError.networkError))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.responseError))
                return
            }
            
            // 处理 HTTP 状态码
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                completion(.failure(APIError.invalidAPIKey))
                return
            case 429:
                completion(.failure(APIError.quotaExceeded))
                return
            case 404:
                completion(.failure(APIError.modelNotFound))
                return
            default:
                completion(.failure(APIError.responseError))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.responseError))
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(.failure(APIError.responseError))
                    return
                }
                
                // 检查是否有错误响应
                if let errorInfo = json["error"] as? [String: Any],
                   let errorMessage = errorInfo["message"] as? String {
                    let error = NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    completion(.failure(error))
                    return
                }
                
                guard let choices = json["choices"] as? [[String: Any]],
                      let message = choices.first?["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    completion(.failure(APIError.responseError))
                    return
                }

                completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                
            } catch {
                completion(.failure(APIError.responseError))
            }
        }.resume()
    }
}
