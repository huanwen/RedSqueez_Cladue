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
                    performHeadToChainTailConnection(headNode, with: targetNode, manager: manager)
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
                    // 情况3: 目标是链条头部
                    performConnectionToChainTail(node, with: targetNode, manager: manager)
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
        if targetNode.next == nil && !hasIncomingConnection(for: targetNode, manager: manager) {
            if node.position.y < targetNode.position.y {
                if let currentTail = findChainTail(from: node, manager: manager) {
                    currentTail.next = targetNode
                } else {
                    node.next = targetNode
                }
                rearrangeChain(from: node)
            } else {
                targetNode.next = node
                rearrangeChain(from: targetNode)
            }
        }
    }
    
    private func performConnectionToTailNode(_ node: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        targetNode.next = node
        let chainHead = getChainHead(of: targetNode, manager: manager)
        rearrangeChain(from: chainHead)
    }
    
    private func performConnectionToChainTail(_ node: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        if let chainTail = findChainTail(from: targetNode, manager: manager) {
            if chainTail.next == nil {
                chainTail.next = node
                rearrangeChain(from: targetNode)
            }
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
    
    private func performHeadToChainTailConnection(_ headNode: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
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
