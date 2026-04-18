// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import SwiftUI
import v_08

/// Applies a named theme to the A2UI component tree via SwiftUI style modifiers.
/// Theme name comes from `beginRendering.styles["theme"]` emitted by the producer.
struct VecanvThemeModifier: ViewModifier {
    let theme: String

    func body(content: Content) -> some View {
        switch theme {
        case "emerald":
            content
                .a2uiTextStyle(for: .h1, weight: .black, color: .green)
                .a2uiTextStyle(for: .h4, color: .green.opacity(0.8))
                .a2uiButtonStyle(for: .primary, backgroundColor: .green, cornerRadius: 14)
                .a2uiCardStyle(cornerRadius: 18, shadowRadius: 6, backgroundColor: .green.opacity(0.08))
        case "warm":
            content
                .a2uiTextStyle(for: .h1, weight: .black, color: .orange)
                .a2uiTextStyle(for: .h4, color: .orange.opacity(0.8))
                .a2uiButtonStyle(for: .primary, backgroundColor: .orange, cornerRadius: 14)
                .a2uiCardStyle(cornerRadius: 18, shadowRadius: 6, backgroundColor: .orange.opacity(0.1))
        case "dark":
            content
                .a2uiTextStyle(for: .h1, weight: .bold, color: .white)
                .a2uiTextStyle(for: .h4, color: .white.opacity(0.85))
                .a2uiTextStyle(for: .caption, color: .white.opacity(0.5))
                .a2uiButtonStyle(for: .primary, backgroundColor: .indigo, cornerRadius: 4)
                .a2uiCardStyle(cornerRadius: 4, shadowRadius: 0, backgroundColor: .black.opacity(0.7))
        default:
            content
        }
    }
}

/// Polls a remote Vecanv producer for the active scene and renders it.
///
/// Flip the active surface on the producer side (e.g. via curl from Mac):
///
///     curl -X POST http://<host>:8500/canvas/active_surface \
///          -H 'Content-Type: application/json' \
///          -d '{"name":"vectorhome-2-whoop"}'
///
/// This page will pick up the change within one poll interval.
struct LivePage: View {
    @AppStorage("vecanv.producerURL")
    private var producerURLString: String = "https://vectorhome-1.tail3698f2.ts.net/canvas/scene"

    @State private var viewModel = SurfaceViewModel_V08()
    @State private var lastUpdate: Date?
    @State private var lastError: String?
    @State private var polling = false
    @State private var editingURL = false
    @State private var activeSurface: String?
    @State private var currentTheme: String = "default"
    @State private var lastPayloadHash: Int = 0

    private let pollInterval: TimeInterval = 2.0

    /// Producer base URL (e.g. https://host/canvas/scene → https://host)
    private var producerBase: String {
        var s = producerURLString
        if let r = s.range(of: "/canvas/scene") { s.removeSubrange(r.lowerBound..<s.endIndex) }
        return s
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let root = viewModel.componentTree {
                ScrollView {
                    A2UIComponentView_V08(node: root, viewModel: viewModel)
                        .padding()
                        .modifier(VecanvThemeModifier(theme: currentTheme))
                        .environment(\.a2uiActionHandler) { action in
                            Task { await handleAction(action) }
                        }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Waiting for first scene from producer…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
            if let lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }
            footer
        }
        .navigationTitle("Live Producer")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editingURL = true } label: {
                    Label("Producer URL", systemImage: "link")
                }
            }
        }
        .sheet(isPresented: $editingURL) {
            editSheet
        }
        .task {
            polling = true
            await pollLoop()
        }
        .onDisappear { polling = false }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(polling ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text(polling ? "Live" : "Stopped")
                    .font(.caption.weight(.semibold))
                Spacer()
                if let activeSurface {
                    Text(activeSurface)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Text(producerURLString)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var footer: some View {
        HStack {
            if let lastUpdate {
                Text("Updated \(lastUpdate.formatted(date: .omitted, time: .standard))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("poll \(Int(pollInterval))s")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
    }

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("Producer URL") {
                    TextField("http://host:port/canvas/scene", text: $producerURLString)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                }
                Section("Reset") {
                    Button("Use vectorhome-1 default (HTTPS via Funnel)") {
                        producerURLString = "https://vectorhome-1.tail3698f2.ts.net/canvas/scene"
                    }
                    Button("Use Tailscale direct HTTP (tailnet only)") {
                        producerURLString = "http://100.115.221.117:8500/canvas/scene"
                    }
                }
            }
            .navigationTitle("Producer")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { editingURL = false }
                }
            }
        }
    }

    private func pollLoop() async {
        while polling && !Task.isCancelled {
            await fetchOnce()
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
    }

    private func fetchOnce() async {
        guard let url = URL(string: producerURLString) else {
            await MainActor.run { lastError = "Invalid URL" }
            return
        }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, _) = try await URLSession.shared.data(for: request)
            // Skip re-render when payload hasn't changed — preserves local
            // data-model state (like a half-typed input field) between polls.
            let hash = data.hashValue
            if hash == lastPayloadHash {
                await MainActor.run { self.lastUpdate = Date(); self.lastError = nil }
                return
            }
            let messages = try JSONDecoder().decode([ServerToClientMessage_V08].self, from: data)
            let fresh = SurfaceViewModel_V08()
            var surface: String?
            var theme: String?
            for m in messages {
                try fresh.processMessage(m)
                if let br = m.beginRendering {
                    surface = br.surfaceId
                    if let t = br.styles?["theme"] { theme = t }
                }
            }
            await MainActor.run {
                self.viewModel = fresh
                self.lastPayloadHash = hash
                self.lastUpdate = Date()
                self.lastError = nil
                if let surface { self.activeSurface = surface }
                if let theme { self.currentTheme = theme }
            }
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }
    }

    /// Action handler invoked by A2UI Button taps. Routes known action
    /// names to producer endpoints; generic enough that any producer
    /// can add new surfaces with interactive buttons without an iOS
    /// rebuild — as long as the action name maps to an existing route.
    private func handleAction(_ action: ResolvedAction) async {
        switch action.name {
        case "chat_send":
            await postChatSend(action)
        default:
            await MainActor.run { self.lastError = "Unknown action: \(action.name)" }
        }
    }

    private func postChatSend(_ action: ResolvedAction) async {
        // Extract the message string from the resolved action context.
        // AnyCodable is an enum in this codebase — pattern-match on .string.
        var message = ""
        if case .string(let s) = action.context["message"] ?? .null {
            message = s
        }
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let url = URL(string: "\(producerBase)/chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["message": trimmed])
        request.timeoutInterval = 60  // Claude can take a while
        do {
            _ = try await URLSession.shared.data(for: request)
            // Force next poll to re-fetch so the new conversation shows up
            await MainActor.run { self.lastPayloadHash = 0 }
            await fetchOnce()
        } catch {
            await MainActor.run { self.lastError = "chat_send failed: \(error.localizedDescription)" }
        }
    }
}
