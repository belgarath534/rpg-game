import SwiftUI

enum Theme {
    static let background = Color(red: 0.07, green: 0.06, blue: 0.10)
    static let card = Color.white.opacity(0.06)
    static let sun = LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)

    static func color(for tone: Tone) -> Color {
        switch tone {
        case .normal: return .primary
        case .good: return .green
        case .bad: return Color(red: 1, green: 0.45, blue: 0.4)
        case .story: return Color(red: 1, green: 0.85, blue: 0.55)
        }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatBar: View {
    let label: String
    let symbol: String
    let value: Int
    let maximum: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: symbol).foregroundStyle(color)
                Text(label).font(.caption.bold())
                Spacer()
                Text("\(value)/\(maximum)").font(.caption.monospacedDigit())
            }
            ProgressView(value: Double(min(value, maximum)), total: Double(max(maximum, 1)))
                .tint(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(value) of \(maximum)")
    }
}

struct ActionButton: View {
    let title: String
    let symbol: String
    var tint: Color = .orange
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}

struct LogList: View {
    let entries: [LogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entries) { entry in
                Text(entry.text)
                    .font(.callout)
                    .foregroundStyle(Theme.color(for: entry.tone))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
