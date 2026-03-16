import SwiftUI

struct NavigationBarModifier: ViewModifier {
    let title: String
    let leadingButton: (() -> Void)?
    let trailingButton: (() -> Void)?
    let trailingTitle: String?
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(
        title: String,
        leadingButton: (() -> Void)? = nil,
        trailingButton: (() -> Void)? = nil,
        trailingTitle: String? = nil,
        backgroundColor: Color = SharedStyles.backgroundColor,
        foregroundColor: Color = SharedStyles.primaryTextColor
    ) {
        self.title = title
        self.leadingButton = leadingButton
        self.trailingButton = trailingButton
        self.trailingTitle = trailingTitle
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let action = leadingButton {
                        Button(action: action) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text(L10n.Common.back)
                            }
                            .foregroundColor(foregroundColor)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(SharedStyles.Text.title)
                        .foregroundColor(foregroundColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let action = trailingButton {
                        if let title = trailingTitle {
                            Button(action: action) {
                                Text(title)
                                    .foregroundColor(foregroundColor)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                        } else {
                            Button(action: action) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(foregroundColor)
                            }
                        }
                    }
                }
            }
            #if os(iOS)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            #else
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if let action = leadingButton {
                        Button(action: action) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text(L10n.Common.back)
                            }
                            .foregroundColor(foregroundColor)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(SharedStyles.Text.title)
                        .foregroundColor(foregroundColor)
                }
                
                ToolbarItem(placement: .automatic) {
                    if let action = trailingButton {
                        if let title = trailingTitle {
                            Button(action: action) {
                                Text(title)
                                    .foregroundColor(foregroundColor)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                        } else {
                            Button(action: action) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(foregroundColor)
                            }
                        }
                    }
                }
            }
            #endif
    }
}

extension View {
    func customNavigationBar(
        title: String,
        leadingButton: (() -> Void)? = nil,
        trailingButton: (() -> Void)? = nil,
        trailingTitle: String? = nil,
        backgroundColor: Color = SharedStyles.backgroundColor,
        foregroundColor: Color = SharedStyles.primaryTextColor
    ) -> some View {
        self.modifier(NavigationBarModifier(
            title: title,
            leadingButton: leadingButton,
            trailingButton: trailingButton,
            trailingTitle: trailingTitle,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        ))
    }
}
