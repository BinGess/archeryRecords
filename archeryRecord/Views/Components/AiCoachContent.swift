import SwiftUI

struct AiCoachContent: View {
    let record: ArcheryRecord
    @State private var trainingAdvice: TrainingAdvice?
    @State private var isLoadingAdvice = false
    @State private var adviceError: Error?
    
    private let cozeService = CozeService()
    
    var body: some View {
        VStack(spacing: SharedStyles.itemSpacing) {
            // 标题栏
            HStack {
                Text("AI教练")
                    .sharedTextStyle(SharedStyles.Text.title)
                Spacer()
                Button(action: {
                    // 已按需求关闭 AI 教练刷新请求，避免再触发服务端智能体调用。
                    Task {
                        // await loadTrainingAdvice(for: record, forceRefresh: true)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(SharedStyles.primaryColor)
                }
            }
            .padding(.horizontal)
            .padding(.top,20)
            
            Divider()
            // 内容区域
            VStack(spacing: SharedStyles.itemSpacing) {
                if isLoadingAdvice {
                    VStack {
                        BreathingLoadingView()
                            .frame(width: 50, height: 50)
//                        Text("AI正在分析...")
//                            .font(SharedStyles.Text.body)
//                            .foregroundColor(.gray)
//                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .padding()
                } else if let advice = trainingAdvice {
                    // 1. 当前水平评估
                    VStack(alignment: .leading, spacing: 8) {
                        Label("当前水平评估", systemImage: "chart.bar.fill")
                            .font(SharedStyles.Text.subtitle)
                            .foregroundColor(SharedStyles.primaryColor)
                        
                        markdownText(advice.performanceLevel)
                            .sharedTextStyle(SharedStyles.Text.body, lineSpacing: SharedStyles.bodyLineSpacing)
                            .padding(.leading)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // 2. 存在问题
                    VStack(alignment: .leading, spacing: 8) {
                        Label("存在问题", systemImage: "exclamationmark.triangle.fill")
                            .font(SharedStyles.Text.subtitle)
                            .foregroundColor(.orange)
                        
                        ForEach(advice.issues, id: \.self) { issue in
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("•")
                                    .foregroundColor(.orange)
                                markdownText(issue)
                                    .sharedTextStyle(SharedStyles.Text.body, lineSpacing: SharedStyles.bodyLineSpacing)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // 3. 改进建议
                    VStack(alignment: .leading, spacing: 8) {
                        Label("改进建议", systemImage: "lightbulb.fill")
                            .font(SharedStyles.Text.subtitle)
                            .foregroundColor(.yellow)
                        
                        ForEach(advice.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("•")
                                    .foregroundColor(.yellow)
                                markdownText(suggestion)
                                    .sharedTextStyle(SharedStyles.Text.body, lineSpacing: SharedStyles.bodyLineSpacing)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding(.vertical, 8)
                } else if adviceError != nil {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 40))
                        Text("AI教练功能已关闭")
                            .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                        Button("点击再试") {
                            Task {
                                // 已按需求关闭 AI 教练重试请求。
                                // await loadTrainingAdvice(for: record, forceRefresh: true)
                            }
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding()
        }
        .background(SharedStyles.backgroundColor)
        .cornerRadius(SharedStyles.cornerRadius)
        .shadow(
            color: SharedStyles.Shadow.light,
            radius: 8,
            x: 0,
            y: 2
        )
        .padding(.horizontal)
        .task {
            // 先尝试从本地加载
            if let stored = TrainingAdviceStorage.get(for: record.id, type: .single) {
                trainingAdvice = stored
            } else {
                // 已按需求关闭 AI 教练自动请求，避免进入页面时触发服务端智能体调用。
                // await loadTrainingAdvice(for: record)
            }
        }
    }
    
    // 添加一个辅助方法来处理 Markdown 文本
    private func markdownText(_ text: String) -> Text {
        let components = text.components(separatedBy: "**")
        return components.enumerated().reduce(Text("")) { result, pair in
            let (index, component) = pair
            if index % 2 == 0 {
                return result + Text(component)
            } else {
                return result + Text(component).bold()
            }
        }
    }
    
    // 加载训练建议
    private func loadTrainingAdvice(for record: ArcheryRecord, forceRefresh: Bool = false) async {
        if isLoadingAdvice { return }
        // 如果已有建议且不强制刷新，则直接返回
        if trainingAdvice != nil && !forceRefresh { return }
        
        await MainActor.run {
            isLoadingAdvice = false
            adviceError = NSError(
                domain: "AICoach",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "AI教练功能已关闭"]
            )
        }

        // 已按需求关闭服务端 AI 教练请求，保留原逻辑注释以便后续恢复。
        // isLoadingAdvice = true
        // adviceError = nil
        //
        // Task.detached(priority: .background) {
        //     do {
        //         let trainingData = cozeService.prepareTrainingData(record: record)
        //         let advice = try await cozeService.getTrainingAdvice(data: trainingData)
        //
        //         if advice.performanceLevel.contains("很抱歉") ||
        //            advice.performanceLevel.contains("出现错误") ||
        //            advice.performanceLevel.contains("无法为你提供") {
        //             throw NSError(
        //                 domain: "AICoach",
        //                 code: 1001,
        //                 userInfo: [NSLocalizedDescriptionKey: "似乎教练有点忙，暂时无法给出建议"]
        //             )
        //         }
        //
        //         let adviceWithMeta = TrainingAdvice(
        //             performanceLevel: advice.performanceLevel,
        //             issues: advice.issues,
        //             suggestions: advice.suggestions,
        //             improvements: advice.improvements,
        //             recordId: record.id,
        //             recordType: .single,
        //             timestamp: Date()
        //         )
        //
        //         TrainingAdviceStorage.save(adviceWithMeta)
        //
        //         await MainActor.run {
        //             trainingAdvice = adviceWithMeta
        //             isLoadingAdvice = false
        //         }
        //     } catch {
        //         await MainActor.run {
        //             adviceError = error
        //             isLoadingAdvice = false
        //         }
        //     }
        // }
    }
}

struct AiCoachGroupContent: View {
    let record: ArcheryGroupRecord
    @State private var trainingAdvice: TrainingAdvice?
    @State private var isLoadingAdvice = false
    @State private var adviceError: Error?
    
    private let cozeService = CozeService()
    
    var body: some View {
        VStack(spacing: SharedStyles.itemSpacing) {
            // 标题栏
            HStack {
                Text("AI教练")
                    .sharedTextStyle(SharedStyles.Text.title)
                Spacer()
                Button(action: {
                    // 已按需求关闭 AI 教练刷新请求，避免再触发服务端智能体调用。
                    Task {
                        // await loadTrainingAdvice(for: record, forceRefresh: true)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(SharedStyles.primaryColor)
                }
            }
            .padding(.horizontal)
            .padding(.top,20)
            
            Divider()
            
            // 内容区域
            VStack(spacing: SharedStyles.itemSpacing) {
                if isLoadingAdvice {
                    VStack {
                        BreathingLoadingView()
                            .frame(width: 50, height: 50)
//                        Text("AI正在分析...")
//                            .font(SharedStyles.Text.body)
//                            .foregroundColor(.gray)
//                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .padding()
                } else if let advice = trainingAdvice {
                    // 1. 当前水平评估
                    VStack(alignment: .leading, spacing: 8) {
                        Label("当前水平评估", systemImage: "chart.bar.fill")
                            .font(SharedStyles.Text.subtitle)
                            .foregroundColor(SharedStyles.primaryColor)
                        
                        markdownText(advice.performanceLevel)
                            .sharedTextStyle(SharedStyles.Text.body, lineSpacing: SharedStyles.bodyLineSpacing)
                            .padding(.leading)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // 2. 存在问题
                    VStack(alignment: .leading, spacing: 8) {
                        Label("存在问题", systemImage: "exclamationmark.triangle.fill")
                            .font(SharedStyles.Text.subtitle)
                            .foregroundColor(.orange)
                        
                        ForEach(advice.issues, id: \.self) { issue in
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("•")
                                    .foregroundColor(.orange)
                                markdownText(issue)
                                    .sharedTextStyle(SharedStyles.Text.body, lineSpacing: SharedStyles.bodyLineSpacing)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // 3. 改进建议
                    VStack(alignment: .leading, spacing: 8) {
                        Label("改进建议", systemImage: "lightbulb.fill")
                            .font(SharedStyles.Text.subtitle)
                            .foregroundColor(.yellow)
                        
                        ForEach(advice.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("•")
                                    .foregroundColor(.yellow)
                                markdownText(suggestion)
                                    .sharedTextStyle(SharedStyles.Text.body, lineSpacing: SharedStyles.bodyLineSpacing)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding(.vertical, 8)
                } else if adviceError != nil {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 40))
                        Text("AI教练功能已关闭")
                            .sharedTextStyle(SharedStyles.Text.bodyEmphasis)
                        Button("点击再试") {
                            Task {
                                // 已按需求关闭 AI 教练重试请求。
                                // await loadTrainingAdvice(for: record, forceRefresh: true)
                            }
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding()
        }
        .background(SharedStyles.backgroundColor)
        .cornerRadius(SharedStyles.cornerRadius)
        .shadow(
            color: SharedStyles.Shadow.light,
            radius: 8,
            x: 0,
            y: 2
        )
        .padding(.horizontal)
        .task {
            // 先尝试从本地加载
            if let stored = TrainingAdviceStorage.get(for: record.id, type: .group) {
                trainingAdvice = stored
            } else {
                // 已按需求关闭 AI 教练自动请求，避免进入页面时触发服务端智能体调用。
                // await loadTrainingAdvice(for: record)
            }
        }
    }
    
    // 添加一个辅助方法来处理 Markdown 文本
    private func markdownText(_ text: String) -> Text {
        let components = text.components(separatedBy: "**")
        return components.enumerated().reduce(Text("")) { result, pair in
            let (index, component) = pair
            if index % 2 == 0 {
                return result + Text(component)
            } else {
                return result + Text(component).bold()
            }
        }
    }
    
    // 加载训练建议
    private func loadTrainingAdvice(for record: ArcheryGroupRecord, forceRefresh: Bool = false) async {
        if isLoadingAdvice { return }
        // 如果已有建议且不强制刷新，则直接返回
        if trainingAdvice != nil && !forceRefresh { return }
        
        await MainActor.run {
            isLoadingAdvice = false
            adviceError = NSError(
                domain: "AICoach",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "AI教练功能已关闭"]
            )
        }

        // 已按需求关闭服务端 AI 教练请求，保留原逻辑注释以便后续恢复。
        // isLoadingAdvice = true
        // adviceError = nil
        //
        // Task.detached(priority: .background) {
        //     do {
        //         let trainingData = cozeService.prepareGroupTrainingData(record: record)
        //         let advice = try await cozeService.getTrainingAdvice(data: trainingData)
        //
        //         if advice.performanceLevel.contains("很抱歉") ||
        //            advice.performanceLevel.contains("出现错误") ||
        //            advice.performanceLevel.contains("无法为你提供") {
        //             throw NSError(
        //                 domain: "AICoach",
        //                 code: 1001,
        //                 userInfo: [NSLocalizedDescriptionKey: "似乎教练有点忙，暂时无法给出建议"]
        //             )
        //         }
        //
        //         let adviceWithMeta = TrainingAdvice(
        //             performanceLevel: advice.performanceLevel,
        //             issues: advice.issues,
        //             suggestions: advice.suggestions,
        //             improvements: advice.improvements,
        //             recordId: record.id,
        //             recordType: .group,
        //             timestamp: Date()
        //         )
        //
        //         TrainingAdviceStorage.save(adviceWithMeta)
        //
        //         await MainActor.run {
        //             trainingAdvice = adviceWithMeta
        //             isLoadingAdvice = false
        //         }
        //     } catch {
        //         await MainActor.run {
        //             adviceError = error
        //             isLoadingAdvice = false
        //         }
        //     }
        // }
    }
}

// 预览
//struct AiCoachContent_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockRecord = ArcheryRecord(
//            id: UUID(),
//            date: Date(),
//            bowType: "复合弓",
//            distance: "18米",
//            targetType: "标准靶",
//            scores: ["10", "9", "X", "8", "M", "9"]
//        )
//        
//        AiCoachContent(record: mockRecord)
//            .previewLayout(.sizeThatFits)
//            .padding()
//    }
//}
