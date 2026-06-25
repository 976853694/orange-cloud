//
//  PurgeByURLSheet.swift
//  Orange Cloud
//
//  按 URL 清理缓存（单文件 purge）。每行一个完整 URL，单次最多 30 个。
//

import SwiftUI

struct PurgeByURLSheet: View {

    let zoneName: String
    /// 交给 ViewModel 执行；调用方负责实际的 purge 与错误提示
    let onPurge: ([String]) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var isPurging = false

    private static let maxURLs = 30

    /// 逐行拆分、去空白、过滤空行
    private var urls: [String] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var overLimit: Bool { urls.count > Self.maxURLs }

    private var isValid: Bool {
        !urls.isEmpty && !overLimit &&
        urls.allSatisfy { $0.hasPrefix("http://") || $0.hasPrefix("https://") }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("每行一个完整 URL，单次最多 \(Self.maxURLs) 个。例如 https://\(zoneName)/style.css")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $text)
                        .font(.callout.monospaced())
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .glassIsland(cornerRadius: OCLayout.chipRadius)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    if !urls.isEmpty {
                        Text("\(urls.count) / \(Self.maxURLs)")
                            .font(.caption)
                            .foregroundStyle(overLimit ? Color.red : Color.secondary)
                    }
                }
                .padding()
            }
            .background { SkyBackground() }
            .navigationTitle("按 URL 清理缓存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(isPurging)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isPurging {
                        ProgressView()
                    } else {
                        Button("清理") {
                            let targets = urls
                            Task {
                                isPurging = true
                                await onPurge(targets)
                                isPurging = false
                                dismiss()
                            }
                        }
                        .disabled(!isValid)
                    }
                }
            }
        }
    }
}
