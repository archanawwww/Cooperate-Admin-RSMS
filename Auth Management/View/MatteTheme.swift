import SwiftUI

public enum MatteTheme {
    public enum Colors {
        public static let primaryBackground = Color(red: 250/255, green: 248/255, blue: 244/255) // #FAF8F4
        public static let loginBackground = Color(red: 246/255, green: 243/255, blue: 237/255) // #F6F3ED
        public static let dashboardBackground = Color(red: 242/255, green: 239/255, blue: 233/255) // #F2EFE9
        public static let secondaryBackground = Color(red: 245/255, green: 242/255, blue: 237/255) // #F5F2ED
        public static let surface = Color.white // #FFFFFF
        public static let border = Color(red: 230/255, green: 226/255, blue: 219/255) // #E6E2DB
        public static let subtleAccent = Color(red: 240/255, green: 236/255, blue: 230/255) // #F0ECE6
        public static let textPrimary = Color(red: 44/255, green: 42/255, blue: 40/255) // #2C2A28
        public static let textSecondary = Color(red: 122/255, green: 117/255, blue: 110/255) // #7A756E
        public static let textTertiary = Color(red: 163/255, green: 157/255, blue: 149/255) // #A39D95
        public static let primaryGold = Color(red: 187/255, green: 140/255, blue: 11/255) // #BB8C0B
        public static let goldLight = Color(red: 243/255, green: 231/255, blue: 193/255) // #F3E7C1
        public static let success = Color(red: 46/255, green: 125/255, blue: 50/255) // #2E7D32
        public static let warning = Color(red: 245/255, green: 166/255, blue: 35/255) // #F5A623
        public static let error = Color(red: 229/255, green: 57/255, blue: 53/255) // #E53935
        public static let info = Color(red: 61/255, green: 90/255, blue: 254/255) // #3D5AFE

        public static let sandstone = subtleAccent
        public static let warmClay = textSecondary
        public static let burntSienna = primaryGold
        public static let ivoryMatte = secondaryBackground
        public static let espresso = textPrimary
        public static let goldenAmber = primaryGold
        public static let fogGlass = surface.opacity(0.82)
        
        public static func roleColor(for role: UserRole) -> Color {
            switch role {
            case .boutiqueManager: return primaryGold
            case .salesAssociate: return success
            case .corporateAdmin: return textPrimary
            case .inventoryController: return info
            }
        }
    }
}

public struct LiquidGlassCard: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(MatteTheme.Colors.fogGlass)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(MatteTheme.Colors.border.opacity(0.95), lineWidth: 1)
            )
            .shadow(color: MatteTheme.Colors.textPrimary.opacity(0.14), radius: 18, x: 0, y: 10)
    }
}

public struct MatteSurfaceCard: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(MatteTheme.Colors.surface.opacity(0.94))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(MatteTheme.Colors.border, lineWidth: 1)
            )
            .shadow(color: MatteTheme.Colors.textPrimary.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

public struct MatteImageBackground: ViewModifier {
    let imageName: String

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    MatteTheme.Colors.primaryBackground

                    GeometryReader { proxy in
                        Image(imageName)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .opacity(0.58)
                    }

                    MatteTheme.Colors.primaryBackground.opacity(0.38)
                }
                .ignoresSafeArea()
            }
    }
}

public extension View {
    func liquidGlassCard() -> some View {
        modifier(LiquidGlassCard())
    }

    func matteSurfaceCard() -> some View {
        modifier(MatteSurfaceCard())
    }

    func matteImageBackground(_ imageName: String) -> some View {
        modifier(MatteImageBackground(imageName: imageName))
    }
}

public struct MatteButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    
    public var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            action()
        }) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(MatteTheme.Colors.ivoryMatte)
                    .opacity(isLoading ? 0 : 1)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: MatteTheme.Colors.ivoryMatte))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(MatteTheme.Colors.espresso)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MatteTheme.Colors.primaryGold.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: MatteTheme.Colors.espresso.opacity(0.24), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
    }
}

public struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var textContentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    
    public var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding()
        .background(MatteTheme.Colors.surface.opacity(0.88))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MatteTheme.Colors.border, lineWidth: 1)
        )
        .foregroundColor(MatteTheme.Colors.textPrimary)
        .accentColor(MatteTheme.Colors.espresso)
    }
}
