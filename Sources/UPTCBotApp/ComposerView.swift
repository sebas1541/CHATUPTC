import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let canSend: Bool
    let isGenerating: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            plusButton
            inputField
            trailingButton
        }
    }

    private var plusButton: some View {
        Button {
            // attach (placeholder)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.primary.opacity(0.07), in: .circle)
        }
        .buttonStyle(.plain)
    }

    private var inputField: some View {
        TextField("Ask anything", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .lineLimit(1...6)
            .focused(isFocused)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.primary.opacity(0.07), in: .rect(cornerRadius: 18))
            .onSubmit {
                if canSend { onSend() }
            }
            .onAppear { isFocused.wrappedValue = true }
    }

    @ViewBuilder
    private var trailingButton: some View {
        if isGenerating {
            Button(action: onStop) {
                ZStack {
                    Circle().fill(Color.primary.opacity(0.07))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary)
                        .frame(width: 10, height: 10)
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Detener generación")
        } else {
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(canSend ? Color.white : .secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        canSend ? Color.primary : Color.primary.opacity(0.07),
                        in: .circle
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .keyboardShortcut(.return, modifiers: [.command])
        }
    }
}
