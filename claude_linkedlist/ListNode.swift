//
//  ListNode.swift
//  LinkedListApp
//
//  链条节点数据模型 - 支持模块配置
//

import SwiftUI

// 链条节点数据模型
class ChainNode: ObservableObject, Identifiable, Equatable {
    let id = UUID()
    @Published var next: ChainNode?
    @Published var position: CGPoint
    @Published var blockConfig: BlockConfig
    @Published var blockData: BlockData
    
    // UUID的简短显示版本（前6位）
    var shortUUID: String {
        return String(id.uuidString.prefix(6))
    }
    
    init(position: CGPoint = CGPoint.zero, config: BlockConfig = BlockConfig.availableBlocks[0]) {
        self.position = position
        self.blockConfig = config
        self.blockData = BlockData()
    }
    
    // 获取完整的显示文本
    func getFullDisplayText() -> String {
        let configText = blockData.getDisplayText(for: blockConfig)
        return configText.isEmpty ? blockConfig.name : "\(blockConfig.name) \(configText)"
    }
    
    // 实现 Equatable 协议
    static func == (lhs: ChainNode, rhs: ChainNode) -> Bool {
        return lhs.id == rhs.id
    }
}
