import Foundation

// MARK: - 基础响应模型
struct CozeResponse<T: Codable>: Codable {
    let code: Int
    let msg: String
    let data: T
}

// MARK: - 聊天相关模型
struct ChatObject: Codable {
    let id: String
    let conversation_id: String
    let bot_id: String
    let created_at: Int?
    let completed_at: Int?
    let failed_at: Int?
    let meta_data: [String: String]?
    let last_error: LastError?
    let status: String
    let required_action: RequiredAction?
    let usage: Usage?
}

struct Message: Codable {
    let bot_id: String
    let content: String
    let content_type: String
    let conversation_id: String
    let id: String
    let role: String
    let type: String?
}

// MARK: - 辅助模型
struct LastError: Codable {
    let code: Int
    let msg: String
}

struct RequiredAction: Codable {
    let type: String?
    let submit_tool_outputs: ToolOutputs?
}

struct ToolOutputs: Codable {
    let tool_calls: [ToolCall]?
}

struct ToolCall: Codable {
    let id: String?
    let type: String?
    let function: FunctionCall?
}

struct FunctionCall: Codable {
    let name: String?
    let arguments: String?
}

struct Usage: Codable {
    let token_count: Int?
    let output_count: Int?
    let input_count: Int?
}

// MARK: - 状态检查响应
struct CozeStatusResponse: Codable {
    struct StatusData: Codable {
        let id: String
        let conversation_id: String
        let bot_id: String
        let created_at: Int
        let status: String
        
        // 定义内部的 LastError 结构体
        struct LastError: Codable {
            let code: Int
            let msg: String
        }
        let last_error: LastError
    }
    
    let data: StatusData
    let code: Int
    let msg: String
}

// MARK: - 训练建议模型
struct TrainingAdvice: Codable {
    let performanceLevel: String
    let issues: [String]
    let suggestions: [String]
    let improvements: [String]
    let recordId: UUID
    let recordType: ArcheryRecordType
    let timestamp: Date
}

// MARK: - 错误处理
enum CozeError: Error {
    case requestFailed(statusCode: Int)
    case invalidResponse
    case invalidData
    case timeout
    
    var localizedDescription: String {
        switch self {
        case .requestFailed(let code):
            return "请求失败，错误码：\(code)"
        case .invalidResponse:
            return "无效的响应数据"
        case .invalidData:
            return "数据解析失败"
        case .timeout:
            return "请求超时"
        }
    }
}

// 添加记录类型枚举
enum ArcheryRecordType: String, Codable {
    case single
    case group
}

// 修改训练数据模型
struct ArcheryTrainingData: Codable {
    let recordId: UUID
    let recordType: ArcheryRecordType
    let totalScore: Int
    let averagePerArrow: Double
    let scores: [String]  // 统一使用字符串数组存储分数
    let scoreDistribution: [String: Int]
    let metadata: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case recordId
        case recordType
        case totalScore
        case averagePerArrow
        case scores
        case scoreDistribution
        case metadata
    }
}