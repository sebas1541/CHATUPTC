import SwiftUI
import AppKit

/// Logo de UPTCBot (cóndor) cargado desde el bundle.
/// Cae a un ícono SF Symbol si el recurso no se encuentra (defensive).
struct UPTCLogo: View {
    let size: CGFloat

    var body: some View {
        if let url = Bundle.main.url(forResource: "logouptc", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        } else {
            // Fallback si el bundle no expone el recurso por alguna razón
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.45, weight: .light))
                    .foregroundStyle(.tint)
            }
            .frame(width: size, height: size)
        }
    }
}
