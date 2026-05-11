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
        case .assistant:
            VStack(alignment: .leading, spacing: 14) {
                Text(displayedText)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                if !(isLast && isGenerating) && !message.text.isEmpty {
                    HStack(spacing: 14) {
                        AssistantActionButton(symbol: "doc.on.doc") {
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(message.text, forType: .string)
                        }
                        AssistantActionButton(symbol: "crop") {}
                        AssistantActionButton(symbol: "square.and.arrow.up") {}
                        AssistantActionButton(symbol: "ellipsis") {}
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 60)
        }
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
