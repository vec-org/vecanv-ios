// Copyright 2026 Vecanv
// SPDX-License-Identifier: MIT

import SwiftUI
import v_08

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

    private let pollInterval: TimeInterval = 2.0

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let root = viewModel.componentTree {
                ScrollView {
                    A2UIComponentView_V08(node: root, viewModel: viewModel)
                        .padding()
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
            let messages = try JSONDecoder().decode([ServerToClientMessage_V08].self, from: data)
            let fresh = SurfaceViewModel_V08()
            var surface: String?
            for m in messages {
                try fresh.processMessage(m)
                if let br = m.beginRendering {
                    surface = br.surfaceId
                }
            }
            await MainActor.run {
                self.viewModel = fresh
                self.lastUpdate = Date()
                self.lastError = nil
                if let surface { self.activeSurface = surface }
            }
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }
    }
}
