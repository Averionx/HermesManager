import SwiftUI

struct ModelGlassCard<Content: View>: View {
    var tint: Color = SetupPalette.emerald
    var opacity: Double = 0.09
    var cornerRadius: CGFloat = 20
    var borderColor: Color = DesignTokens.borderSubtle
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(DiffusePanelBackground(cornerRadius: cornerRadius, tint: tint, opacity: opacity))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(cornerRadius)
    }
}

struct ModelPageHeader: View {
    let title: String
    let subtitle: String
    let updatedAt: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 18) {
                titleBlock
                Spacer(minLength: 16)
                metaBlock
            }

            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                metaBlock
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(DesignTokens.textPrimary)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignTokens.textTertiary)
                .lineSpacing(3)
        }
    }

    private var metaBlock: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                Text(updatedAt.isEmpty ? "等待刷新" : "最后刷新：\(updatedAt)")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(DesignTokens.textTertiary)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black.opacity(0.82))
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(SetupPalette.emerald)
                        .cornerRadius(DesignTokens.radiusPill)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ModelSummaryCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let accent: Color

    var body: some View {
        ModelGlassCard(tint: accent, opacity: 0.075, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(accent)
                        .frame(width: 38, height: 38)
                        .background(accent.opacity(0.12))
                        .cornerRadius(14)

                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignTokens.textMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(value)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 126, maxHeight: 126, alignment: .topLeading)
        }
    }
}

struct ModelStatusBadge: View {
    let status: ModelHealthStatus
    var title: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .bold))
            Text(title ?? status.rawValue)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(status.accent)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(status.accent.opacity(0.10))
        .cornerRadius(DesignTokens.radiusPill)
    }
}

struct ModelKindBadge: View {
    let text: String
    var accent: Color = SetupPalette.cyan

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(accent)
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background(accent.opacity(0.10))
            .cornerRadius(DesignTokens.radiusPill)
    }
}

struct LatencyBadge: View {
    let latencyMS: Int?
    let status: ModelHealthStatus

    var body: some View {
        Text(latencyMS.map { "\($0)ms" } ?? "—")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(status == .healthy ? SetupPalette.emerald : status.accent)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background((status == .healthy ? SetupPalette.emerald : status.accent).opacity(0.08))
            .cornerRadius(DesignTokens.radiusPill)
    }
}

struct ModelActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accent)
                    .frame(width: 42, height: 42)
                    .background(accent.opacity(0.12))
                    .cornerRadius(14)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textMuted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
            .background(DiffusePanelBackground(cornerRadius: 18, tint: accent, opacity: hovering ? 0.13 : 0.075))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(hovering ? accent.opacity(0.32) : DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(18)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct ModelChip: View {
    let model: ModelInfoItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Circle()
                    .fill(model.status.accent)
                    .frame(width: 6, height: 6)
                Text(model.name)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if model.isCurrent {
                    Text("当前使用")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black.opacity(0.82))
                        .padding(.horizontal, 6)
                        .frame(height: 18)
                        .background(SetupPalette.emerald)
                        .cornerRadius(DesignTokens.radiusPill)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(isSelected || model.isCurrent ? SetupPalette.emerald.opacity(0.12) : DesignTokens.surface2.opacity(0.52))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected || model.isCurrent ? SetupPalette.emerald.opacity(0.30) : DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(8)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityAction(named: Text("打开")) { action() }
    }
}

struct ModelSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(DesignTokens.textMuted)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignTokens.textPrimary)
        }
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(DesignTokens.surface2.opacity(0.56))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(13)
    }
}

struct ModelSystemPillButton: View {
    let title: String
    let icon: String
    let accent: Color
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(filled ? .black.opacity(0.84) : DesignTokens.textPrimary)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity)
            .frame(minWidth: 148)
            .frame(height: 38)
            .background(filled ? accent : DesignTokens.surface2.opacity(0.62))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(filled ? Color.clear : DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(13)
        }
        .buttonStyle(.plain)
    }
}

struct ModelProgressBar: View {
    let value: Int
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DesignTokens.surface3.opacity(0.72))
                Capsule()
                    .fill(accent)
                    .frame(width: proxy.size.width * CGFloat(max(0, min(value, 100))) / 100)
            }
        }
        .frame(height: 6)
    }
}
