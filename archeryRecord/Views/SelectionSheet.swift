import SwiftUI

struct SelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let options: [String]
    @Binding var selectedOption: String
    let isFromScoreInput: Bool // 添加标识来源的参数

    private var accentColor: Color {
        isFromScoreInput ? SharedStyles.primaryColor : SharedStyles.secondaryColor
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        dismiss()
                    }) {
                        HStack {
                            if TargetTypeDisplay.isKnownTargetType(option) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(TargetTypeDisplay.primaryTitle(for: option))
                                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: SharedStyles.primaryTextColor)

                                    if let subtitle = TargetTypeDisplay.subtitle(for: option) {
                                        Text(subtitle)
                                            .sharedTextStyle(SharedStyles.Text.footnote, color: SharedStyles.secondaryTextColor)
                                    }
                                }
                            } else {
                                Text(option)
                            }
                            Spacer()
                            if option == selectedOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                    .foregroundColor(SharedStyles.primaryTextColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(SharedStyles.backgroundColor)
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
                        .font(SharedStyles.Text.title)
                        .foregroundColor(SharedStyles.primaryTextColor)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(L10n.Common.back)
                        }
                        .foregroundColor(SharedStyles.primaryTextColor)
                    }
                }
            }
            #if os(iOS)
            .toolbarBackground(SharedStyles.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            #else
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(SharedStyles.Text.title)
                        .foregroundColor(SharedStyles.primaryTextColor)
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(L10n.Common.back)
                        }
                        .foregroundColor(SharedStyles.primaryTextColor)
                    }
                }
            }
            #endif
        }
    }
}

#Preview {
    SelectionSheet(
        title: L10n.GroupInput.selectBowType,
        options: L10n.Options.BowType.all,
        selectedOption: .constant(L10n.Options.BowType.compound),
        isFromScoreInput: true
    )
}
