import Foundation

struct MarkdownText {
    enum Style {
        case normal
        case bold
        case italic
        case bullet
        case numbered
    }
    
    let text: String
    let style: Style
}

struct MarkdownSection {
    let title: String
    let content: [MarkdownText]
}

class MarkdownParser {
    static func parse(_ text: String) -> [MarkdownSection] {
        var sections: [MarkdownSection] = []
        var currentTitle = ""
        var currentContent: [MarkdownText] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.range(of: "^\\d+\\.\\s+.*$", options: .regularExpression) != nil {
                // 保存之前的部分
                if !currentTitle.isEmpty && !currentContent.isEmpty {
                    sections.append(MarkdownSection(title: currentTitle, content: currentContent))
                }
                
                // 开始新的部分
                currentTitle = trimmedLine.replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression)
                currentContent = []
            } else if !trimmedLine.isEmpty {
                // 解析行内格式
                let style: MarkdownText.Style
                var content = trimmedLine
                
                if trimmedLine.hasPrefix("- ") {
                    style = .bullet
                    content = String(trimmedLine.dropFirst(2))
                } else if trimmedLine.hasPrefix("**") && trimmedLine.hasSuffix("**") {
                    style = .bold
                    content = String(trimmedLine.dropFirst(2).dropLast(2))
                } else if trimmedLine.hasPrefix("*") && trimmedLine.hasSuffix("*") {
                    style = .italic
                    content = String(trimmedLine.dropFirst(1).dropLast(1))
                } else {
                    style = .normal
                }
                
                currentContent.append(MarkdownText(text: content, style: style))
            }
        }
        
        // 添加最后一部分
        if !currentTitle.isEmpty && !currentContent.isEmpty {
            sections.append(MarkdownSection(title: currentTitle, content: currentContent))
        }
        
        return sections
    }
} 