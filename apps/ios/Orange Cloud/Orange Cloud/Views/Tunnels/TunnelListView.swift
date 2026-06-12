//
//  TunnelListView.swift
//  Orange Cloud
//
//  Cloudflare Tunnel 列表与连接详情（P5，只读）。
//

import SwiftUI

struct TunnelListView: View {

    @Environment(SessionStore.self) private var session
    @State private var viewModel: TunnelListViewModel

    init(session: SessionStore) {
        _viewModel = State(initialValue: TunnelListViewModel(service: session.tunnelService))
    }

    var body: some View {
        Group {
            if viewModel.tunnels.isEmpty && viewModel.isLoading {
                SkeletonList(rows: 5)
            } else if viewModel.tunnels.isEmpty {
                ContentUnavailableView {
                    Label("没有隧道", systemImage: "arrow.triangle.2.circlepath")
                } description: {
                    Text("用 cloudflared 创建隧道后会显示在这里")
                }
            } else {
                List(viewModel.tunnels) { tunnel in
                    NavigationLink {
                        TunnelDetailView(tunnel: tunnel)
                    } label: {
                        TunnelRow(tunnel: tunnel)
                    }
                    .glassRow()
                }
                .scrollContentBackground(.hidden)
                .refreshable { await load() }
            }
        }
        .background { SkyBackground() }
        .navigationTitle("Cloudflare Tunnel")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .alert("加载失败", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    private func load() async {
        await session.ensureAccounts()
        guard let accountId = session.selectedAccount?.id else { return }
        await viewModel.load(accountId: accountId)
    }
}

// MARK: - 行

private struct TunnelRow: View {
    let tunnel: Tunnel

    var body: some View {
        HStack(spacing: 12) {
            TintIcon(systemImage: "arrow.triangle.2.circlepath", color: statusColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(tunnel.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(tunnel.statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let count = tunnel.connections?.count, count > 0 {
                        Text("· \(count) 个连接")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch tunnel.status {
        case "healthy":  .green
        case "degraded": .orange
        case "down":     .red
        default:         .gray
        }
    }
}

// MARK: - 详情（连接列表）

struct TunnelDetailView: View {

    let tunnel: Tunnel

    var body: some View {
        List {
            Section("信息") {
                LabeledContent("状态", value: tunnel.statusText)
                if let type = tunnel.tunType {
                    LabeledContent("类型", value: type)
                }
                if let remote = tunnel.remoteConfig {
                    LabeledContent("配置方式", value: remote ? String(localized: "远程（Dashboard）") : String(localized: "本地（config.yml）"))
                }
                if let created = WorkerScript.parseDate(tunnel.createdAt) {
                    LabeledContent("创建时间") {
                        Text(created, format: .dateTime.year().month().day())
                    }
                }
                LabeledContent("Tunnel ID") {
                    Text(tunnel.id)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }
            .glassRow()

            Section("活跃连接") {
                if let connections = tunnel.connections, !connections.isEmpty {
                    ForEach(Array(connections.enumerated()), id: \.offset) { _, connection in
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "antenna.radiowaves.left.and.right", color: .green, size: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(connection.coloName ?? String(localized: "未知节点"))
                                    .font(.callout.weight(.medium))
                                HStack(spacing: 6) {
                                    if let version = connection.clientVersion {
                                        Text("cloudflared \(version)")
                                    }
                                    if let opened = WorkerScript.parseDate(connection.openedAt) {
                                        Text(opened, format: .relative(presentation: .named))
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("没有活跃连接")
                        .foregroundStyle(.secondary)
                }
            }
            .glassRow()
        }
        .daybreakList()
        .navigationTitle(tunnel.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
