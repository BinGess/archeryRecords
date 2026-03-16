import  SwiftUI

struct CustomBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text(L10n.Common.back)
            }
            .foregroundColor(SharedStyles.primaryTextColor)
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
    }
} 
