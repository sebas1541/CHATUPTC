import SwiftUI
import AppKit

struct ComposerView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let canSend: Bool
    let isGenerating: Bool
    let attachment: URL?
    let onSend: () -> Void
    let onStop: () -> Void
    let onAttachImage: () -> Void
    let onRemoveAttachment: () -> Void

    @State private var showingPlusMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let attachment {
                attachmentPreview(url: attachment)
            }
            HStack(spacing: 10) {
                plusButton
                inputField
                trailingButton
            }
        }
    }

    private var plusButton: some View {
        Button {
            showingPlusMenu = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.primary.opacity(0.07), in: .circle)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPlusMenu, arrowEdge: .top) {
            plusMenuContent
        }
    }

    private var plusMenuContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuItem(
                icon: "photo.fill",
                iconColor: .blue,
                title: "Adjuntar imagen",
                subtitle: "PNG, JPG, HEIC, TIFF, GIF"
            ) {
                showingPlusMenu = false
                onAttachImage()
            }
        }
        .padding(8)
        .frame(width: 280)
    }

    private func menuItem(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle())
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

    private func attachmentPreview(url: URL) -> some View {
        HStack(spacing: 8) {
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.07))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("Imagen adjunta")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onRemoveAttachment) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quitar imagen")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

private struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.10) : Color.clear)
            )
            .background(
                MenuHoverBackground()
            )
    }
}

private struct MenuHoverBackground: View {
    @State private var hovering = false
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(hovering ? Color.primary.opacity(0.06) : Color.clear)
            .onHover { hovering = $0 }
    }
}
