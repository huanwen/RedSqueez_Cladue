//
//  ConnectionLogic.swift
//  LinkedListApp
//
//  链表连接逻辑处理
//

import SwiftUI

// MARK: - 连接逻辑处理类
class ConnectionLogic {
    private let snapDistance: CGFloat = 40.0
    private let nodeSpacing: CGFloat = 60.0
    
    // MARK: - 链条头部拖拽连接检查
    func checkChainToChainConnection(
        for headNode: ChainNode,
        manager: ChainManager,
        isChainHead: Bool,
        updateCallback: @escaping () -> Void
    ) {
        // 只有链条头部才能进行链条间连接
        guard isChainHead else { return }
        
        for targetNode in manager.nodes {
            if targetNode.id == headNode.id { continue }
            if isNodeInSameChain(headNode, targetNode, manager: manager) { continue }
            
            let horizontalDistance = abs(headNode.position.x - targetNode.position.x)
            let verticalDistance = abs(headNode.position.y - targetNode.position.y)
            
            if horizontalDistance < snapDistance && verticalDistance < snapDistance {
                // 检查目标节点的状态
                let targetIsHead = !hasIncomingConnection(for: targetNode, manager: manager)
                let targetHasNext = targetNode.next != nil
                let targetIsTail = !targetIsHead && !targetHasNext
                
                if targetIsHead && !targetHasNext {
                    // 情况1: 目标是独立节点
                    performHeadToNodeConnection(headNode, with: targetNode, manager: manager)
                } else if targetIsTail {
                    // 情况2: 目标是链条尾部节点
                    performHeadToTailNodeConnection(headNode, with: targetNode, manager: manager)
                } else if targetIsHead && targetHasNext {
                    // 情况3: 目标是链条头部
                    performHeadToChainHeadConnection(headNode, with: targetNode, manager: manager)
                } else {
                    // 情况4: 目标是链条中间节点
                    performChainInsertion(headNode, at: targetNode, manager: manager)
                }
                
                updateCallback()
                break
            }
        }
    }
    
    // MARK: - 单节点拖拽连接检查
    func checkAutoConnect(
        for node: ChainNode,
        manager: ChainManager,
        hasIncomingConnection: Bool,
        updateCallback: @escaping () -> Void
    ) {
        // 只有独立节点或链条头部才能进行连接
        guard !hasIncomingConnection else { return }
        
        for targetNode in manager.nodes {
            if targetNode.id == node.id { continue }
            if isNodeInSameChain(node, targetNode, manager: manager) { continue }
            
            let horizontalDistance = abs(node.position.x - targetNode.position.x)
            let verticalDistance = abs(node.position.y - targetNode.position.y)
            
            if horizontalDistance < snapDistance && verticalDistance < snapDistance {
                // 检查目标节点的状态
                let targetIsHead = !self.hasIncomingConnection(for: targetNode, manager: manager)
                let targetHasNext = targetNode.next != nil
                let targetIsTail = !targetIsHead && !targetHasNext
                
                if targetIsHead && !targetHasNext {
                    // 情况1: 目标是独立节点
                    performSimpleConnection(node, with: targetNode, manager: manager)
                } else if targetIsTail {
                    // 情况2: 目标是链条尾部节点
                    performConnectionToTailNode(node, with: targetNode, manager: manager)
                } else if targetIsHead && targetHasNext {
                    // 情况3: 目标是链条头部 - 需要根据位置决定连接方式
                    performConnectionToChainHead(node, with: targetNode, manager: manager)
                } else {
                    // 情况4: 目标是链条中间节点
                    performNodeInsertion(node, at: targetNode, manager: manager)
                }
                
                updateCallback()
                break
            }
        }
    }
    
    // MARK: - 私有连接操作方法
    private func performSimpleConnection(_ node: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        // 首先检查目标节点的真实状态
        let targetIsHead = !hasIncomingConnection(for: targetNode, manager: manager)
        let targetHasNext = targetNode.next != nil
        
        if targetIsHead && targetHasNext {
            // 目标是链条头部 - 使用专门的连接逻辑
            performConnectionToChainHead(node, with: targetNode, manager: manager)
        } else if targetIsHead && !targetHasNext {
            // 目标是独立节点
            if node.position.y < targetNode.position.y {
                // 拖拽节点在上方 - 拖拽节点成为链头
                if let currentTail = findChainTail(from: node, manager: manager) {
                    currentTail.next = targetNode
                } else {
                    node.next = targetNode
                }
                rearrangeChain(from: node)
            } else {
                // 拖拽节点在下方 - 目标节点成为链头
                targetNode.next = node
                rearrangeChain(from: targetNode)
            }
        } else if !targetIsHead && !targetHasNext {
            // 目标是链条尾部
            performConnectionToTailNode(node, with: targetNode, manager: manager)
        } else {
            // 目标是链条中间节点
            performNodeInsertion(node, at: targetNode, manager: manager)
        }
    }
    
    private func performConnectionToTailNode(_ node: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        targetNode.next = node
        let chainHead = getChainHead(of: targetNode, manager: manager)
        rearrangeChain(from: chainHead)
    }
    
    // 修复：连接到链条头部 - 根据位置决定是成为新链头还是插入
    private func performConnectionToChainHead(_ node: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        // 检查拖拽节点的位置是否在目标链条头部上方
        if node.position.y < targetNode.position.y {
            // 单个节点在上方 - 成为新的链头
            if let currentChainTail = findChainTail(from: node, manager: manager) {
                currentChainTail.next = targetNode
            } else {
                node.next = targetNode
            }
            rearrangeChain(from: node)  // 从新的链头开始重排
        } else {
            // 单个节点在下方 - 插入到链条头部下面
            let originalNext = targetNode.next
            targetNode.next = node
            
            // 如果当前拖拽的节点有子链，将子链连接到原来的next
            if let currentChainTail = findChainTail(from: node, manager: manager) {
                currentChainTail.next = originalNext
            } else {
                node.next = originalNext
            }
            
            rearrangeChain(from: targetNode)  // 从原链头开始重排
        }
    }
    
    private func performNodeInsertion(_ node: ChainNode, at targetNode: ChainNode, manager: ChainManager) {
        let targetNext = targetNode.next
        let currentChainTail = findChainTail(from: node, manager: manager) ?? node
        targetNode.next = node
        currentChainTail.next = targetNext
        
        let chainHead = getChainHead(of: targetNode, manager: manager)
        rearrangeChain(from: chainHead)
    }
    
    private func performHeadToNodeConnection(_ headNode: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        if headNode.position.y < targetNode.position.y {
            let currentTail = findChainTail(from: headNode, manager: manager) ?? headNode
            currentTail.next = targetNode
            rearrangeChain(from: headNode)
        } else {
            targetNode.next = headNode
            rearrangeChain(from: targetNode)
        }
    }
    
    private func performHeadToTailNodeConnection(_ headNode: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        targetNode.next = headNode
        let targetChainHead = getChainHead(of: targetNode, manager: manager)
        rearrangeChain(from: targetChainHead)
    }
    
    // 链条头部连接到另一个链条头部 - 保持原有逻辑
    private func performHeadToChainHeadConnection(_ headNode: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        // 将当前链条连接到目标链条尾部
        if let targetChainTail = findChainTail(from: targetNode, manager: manager) {
            if targetChainTail.next == nil {
                targetChainTail.next = headNode
                rearrangeChain(from: targetNode)
            }
        }
    }
    
    private func performChainInsertion(_ headNode: ChainNode, at targetNode: ChainNode, manager: ChainManager) {
        let targetNext = targetNode.next
        let currentChainTail = findChainTail(from: headNode, manager: manager) ?? headNode
        targetNode.next = headNode
        currentChainTail.next = targetNext
        
        let chainHead = getChainHead(of: targetNode, manager: manager)
        rearrangeChain(from: chainHead)
    }
    
    // MARK: - 辅助方法
    private func hasIncomingConnection(for targetNode: ChainNode, manager: ChainManager) -> Bool {
        return manager.nodes.contains { $0.next?.id == targetNode.id }
    }
    
    private func getChainHead(of node: ChainNode, manager: ChainManager) -> ChainNode {
        var head = node
        while let previous = manager.nodes.first(where: { $0.next?.id == head.id }) {
            head = previous
        }
        return head
    }
    
    private func findChainTail(from startNode: ChainNode, manager: ChainManager) -> ChainNode? {
        let head = getChainHead(of: startNode, manager: manager)
        var current = head
        while let next = current.next {
            current = next
        }
        return current
    }
    
    private func rearrangeChain(from head: ChainNode) {
        var current: ChainNode? = head
        var yOffset: CGFloat = 0
        
        while let currentNode = current {
            withAnimation(.easeOut(duration: 0.3)) {
                currentNode.position = CGPoint(
                    x: head.position.x,
                    y: head.position.y + yOffset
                )
            }
            yOffset += nodeSpacing
            current = currentNode.next
        }
    }
    
    private func isNodeInSameChain(_ node: ChainNode, _ targetNode: ChainNode, manager: ChainManager) -> Bool {
        let head = getChainHead(of: node, manager: manager)
        var current: ChainNode? = head
        while let currentNode = current {
            if currentNode.id == targetNode.id {
                return true
            }
            current = currentNode.next
        }
        return false
    }
}
