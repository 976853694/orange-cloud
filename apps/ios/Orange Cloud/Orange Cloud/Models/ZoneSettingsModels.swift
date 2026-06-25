//
//  ZoneSettingsModels.swift
//  Orange Cloud
//
//  Zone 设置（security_level / development_mode）与缓存清理。
//

import Foundation

/// GET/PATCH /zones/{id}/settings/{setting} 的 result
nonisolated struct ZoneSetting: Codable, Sendable {
    let id:    String?
    let value: String
}

nonisolated struct ZoneSettingUpdate: Codable, Sendable {
    let value: String
}

/// POST /zones/{id}/purge_cache —— 全量清理
nonisolated struct PurgeRequest: Codable, Sendable {
    let purgeEverything: Bool

    enum CodingKeys: String, CodingKey {
        case purgeEverything = "purge_everything"
    }
}

/// POST /zones/{id}/purge_cache —— 按单文件 URL 清理
/// （2025-04 起所有套餐可用，单次最多 30 个 URL）
nonisolated struct PurgeFilesRequest: Codable, Sendable {
    let files: [String]
}

nonisolated struct PurgeResult: Codable, Sendable {
    let id: String?
}
