import SwiftUI

struct BreathingLoadingView: View {
    @State private var isShowingPrimary = true
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.7
    
    let primaryColor: Color
    let secondaryColor: Color
    let size: CGFloat
    let text: String
    
    init(
        primaryColor: Color = .orange,
        secondaryColor: Color = .purple,
        size: CGFloat = 40,
        text: String = "AI教练正在思考"
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.size = size
        self.text = text
    }
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                // 主色圆
                Circle()
                    .fill(primaryColor)
                    .frame(width: size, height: size)
                    .scaleEffect(isShowingPrimary ? scale : 0.5)
                    .opacity(isShowingPrimary ? opacity : 0)
                
                // 次色圆
                Circle()
                    .fill(secondaryColor)
                    .frame(width: size * 0.7, height: size * 0.7)
                    .scaleEffect(!isShowingPrimary ? scale : 0.5)
                    .opacity(!isShowingPrimary ? opacity : 0)
            }
            .animation(
                Animation.easeInOut(duration: 0.8),
                value: isShowingPrimary
            )
            .onAppear {
                // 启动定时器，交替显示两个圆
                let timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                    self.isShowingPrimary.toggle()
                    self.scale = self.scale == 1.0 ? 1.2 : 1.0
                    self.opacity = self.opacity == 0.7 ? 0.4 : 0.7
                }
                timer.fire()
            }
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
    }
}

// 预览
struct BreathingLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BreathingLoadingView()
            
            BreathingLoadingView(
                primaryColor: .blue,
                secondaryColor: .green,
                size: 50,
                text: "加载中..."
            )
            
            BreathingLoadingView(
                primaryColor: .purple,
                secondaryColor: .orange,
                size: 30,
                text: "请稍候..."
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
