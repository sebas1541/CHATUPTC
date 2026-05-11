import SwiftUI
import AppKit

struct MessageView: View {
    let message: ChatMessage
    let isLast: Bool
    let isGenerating: Bool

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 6) {
                    ForEach(message.imagePaths, id: \.self) { path in
                        userImageThumbnail(path: path)
                    }
                    if !message.text.isEmpty {
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Color.primary.opacity(0.07),
                                in: .rect(cornerRadius: 18)
                            )
                            .textSelection(.enabled)
                    }
                }
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 14) {
                if isLast && isGenerating && message.text.isEmpty {
                    ThinkingIndicator()
                } else {
                    Text(displayedAttributed)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }

                if !(isLast && isGenerating) && !message.text.isEmpty {
                    HStack(spacing: 14) {
                        AssistantActionButton(symbol: "doc.on.doc") {
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(message.text, forType: .string)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 60)
        }
    }

    @ViewBuilder
    private func userImageThumbnail(path: String) -> some View {
        if let nsImage = NSImage(contentsOfFile: path) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.07))
                .frame(width: 140, height: 100)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 18))
                        Text("Imagen no encontrada")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.secondary)
                )
        }
    }

    private var displayedAttributed: AttributedString {
        let raw = displayedText
        // Durante streaming NO parseamos markdown: AttributedString(markdown:)
        // aloca pesado y se llama en cada chunk → leak de memoria. Solo
        // parseamos cuando el mensaje terminó de generar.
        guard !(isLast && isGenerating) else {
            return AttributedString(raw)
        }
        if let parsed = try? AttributedString(
            markdown: raw,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            return parsed
        }
        return AttributedString(raw)
    }

    private var displayedText: String {
        if isLast && isGenerating && message.text.isEmpty {
            return "…"
        }
        return message.text
    }
}

private struct AssistantActionButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Indicador "Pensando…" con tres puntos que pulsan en cascada
/// mientras esperamos el primer token del modelo.
private struct ThinkingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Thinking")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 5, height: 5)
                        .opacity(animating ? 1.0 : 0.25)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(i) * 0.2),
                            value: animating
                        )
                }
            }
        }
        .onAppear { animating = true }
    }
}
