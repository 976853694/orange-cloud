//
//  DNSRecordFormView.swift
//  Orange Cloud
//
//  DNS 记录新建 / 编辑表单（Sheet）。
//

import SwiftUI
import SwiftData

struct DNSRecordFormView: View {

    let mode: DNSFormMode
    let viewModel: DNSListViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var type:     String = "A"
    @State private var name:     String = ""
    @State private var content:  String = ""
    @State private var proxied:  Bool   = true
    @State private var ttl:      Int    = 1
    @State private var priority: Int    = 10
    @State private var comment:  String = ""

    private static let recordTypes = ["A", "AAAA", "CNAME", "TXT", "MX", "NS"]
    private static let ttlOptions: [(label: String, value: Int)] = [
        (String(localized: "自动"), 1),
        (String(localized: "1 分钟"), 60),
        (String(localized: "5 分钟"), 300),
        (String(localized: "30 分钟"), 1800),
        (String(localized: "1 小时"), 3600),
        (String(localized: "1 天"), 86400),
    ]

    /// 只有 A / AAAA / CNAME 支持 Cloudflare 代理
    private var supportsProxy: Bool {
        ["A", "AAAA", "CNAME"].contains(type)
    }

    private var needsPriority: Bool {
        type == "MX"
    }

    private var isEditing: Bool {
        if case .edit = mode { true } else { false }
    }

    private var canSave: Bool {
        !name.isEmpty && !content.isEmpty && !viewModel.isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("类型") {
                    Picker("记录类型", selection: $type) {
                        ForEach(Self.recordTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isEditing)   // CF API 不允许修改记录类型
                }

                Section("记录") {
                    TextField("名称（@ 表示根域名）", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(contentPlaceholder, text: $content, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.callout.monospaced())
                    if needsPriority {
                        Stepper("优先级：\(priority)", value: $priority, in: 0...65535)
                    }
                }

                Section("解析设置") {
                    if supportsProxy {
                        Toggle(isOn: $proxied) {
                            Label {
                                Text("Cloudflare 代理")
                            } icon: {
                                ProxiedBadge(proxied: proxied)
                            }
                        }
                    }
                    if !(supportsProxy && proxied) {
                        Picker("TTL", selection: $ttl) {
                            ForEach(Self.ttlOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                    }
                }

                Section("备注") {
                    TextField("可选备注", text: $comment)
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? String(localized: "编辑记录") : String(localized: "新建记录"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("保存").fontWeight(.semibold)
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: populateIfEditing)
            .interactiveDismissDisabled(viewModel.isSaving)
        }
    }

    private var contentPlaceholder: String {
        switch type {
        case "A":     String(localized: "IPv4 地址，如 203.0.113.1")
        case "AAAA":  String(localized: "IPv6 地址，如 2001:db8::1")
        case "CNAME": String(localized: "目标域名，如 example.com")
        case "TXT":   String(localized: "文本内容")
        case "MX":    String(localized: "邮件服务器，如 mail.example.com")
        case "NS":    String(localized: "Name Server 域名")
        default:      String(localized: "记录值")
        }
    }

    private func populateIfEditing() {
        guard case .edit(let record) = mode else { return }
        type     = record.type
        name     = record.name
        content  = record.content
        proxied  = record.proxied
        ttl      = record.ttl
        priority = record.priority ?? 10
        comment  = record.comment ?? ""
    }

    private func save() async {
        viewModel.error = nil
        let record = CreateDNSRecord(
            type:     type,
            name:     name.trimmingCharacters(in: .whitespaces),
            content:  content.trimmingCharacters(in: .whitespacesAndNewlines),
            proxied:  supportsProxy && proxied,
            ttl:      supportsProxy && proxied ? 1 : ttl,   // 代理开启时 TTL 固定自动
            priority: needsPriority ? priority : nil,
            comment:  comment.isEmpty ? nil : comment
        )
        let recordId: String? = if case .edit(let cached) = mode { cached.id } else { nil }
        if await viewModel.save(recordId: recordId, record: record, context: modelContext) {
            dismiss()
        }
    }
}
