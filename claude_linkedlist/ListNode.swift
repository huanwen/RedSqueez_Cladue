//
//  ListNode.swift
//  LinkedListApp
//
//  链条节点数据模型
//

import SwiftUI

// 链条节点数据模型
class ChainNode: ObservableObject, Identifiable, Equatable {
    let id = UUID()
    @Published var next: ChainNode?
    @Published var position: CGPoint
    
    // UUID的简短显示版本（前6位）
    var shortUUID: String {
        return String(id.uuidString.prefix(6))
    }
    
    init(position: CGPoint = CGPoint.zero) {
        self.position = position
    }
    
    // 实现 Equatable 协议
    static func == (lhs: ChainNode, rhs: ChainNode) -> Bool {
        return lhs.id == rhs.id
    }
}
