import SwiftUI

struct ProBadgeView: View {
    var iconSize: CGFloat = 10
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 5

    var body: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: iconSize, weight: .black))
            .foregroundStyle(Color(red: 0.36, green: 0.23, blue: 0.02))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.00, green: 0.92, blue: 0.44),
                                Color(red: 0.98, green: 0.76, blue: 0.17)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    ProBadgeView()
        .padding()
}
