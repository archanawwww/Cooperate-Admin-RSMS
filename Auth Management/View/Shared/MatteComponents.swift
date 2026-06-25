import SwiftUI

// MARK: - Matte Panel

extension View {

    func mattePanel() -> some View {
        self
            .padding(18)
            .background(MatteTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(MatteTheme.Colors.border, lineWidth: 1)
            )
    }

}

// MARK: - Primary Button

struct MattePrimaryButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {

        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed
                ? MatteTheme.Colors.espresso.opacity(0.7)
                : MatteTheme.Colors.espresso
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)

    }

}
