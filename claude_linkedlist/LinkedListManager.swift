//
//  LinkedListManager.swift
//  LinkedListApp
//
//  链条管理器 - 处理链条连接和拖拽逻辑
//

import SwiftUI

// 链条管理器
class ChainManager: ObservableObject {
    @Published var nodes: [ChainNode] = []
    @Published var chains: [[ChainNode]] = [] // 存储多个独立的链条
    
    private let snapDistance: CGFloat = 25.0
    private let nodeSpacing: CGFloat = 50.0 // 垂直间距
    
    // 添加新节点
    func addNode(at position: CGPoint) {
        let newNode = ChainNode(position: position)
        nodes.append(newNode)
    }
    
    // 检查节点是否有前一个节点连接
    func hasPreviousConnection(for node: ChainNode) -> Bool {
        return nodes.contains { $0.next?.id == node.id }
    }
    
    // 检查自动连接（当拖拽结束时）- 上下长边连接
    func checkAutoConnect(for draggedNode: ChainNode) {
        guard draggedNode.next == nil else { return } // 如果已经连接了下一个节点，不处理
        guard !hasPreviousConnection(for: draggedNode) else { return } // 如果已经被其他节点连接，不处理
        
        // 找到最近的可连接节点
        for targetNode in nodes {
            if targetNode.id == draggedNode.id { continue }
            if targetNode.next != nil { continue } // 目标节点已经有下一个连接了
            if hasPreviousConnection(for: targetNode) { continue } // 目标节点已经被连接了
            
            // 检查垂直距离（上下连接）
            let horizontalDistance = abs(draggedNode.position.x - targetNode.position.x)
            let verticalDistance = abs(draggedNode.position.y - targetNode.position.y)
            
            // 如果水平距离较近且垂直距离在合理范围内，进行连接
            if horizontalDistance < 30 && verticalDistance > 30 && verticalDistance < snapDistance + 40 {
                // 确定哪个节点在上，哪个在下
                if draggedNode.position.y < targetNode.position.y {
                    // 拖拽的节点在上方，连接到下方的目标节点
                    draggedNode.next = targetNode
                    
                    // 调整位置使连接更自然
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        targetNode.position = CGPoint(
                            x: draggedNode.position.x,
                            y: draggedNode.position.y + nodeSpacing
                        )
                    }
                } else {
                    // 目标节点在上方，目标连接到拖拽的节点
                    targetNode.next = draggedNode
                    
                    // 调整位置使连接更自然
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        draggedNode.position = CGPoint(
                            x: targetNode.position.x,
                            y: targetNode.position.y + nodeSpacing
                        )
                    }
                }
                break
            }
        }
    }
    
    // 连接两个节点
    private func connectNodes(from: ChainNode, to: ChainNode) {
        // 断开to节点的现有连接
        disconnectNodeBefore(to)
        
        // 建立新连接
        from.next = to
        
        // 调整位置使连接更自然
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            to.position = CGPoint(x: from.position.x + nodeSpacing, y: from.position.y)
        }
        
        updateChains()
    }
    
    // 检查节点是否已经有连接
    private func hasConnection(_ node: ChainNode) -> Bool {
        // 检查是否作为其他节点的next存在
        return nodes.contains { $0.next?.id == node.id }
    }
    
    // 断开指定节点之前的连接
    private func disconnectNodeBefore(_ targetNode: ChainNode) {
        for node in nodes {
            if node.next?.id == targetNode.id {
                node.next = nil
                break
            }
        }
        updateChains()
    }
    
    // 拖拽整条链
    func dragChain(headNode: ChainNode, offset: CGSize) {
        var current: ChainNode? = headNode
        var xOffset: CGFloat = 0
        
        while let node = current {
            node.position = CGPoint(
                x: headNode.position.x + offset.width + xOffset,
                y: headNode.position.y + offset.height
            )
            xOffset += nodeSpacing
            current = node.next
        }
    }
    
    // 更新链条列表
    private func updateChains() {
        chains.removeAll()
        var processedNodes = Set<UUID>()
        
        for node in nodes {
            if !processedNodes.contains(node.id) && !hasConnection(node) {
                // 这是一个链条的头节点
                var chain: [ChainNode] = []
                var current: ChainNode? = node
                
                while let currentNode = current {
                    chain.append(currentNode)
                    processedNodes.insert(currentNode.id)
                    current = currentNode.next
                }
                
                if !chain.isEmpty {
                    chains.append(chain)
                }
            }
        }
        
        // 处理单独的节点（既不是头也不是尾）
        for node in nodes {
            if !processedNodes.contains(node.id) {
                chains.append([node])
                processedNodes.insert(node.id)
            }
        }
    }
    
    // 获取链条的头节点
    func getChainHead(for node: ChainNode) -> ChainNode {
        // 找到指向这个节点的节点
        var head = node
        while let previous = nodes.first(where: { $0.next?.id == head.id }) {
            head = previous
        }
        return head
    }
    
    // 删除节点
    func deleteNode(_ nodeToDelete: ChainNode) {
        // 找到指向要删除节点的节点，断开连接
        for node in nodes {
            if node.next?.id == nodeToDelete.id {
                node.next = nodeToDelete.next // 跳过被删除的节点
                break
            }
        }
        
        // 从数组中移除
        nodes.removeAll { $0.id == nodeToDelete.id }
    }
    
    // 清空所有连接
    func clearAllConnections() {
        for node in nodes {
            node.next = nil
        }
    }
    
    // 清空所有节点
    func clearAll() {
        nodes.removeAll()
        chains.removeAll()
    }
}
