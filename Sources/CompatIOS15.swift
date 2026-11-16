import SwiftUI
import UIKit

struct CompatVStackLayout {
    var alignment: HorizontalAlignment = .center
    var spacing: CGFloat? = nil
}

struct CompatHStackLayout {
    var alignment: VerticalAlignment = .center
    var spacing: CGFloat? = nil
}

struct CompatLayout {
    private let vertical: Bool
    private let hAlignment: HorizontalAlignment
    private let vAlignment: VerticalAlignment
    private let spacing: CGFloat?

    init(_ layout: CompatVStackLayout) {
        vertical = true
        hAlignment = layout.alignment
        vAlignment = .center
        spacing = layout.spacing
    }

    init(_ layout: CompatHStackLayout) {
        vertical = false
        hAlignment = .center
        vAlignment = layout.alignment
        spacing = layout.spacing
    }

    @ViewBuilder
    func callAsFunction<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if vertical {
            VStack(alignment: hAlignment, spacing: spacing, content: content)
        } else {
            HStack(alignment: vAlignment, spacing: spacing, content: content)
        }
    }
}

private struct LegacyOnChange<Value: Equatable>: ViewModifier {
    let value: Value
    let initial: Bool
    let action: (Value, Value) -> Void
    @State private var previous: Value?

    func body(content: Content) -> some View {
        content
            .onAppear {
                if initial { action(value, value) }
                previous = value
            }
            .onChange(of: value) { next in
                let old = previous ?? next
                previous = next
                action(old, next)
            }
    }
}

extension View {
    func onChangeCompat<Value: Equatable>(
        of value: Value, initial: Bool = false,
        perform: @escaping (Value, Value) -> Void
    ) -> some View {
        modifier(LegacyOnChange(value: value, initial: initial, action: perform))
    }
}

private struct SharedFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ActivityController: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct LegacyShareButton<Label: View>: View {
    let item: () -> URL?
    let label: () -> Label
    @State private var file: SharedFile?

    var body: some View {
        Button {
            if let url = item() { file = SharedFile(url: url) }
        } label: {
            label()
        }
        .sheet(item: $file) { selected in
            ActivityController(url: selected.url)
        }
    }
}
