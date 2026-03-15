import  SwiftUI

struct CustomBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text(L10n.Common.back)
            }
            .foregroundColor(.white)
            .padding(.leading, 8)  // 统一的左边距
        }
    }
} 
