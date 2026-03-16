import Foundation

class CozeService: ObservableObject {
    // 添加可观察的状态
    @Published private(set) var isConnecting = false
    @Published private(set) var connectionError: Error?
    
    // 配置信息
    private let configuration: CozeConfiguration
    private var accessToken: String { configuration.accessToken }
    private var botId: String { configuration.botId }
    private var baseURL: String { configuration.baseURL }

    init(configuration: CozeConfiguration = CozeConfiguration.load() ?? .empty) {
        self.configuration = configuration
    }
    
    func getTrainingAdvice(data: ArcheryTrainingData) async throws -> TrainingAdvice {
        try ensureConfiguration()
        print("\n=== 开始获取训练建议 ===")
        
        // 1. 构建基本信息部分
        let basicInfo = """
        基本信息：
        - 弓种：\(data.metadata["bowType"] ?? "")
        - 距离：\(data.metadata["distance"] ?? "")米
        - 靶型：\(data.metadata["targetType"] ?? "")
        - 总箭数：\(data.metadata["totalArrows"] ?? "")
        - 训练日期：\(data.metadata["date"] ?? "")
        """
        
        print("\n发送的训练数据:")
        print(basicInfo)
        
        // 2. 构建成绩数据部分
        let scoreInfo = """
        成绩数据：
        - 总分：\(data.totalScore)
        - 平均每箭：\(String(format: "%.1f", data.averagePerArrow))
        - 各组得分：\(data.scores.map { String($0) }.joined(separator: ", "))
        """
        
        // 3. 构建分数分布部分
        let distributionInfo = data.scoreDistribution.map { "\($0.key): \($0.value)次" }.joined(separator: "\n")
        
        // 4. 组合完整内容
        let content = """
        请基于以下射箭训练记录进行分析：
        
        \(basicInfo)
        
        \(scoreInfo)
        
        分数分布：
        \(distributionInfo)
        
        请提供：
        1. 当前水平评估
        2. 主要问题分析
        3. 具体训练建议
        """
        
        // 5. 构建消息体
        let message = [
            "role": "user",
            "content": content,
            "content_type": "text"
        ]
        
        let messageBody: [String: Any] = [
            "bot_id": botId,
            "user_id": "user_\(UUID().uuidString)",
            "stream": false,
            "auto_save_history": true,
            "additional_messages": [message]
        ]
        
        // 6. 创建和配置请求
        let chatUrl = URL(string: "\(baseURL)/v3/chat")!
        var chatRequest = URLRequest(url: chatUrl)
        chatRequest.httpMethod = "POST"
        chatRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        chatRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        chatRequest.httpBody = try JSONSerialization.data(withJSONObject: messageBody)
        
        // 7. 发送请求并处理响应
        print("\n正在发送API请求...")
        let (chatData, _) = try await URLSession.shared.data(for: chatRequest)
        
        print("\n收到初始响应:")
        print(String(data: chatData, encoding: .utf8) ?? "无法解码响应数据")
        
        // 解析初始响应
        struct ChatResponse: Codable {
            let code: Int
            let msg: String
            let data: ChatObject
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: chatData)
        guard chatResponse.code == 0 else {
            print("\n请求失败: code=\(chatResponse.code)")
            throw CozeError.requestFailed(statusCode: chatResponse.code)
        }
        
        // 获取对话ID和会话ID
        let chatId = chatResponse.data.id
        let conversationId = chatResponse.data.conversation_id
        
        print("\n开始轮询获取结果...")
        // 轮询获取结果
        for attempt in 0..<20 {
            print("\n第 \(attempt + 1) 次尝试获取结果")
            
            let retrieveUrl = URL(string: "\(baseURL)/v3/chat/retrieve")!
                .appendingQueryItem(name: "chat_id", value: chatId)
                .appendingQueryItem(name: "conversation_id", value: conversationId)
            
            var retrieveRequest = URLRequest(url: retrieveUrl)
            retrieveRequest.httpMethod = "GET"
            retrieveRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (retrieveData, _) = try await URLSession.shared.data(for: retrieveRequest)
            let retrieveResponse = try JSONDecoder().decode(ChatResponse.self, from: retrieveData)
            
            print("获取到响应: \(String(data: retrieveData, encoding: .utf8) ?? "无法解码")")
            
            // 检查对话状态
            switch retrieveResponse.data.status {
            case "completed":
                print("\n对话完成！")
                if let usage = retrieveResponse.data.usage {
                    print("Token使用情况: 总计=\(usage.token_count ?? 0), 输入=\(usage.input_count ?? 0), 输出=\(usage.output_count ?? 0)")
                }
                
                // 获取消息列表
                let messagesUrl = URL(string: "\(baseURL)/v3/chat/message/list")!
                    .appendingQueryItem(name: "chat_id", value: chatId)
                    .appendingQueryItem(name: "conversation_id", value: conversationId)
                
                var messagesRequest = URLRequest(url: messagesUrl)
                messagesRequest.httpMethod = "GET"
                messagesRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let (messagesData, _) = try await URLSession.shared.data(for: messagesRequest)
                
                // 解析消息列表响应
                struct MessagesResponse: Codable {
                    let code: Int
                    let data: [Message]
                    let msg: String
                    
                    struct Message: Codable {
                        let bot_id: String
                        let content: String
                        let content_type: String
                        let conversation_id: String
                        let id: String
                        let role: String
                        let type: String?
                    }
                }
                
                let messagesResponse = try JSONDecoder().decode(MessagesResponse.self, from: messagesData)
                
                // 查找类型为 "answer" 的助手回复
                if let assistantMessage = messagesResponse.data.first(where: { $0.role == "assistant" && $0.type == "answer" }) {
                    print("\n=== 开始解析AI返回内容 ===")
                    let content = assistantMessage.content
                    print("原始内容：\n\(content)")
                    
                    // 将内容按段落分割
                    let paragraphs = content.components(separatedBy: "\n\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    print("\n处理后的段落：")
                    paragraphs.forEach { print($0) }
                    
                    // 提取各部分内容
                    var performanceLevel = ""
                    var issues: [String] = []
                    var suggestions: [String] = []
                    
                    // 首先尝试使用正则表达式匹配各个部分
                    let performancePattern = try? NSRegularExpression(pattern: "当前水平评估[：:](.*?)(?=主要问题分析|$)", options: [.dotMatchesLineSeparators])
                    let issuesPattern = try? NSRegularExpression(pattern: "主要问题分析[：:](.*?)(?=具体训练建议|$)", options: [.dotMatchesLineSeparators])
                    let suggestionsPattern = try? NSRegularExpression(pattern: "具体训练建议[：:](.*?)$", options: [.dotMatchesLineSeparators])

                    let contentRange = NSRange(content.startIndex..<content.endIndex, in: content)

                    // 提取性能评估部分
                    if let match = performancePattern?.firstMatch(in: content, options: [], range: contentRange),
                       let range = Range(match.range(at: 1), in: content) {
                        performanceLevel = String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    // 提取问题分析部分
                    if let match = issuesPattern?.firstMatch(in: content, options: [], range: contentRange),
                       let range = Range(match.range(at: 1), in: content) {
                        let issuesText = String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        // 处理带有 - 或 • 的列表项
                        issues = issuesText.components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                            .map { line in
                                if line.hasPrefix("-") || line.hasPrefix("•") {
                                    return line.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                                }
                                return line
                            }
                    }

                    // 提取训练建议部分
                    if let match = suggestionsPattern?.firstMatch(in: content, options: [], range: contentRange),
                       let range = Range(match.range(at: 1), in: content) {
                        let suggestionsText = String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        // 处理带有 - 或 • 的列表项
                        suggestions = suggestionsText.components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                            .map { line in
                                if line.hasPrefix("-") || line.hasPrefix("•") {
                                    return line.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                                }
                                return line
                            }
                    }

                    // 如果正则表达式解析失败，尝试按段落解析
                    if performanceLevel.isEmpty && issues.isEmpty && suggestions.isEmpty {
                        print("正则表达式解析失败，尝试按段落解析")
                        
                        // 按段落分割内容
                        let paragraphs = content.components(separatedBy: "\n\n")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        
                        for paragraph in paragraphs {
                            if paragraph.contains("当前水平评估") {
                                performanceLevel = paragraph.replacingOccurrences(of: "当前水平评估[：:]*\\s*", with: "", options: .regularExpression)
                            } else if paragraph.contains("主要问题分析") {
                                let lines = paragraph.components(separatedBy: .newlines)
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty && !$0.contains("主要问题分析") }
                                    .map { line in
                                        if line.hasPrefix("-") || line.hasPrefix("•") {
                                            return line.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                                        }
                                        return line
                                    }
                                issues = lines
                            } else if paragraph.contains("具体训练建议") {
                                let lines = paragraph.components(separatedBy: .newlines)
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty && !$0.contains("具体训练建议") }
                                    .map { line in
                                        if line.hasPrefix("-") || line.hasPrefix("•") {
                                            return line.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                                        }
                                        return line
                                    }
                                suggestions = lines
                            }
                        }
                    }

                    // 如果解析结果为空，使用默认值
                    if performanceLevel.isEmpty {
                        performanceLevel = "AI未能提供水平评估"
                    }
                    if issues.isEmpty {
                        issues = ["AI未能识别问题"]
                    }
                    if suggestions.isEmpty {
                        suggestions = ["AI未能提供具体建议"]
                    }

                    print("\n最终解析结果：")
                    print("性能评估：\n\(performanceLevel)")
                    print("\n问题：")
                    issues.forEach { print("- \($0)") }
                    print("\n建议：")
                    suggestions.forEach { print("- \($0)") }
                    print("=== 解析完成 ===\n")
                    
                    let advice = TrainingAdvice(
                        performanceLevel: performanceLevel,
                        issues: issues,
                        suggestions: suggestions,
                        improvements: [],
                        recordId: data.recordId,
                        recordType: data.recordType,
                        timestamp: Date()
                    )
                    
                    return advice
                }
                
                throw CozeError.invalidResponse
                
            case "failed":
                print("\n对话失败！")
                if let error = retrieveResponse.data.last_error {
                    print("对话失败: code=\(error.code), msg=\(error.msg)")
                    throw CozeError.requestFailed(statusCode: error.code)
                }
                throw CozeError.invalidResponse
                
            case "in_progress":
                print("AI正在处理中...")
                try await Task.sleep(nanoseconds: 3_000_000_000)
                continue
                
            default:
                print("\n未知状态: \(retrieveResponse.data.status)")
                try await Task.sleep(nanoseconds: 3_000_000_000)
                continue
            }
        }
        
        print("\n=== 获取训练建议结束 ===\n")
        throw CozeError.timeout
    }
    
    private func createConversation() async throws -> String {
        try ensureConfiguration()
        let url = URL(string: "\(baseURL)/v1/conversation/create")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        logResponseDetails(data, response: response as! HTTPURLResponse)
        
        struct CreateConversationResponse: Codable {
            let data: ConversationData
            let code: Int
            let msg: String
            
            struct ConversationData: Codable {
                let id: String  // 这里修改为 id
            }
        }
        
        let createResponse = try JSONDecoder().decode(CreateConversationResponse.self, from: data)
        guard createResponse.code == 0 else {
            throw CozeError.requestFailed(statusCode: createResponse.code)
        }
        
        return createResponse.data.id  // 返回 id 作为 conversation_id
    }
    
    private func createMessage(conversationId: String, data: ArcheryTrainingData) async throws -> CozeStatusResponse {
        try ensureConfiguration()
        let url = URL(string: "\(baseURL)/v1/conversation/message/create")!
            .appendingQueryItem(name: "conversation_id", value: conversationId)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // 修改内容构建部分
        let content = """
        请基于以下射箭训练记录进行分析：
        
        基本信息：
        - 弓种：\(data.metadata["bowType"] ?? "")
        - 距离：\(data.metadata["distance"] ?? "")米
        - 靶型：\(data.metadata["targetType"] ?? "")
        - 总箭数：\(data.metadata["totalArrows"] ?? "")
        - 训练日期：\(data.metadata["date"] ?? "")
        
        成绩数据：
        - 总分：\(data.totalScore)
        - 平均每箭：\(String(format: "%.1f", data.averagePerArrow))
        - 各组得分：\(data.scores.map { String($0) }.joined(separator: ", "))
        
        分数分布：
        \(data.scoreDistribution.map { "\($0.key): \($0.value)次" }.joined(separator: "\n"))
        
        请提供（使用Markdown格式）：
        1. **当前水平评估**
           - 总体水平评价
           - 技术掌握程度
           - 稳定性分析

        2. **主要问题分析**
           - 技术问题
           - 心理因素
           - 其他影响

        3. **具体训练建议**
           - 短期目标
           - 训练重点
           - 具体方法

        4. **需要改进的方面**
           - 优先改进项
           - 长期发展建议
           - 注意事项
        """
        
        let messageBody: [String: Any] = [
            "role": "user",
            "content": content,  // 使用构建的 content 字符串
            "content_type": "text",
            "bot_id": botId
        ]
        
        // 打印请求信息
        print("发送消息请求:")
        print("URL: \(url)")
        print("Headers: \(sanitizedHeaders(request.allHTTPHeaderFields ?? [:]))")
        print("Body: \(messageBody)")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: messageBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            logResponseDetails(data, response: httpResponse)
            print("发送消息响应: \(String(data: data, encoding: .utf8) ?? "无法解码")")
        }
        
        // 解析响应
        struct CreateMessageResponse: Codable {
            let code: Int
            let msg: String
            let data: MessageData
            
            struct MessageData: Codable {
                let id: String
                let conversation_id: String
                let content: String
                let role: String
                let created_at: Int
                let content_type: String
                let bot_id: String?
                let chat_id: String?
                let meta_data: [String: String]?
                let type: String?
                let updated_at: String?
            }
        }
        
        let createResponse = try JSONDecoder().decode(CreateMessageResponse.self, from: data)
        
        // 检查响应状态
        guard createResponse.code == 0 else {
            print("发送消息失败: code=\(createResponse.code), msg=\(createResponse.msg)")
            throw CozeError.requestFailed(statusCode: createResponse.code)
        }
        
        print("发送消息成功，message_id: \(createResponse.data.id)")
        
        // 返回状态响应
        return CozeStatusResponse(
            data: CozeStatusResponse.StatusData(
                id: createResponse.data.id,
                conversation_id: createResponse.data.conversation_id,
                bot_id: createResponse.data.bot_id ?? "",
                created_at: createResponse.data.created_at,
                status: "in_progress",
                last_error: CozeStatusResponse.StatusData.LastError(code: 0, msg: "")
            ),
            code: createResponse.code,
            msg: createResponse.msg
        )
    }
    
    private func pollForResult(conversationId: String, data: ArcheryTrainingData) async throws -> TrainingAdvice {
        try ensureConfiguration()
        // 第一步：获取消息列表
        let listUrl = URL(string: "\(baseURL)/v1/conversation/message/list")!
            .appendingQueryItem(name: "conversation_id", value: conversationId)
        
        var listRequest = URLRequest(url: listUrl)
        listRequest.httpMethod = "POST"
        listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        listRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加空的请求体
        let emptyBody: [String: Any] = [:]
        listRequest.httpBody = try JSONSerialization.data(withJSONObject: emptyBody)
        
        // 增加轮询次数和间隔时间
        for attempt in 0..<20 {
            print("尝试获取结果: 第 \(attempt + 1) 次")
            
            let (listData, listResponse) = try await URLSession.shared.data(for: listRequest)
            if let httpResponse = listResponse as? HTTPURLResponse {
                logResponseDetails(listData, response: httpResponse)
                print("消息列表响应: \(String(data: listData, encoding: .utf8) ?? "无法解码")")
            }
            
            // 解析消息列表响应
            struct MessagesListResponse: Codable {
                let code: Int
                let msg: String
                let data: [Message]
                let first_id: String?
                let last_id: String?
                let has_more: Bool?
                
                struct Message: Codable {
                    let id: String
                    let role: String
                    let content: String
                    let conversation_id: String
                    let created_at: Int
                    let content_type: String
                    let bot_id: String?
                    let chat_id: String?
                    let meta_data: [String: String]?
                    let type: String?
                    let updated_at: String?
                    
                    // 打印消息内容的辅助方法
                    func description() -> String {
                        return "Message(role: \(role), content: \(content), id: \(id))"
                    }
                }
            }
            
            do {
                let listResponse = try JSONDecoder().decode(MessagesListResponse.self, from: listData)
                
                // 检查是否有错误
                guard listResponse.code == 0 else {
                    print("API返回错误: code=\(listResponse.code), msg=\(listResponse.msg)")
                    throw CozeError.requestFailed(statusCode: listResponse.code)
                }
                
                // 打印所有消息
                print("获取到 \(listResponse.data.count) 条消息:")
                for message in listResponse.data {
                    print(message.description())
                }
                
                // 查找助手的回复消息
                if let assistantMessage = listResponse.data.first(where: { $0.role == "assistant" }) {
                    print("找到助手回复，message_id: \(assistantMessage.id)")
                    
                    return try await retrieveMessage(
                        conversationId: conversationId, 
                        messageId: assistantMessage.id, 
                        data: data
                    )
                } else {
                    print("未找到助手回复，继续等待...")
                }
            } catch {
                print("解析响应数据失败: \(error)")
                print("原始数据: \(String(data: listData, encoding: .utf8) ?? "无法解码")")
            }
            
            // 等待3秒后重试
            print("等待3秒后重试...")
            try await Task.sleep(nanoseconds: 3_000_000_000)
        }
        
        throw CozeError.timeout
    }
    
    // 新增方法：获取具体消息内容
    private func retrieveMessage(conversationId: String, messageId: String, data: ArcheryTrainingData) async throws -> TrainingAdvice {
        try ensureConfiguration()
        let messageUrl = URL(string: "\(baseURL)/v1/conversation/message/retrieve")!
            .appendingQueryItem(name: "conversation_id", value: conversationId)
            .appendingQueryItem(name: "message_id", value: messageId)
        
        var messageRequest = URLRequest(url: messageUrl)
        messageRequest.httpMethod = "GET"
        messageRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        messageRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (messageData, messageResponse) = try await URLSession.shared.data(for: messageRequest)
        if let httpResponse = messageResponse as? HTTPURLResponse {
            logResponseDetails(messageData, response: httpResponse)
            print("消息详情响应: \(String(data: messageData, encoding: .utf8) ?? "无法解码")")
        }
        
        struct MessageResponse: Codable {
            let code: Int
            let msg: String
            let data: Message
            
            struct Message: Codable {
                let content: String
                let role: String
                let content_type: String
            }
        }
        
        let messageDetail = try JSONDecoder().decode(MessageResponse.self, from: messageData)
        
        // 打印原始AI返回内容
        print("=== AI返回的原始内容 ===")
        print(messageDetail.data.content)
        print("=====================\n")
        
        // 按段落分割内容
        let paragraphs = messageDetail.data.content.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        print("=== 分段后的内容 ===")
        paragraphs.enumerated().forEach { (index, paragraph) in
            print("段落 \(index):")
            print(paragraph)
            print("---")
        }
        print("=====================\n")
        
        // 提取每个部分的内容
        var performanceLevel = "暂无评估"
        var issues: [String] = []
        var suggestions: [String] = []
        
        for (index, paragraph) in paragraphs.enumerated() {
            let lines = paragraph.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            print("处理段落 \(index)，包含 \(lines.count) 行")
            
            switch index {
            case 0: // 第一段是水平评估
                performanceLevel = lines.joined(separator: "\n")
                print("设置 performanceLevel:")
                print(performanceLevel)
                
            case 1: // 第二段是问题分析
                issues = [lines.joined(separator: "\n")]
                print("设置 issues:")
                issues.forEach { print($0) }
                
            case 2: // 第三段是训练建议
                suggestions = lines.filter { $0.hasPrefix("-") }
                    .map { $0.replacingOccurrences(of: "^- ", with: "", options: .regularExpression) }
                print("设置 suggestions:")
                suggestions.forEach { print("- \($0)") }
                
            default:
                print("跳过额外段落 \(index)")
            }
            print("---\n")
        }
        
        // 创建 TrainingAdvice 对象
        let advice = TrainingAdvice(
            performanceLevel: performanceLevel,
            issues: issues,
            suggestions: suggestions,
            improvements: [],
            recordId: data.recordId,
            recordType: data.recordType,
            timestamp: Date()
        )
        
        // 打印最终组装的对象内容
        print("=== 最终组装的 TrainingAdvice 对象 ===")
        print("performanceLevel:")
        print(advice.performanceLevel)
        print("\nissues:")
        advice.issues.forEach { print("- \($0)") }
        print("\nsuggestions:")
        advice.suggestions.forEach { print("- \($0)") }
        print("=====================\n")
        
        return advice
    }
    
    private func parseAIResponse(_ content: String, data: ArcheryTrainingData) -> TrainingAdvice {
        print("\n=== 开始解析AI返回内容 ===")
        print("原始内容：\n\(content)")
        
        // 提取各部分内容
        var performanceLevel = ""
        var issues: [String] = []
        var suggestions: [String] = []
        
        // 首先尝试使用正则表达式匹配各个部分
        let performancePattern = try? NSRegularExpression(pattern: "当前水平评估[：:](.*?)(?=主要问题分析|$)", options: [.dotMatchesLineSeparators])
        let issuesPattern = try? NSRegularExpression(pattern: "主要问题分析[：:](.*?)(?=具体训练建议|$)", options: [.dotMatchesLineSeparators])
        let suggestionsPattern = try? NSRegularExpression(pattern: "具体训练建议[：:](.*?)$", options: [.dotMatchesLineSeparators])

        let contentRange = NSRange(content.startIndex..<content.endIndex, in: content)

        // 提取性能评估部分
        if let match = performancePattern?.firstMatch(in: content, options: [], range: contentRange),
           let range = Range(match.range(at: 1), in: content) {
            performanceLevel = String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 提取问题分析部分
        if let match = issuesPattern?.firstMatch(in: content, options: [], range: contentRange),
           let range = Range(match.range(at: 1), in: content) {
            let issuesText = String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            // 处理带有 - 或 • 的列表项
            issues = issuesText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { line in
                    if line.hasPrefix("-") || line.hasPrefix("•") {
                        return line.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                    }
                    return line
                }
        }

        // 提取训练建议部分
        if let match = suggestionsPattern?.firstMatch(in: content, options: [], range: contentRange),
           let range = Range(match.range(at: 1), in: content) {
            let suggestionsText = String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            // 处理带有 - 或 • 的列表项
            suggestions = suggestionsText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { line in
                    if line.hasPrefix("-") || line.hasPrefix("•") {
                        return line.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                    }
                    return line
                }
        }

        // 如果正则表达式解析失败，尝试按段落解析
        if performanceLevel.isEmpty && issues.isEmpty && suggestions.isEmpty {
            print("正则表达式解析失败，尝试按段落解析")
            
            // 按段落分割内容
            let paragraphs = content.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            for paragraph in paragraphs {
                if paragraph.contains("当前水平评估") {
                    performanceLevel = paragraph.replacingOccurrences(of: "当前水平评估[：:]*\\s*", with: "", options: .regularExpression)
                } else if paragraph.contains("主要问题分析") {
                    let lines = paragraph.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty && !$0.contains("主要问题分析") }
                        .map { line in
                            if line.hasPrefix("-") || line.hasPrefix("•") {
                                return line.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                            }
                            return line
                        }
                    issues = lines
                } else if paragraph.contains("具体训练建议") {
                    let lines = paragraph.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty && !$0.contains("具体训练建议") }
                        .map { line in
                            if line.hasPrefix("-") || line.hasPrefix("•") {
                                return line.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                            }
                            return line
                        }
                    suggestions = lines
                }
            }
        }

        // 如果解析结果为空，使用默认值
        if performanceLevel.isEmpty {
            performanceLevel = "AI未能提供水平评估"
        }
        if issues.isEmpty {
            issues = ["AI未能识别问题"]
        }
        if suggestions.isEmpty {
            suggestions = ["AI未能提供具体建议"]
        }

        print("\n最终解析结果：")
        print("性能评估：\n\(performanceLevel)")
        print("\n问题：")
        issues.forEach { print("- \($0)") }
        print("\n建议：")
        suggestions.forEach { print("- \($0)") }
        print("=== 解析完成 ===\n")

        return TrainingAdvice(
            performanceLevel: performanceLevel,
            issues: issues,
            suggestions: suggestions,
            improvements: [],
            recordId: data.recordId,
            recordType: data.recordType,
            timestamp: Date()
        )
    }
    
    // 辅助方法：从文本中提取列表项
    private func extractBulletPoints(from text: String) -> [String] {
        var bulletPoints: [String] = []
        var currentPoint = ""
        
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("•") || trimmedLine.hasPrefix("*") {
                // 如果有上一个点，先保存
                if !currentPoint.isEmpty {
                    bulletPoints.append(currentPoint)
                    currentPoint = ""
                }
                
                // 提取列表项文本（去掉前导的 - 和空格）
                let pointText = trimmedLine.replacingOccurrences(of: "^[\\-\\*•]\\s*", with: "", options: .regularExpression)
                currentPoint = pointText
            } else if !currentPoint.isEmpty {
                // 如果不是新的列表项，且有当前点，则为当前点的继续
                currentPoint += " " + trimmedLine
            } else {
                // 如果没有列表标记，且没有当前点，则作为新点
                currentPoint = trimmedLine
            }
        }
        
        // 添加最后一个点
        if !currentPoint.isEmpty {
            bulletPoints.append(currentPoint)
        }
        
        return bulletPoints
    }
    
    // 修改测试方法
    func testConnection() async throws -> Bool {
        try ensureConfiguration()
        // 创建一个测试用的射箭记录
        let testRecord = ArcheryGroupRecord(
            id: UUID(),
            bowType: "反曲弓",
            distance: "18",
            targetType: "标准靶",
            groupScores: [["8", "9", "10"]],
            date: Date(),
            numberOfGroups: 1,
            arrowsPerGroup: 3
        )
        
        do {
            let trainingData = prepareGroupTrainingData(record: testRecord)  // 使用 prepareGroupTrainingData
            let advice = try await getTrainingAdvice(data: trainingData)
            
            // 打印返回的结果，用于调试
            print("请求成功！")
            print("性能评估: \(advice.performanceLevel)")
            print("问题分析: \(advice.issues)")
            print("训练建议: \(advice.suggestions)")
            print("改进方向: \(advice.improvements)")
            
            return true
        } catch {
            print("错误: \(error.localizedDescription)")
            return false
        }
    }
    
    // 将访问级别从 private 改为 internal
    func prepareTrainingData(record: ArcheryRecord) -> ArcheryTrainingData {
        let scores = record.scores
        return ArcheryTrainingData(
            recordId: record.id,
            recordType: .single,
            totalScore: scores.calculateScore(),
            averagePerArrow: Double(scores.calculateScore()) / Double(scores.count),
            scores: scores,
            scoreDistribution: getScoreDistribution(from: scores),
            metadata: [
                "bowType": record.bowType,
                "distance": record.distance,
                "targetType": record.targetType,
                "totalArrows": "\(scores.count)",
                "date": record.date.formattedString()
            ]
        )
    }
    
    // 将访问级别从 private 改为 internal
    func prepareGroupTrainingData(record: ArcheryGroupRecord) -> ArcheryTrainingData {
        let allScores = record.groupScores.flatMap { $0 }
        return ArcheryTrainingData(
            recordId: record.id,
            recordType: .group,
            totalScore: allScores.calculateScore(),
            averagePerArrow: Double(allScores.calculateScore()) / Double(allScores.count),
            scores: allScores,
            scoreDistribution: getScoreDistribution(from: allScores),
            metadata: [
                "bowType": record.bowType,
                "distance": record.distance,
                "targetType": record.targetType,
                "totalArrows": "\(allScores.count)",
                "date": record.date.formattedString()
            ]
        )
    }
    
    // getScoreDistribution 可以保持 private
    private func getScoreDistribution(from scores: [String]) -> [String: Int] {
        var distribution: [String: Int] = [:]
        for score in scores {
            distribution[score, default: 0] += 1
        }
        return distribution
    }

    private func ensureConfiguration() throws {
        guard configuration.isConfigured else {
            throw CozeError.configurationMissing
        }
    }

    private func sanitizedHeaders(_ headers: [String: String]) -> [String: String] {
        var sanitized = headers
        if sanitized["Authorization"] != nil {
            sanitized["Authorization"] = "Bearer ***"
        }
        return sanitized
    }
}

extension URL {
    func appendingQueryItem(name: String, value: String) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        components.queryItems = queryItems
        return components.url!
    }
}

// 保留日期解码扩展
extension JSONDecoder {
    func setCustomDateDecodingStrategy() {
        self.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let timestamp = TimeInterval(dateString) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
    }
}

// 保留日志记录扩展
extension CozeService {
    private func logRequestDetails(_ request: URLRequest, data: Data? = nil) {
        print("=== 请求详情 ===")
        print("URL: \(request.url?.absoluteString ?? "无")")
        print("方法: \(request.httpMethod ?? "无")")
        print("头部: \(sanitizedHeaders(request.allHTTPHeaderFields ?? [:]))")
        if let data = data {
            print("请求体: \(String(data: data, encoding: .utf8) ?? "无")")
        }
        print("==============")
    }
    
    private func logResponseDetails(_ data: Data, response: HTTPURLResponse) {
        print("=== 响应详情 ===")
        print("状态码: \(response.statusCode)")
        print("响应头: \(response.allHeaderFields)")
        print("响应体: \(String(data: data, encoding: .utf8) ?? "无")")
        print("==============")
    }
}
