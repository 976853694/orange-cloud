//
//  StatusDot.swift
//  Orange Cloud
//
//  Zone 状态指示点：active 绿 / pending 橙 / paused 红，外圈同色光晕（设计稿 StatusDot）。
//

import SwiftUI

struct StatusDot: View {

    let status: String
    var size: CGFloat = 8

    private var color: Color {
        switch status {
        case "active":                    .green
        case "pending", "initializing":   .orange
        default:                          .red
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(color.opacity(0.13))
                    .frame(width: size + 6, height: size + 6)
            )
    }
}

#Preview {
    HStack(spacing: 16) {
        StatusDot(status: "active")
        StatusDot(status: "pending")
        StatusDot(status: "paused")
    }
    .padding()
}
