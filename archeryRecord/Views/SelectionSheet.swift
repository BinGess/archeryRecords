import SwiftUI

struct SelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let options: [String]
    @Binding var selectedOption: String
    let isFromScoreInput: Bool // 添加标识来源的参数
    
    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option)
                            Spacer()
                            if option == selectedOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(isFromScoreInput ? .orange : .purple)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitleDisplayMode(.inline)
            #else
            .listStyle(PlainListStyle())
            #endif
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(L10n.Common.back)
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            #if os(iOS)
            .toolbarBackground(isFromScoreInput ? Color.orange : Color.purple, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            #else
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(L10n.Common.back)
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            #endif
        }
    }
}

#Preview {
    SelectionSheet(
        title: "选择弓种",
        options: ["复合弓", "反曲弓", "传统弓","光弓","美猎"],
        selectedOption: .constant("复合弓"),
        isFromScoreInput: true
    )
}
