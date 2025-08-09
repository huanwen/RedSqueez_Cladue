//
//  ConnectionLogic.swift
//  LinkedListApp
//
//  链表连接逻辑处理 - 修复链条插入bug
//

import SwiftUI

// MARK: - 连接逻辑处理类
class ConnectionLogic {
    private let snapDistance: CGFloat = 40.0
    private let nodeSpacing: CGFloat = 44.0 // 🔧 FIX: 调整间距使凹凸槽完美贴合(60高度-8槽高-8边距)
    
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
                    // 🔧 FIX: 情况3: 目标是链条头部 - 修复插入逻辑
                    performHeadToChainHeadConnection_Fixed(headNode, with: targetNode, manager: manager)
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
                    performConnectionToChainHead_Fixed(node, with: targetNode, manager: manager)
                } else {
                    // 情况4: 目标是链条中间节点
                    performNodeInsertion(node, at: targetNode, manager: manager)
                }
                
                updateCallback()
                break
            }
        }
    }
    
    // MARK: - 🔧 FIX: 修复的连接操作方法
    
    // 修复：链条头部到链条头部的连接
    private func performHeadToChainHeadConnection_Fixed(_ headNode: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        print("🔧 链条头部连接: \(headNode.blockConfig.name) -> \(targetNode.blockConfig.name)")
        
        // 检查拖拽链条头部的位置相对于目标链条头部的位置
        if headNode.position.y < targetNode.position.y {
            // 🔧 FIX: 拖拽的链条在上方 - 应该连接到目标链条的尾部
            print("  - 拖拽链条在上方，连接到目标链条尾部")
            if let targetChainTail = findChainTail(from: targetNode, manager: manager) {
                targetChainTail.next = headNode
                // 🔧 FIX: 使用精确对齐重排整个链条
                rearrangeChain(from: targetNode)
            }
        } else {
            // 🔧 FIX: 拖拽的链条在下方 - 应该插入到目标链条头部下面
            print("  - 拖拽链条在下方，插入到目标链条头部下面")
            
            // 保存目标链条头部的原始next
            let originalNext = targetNode.next
            
            // 将目标链条头部连接到拖拽的链条头部
            targetNode.next = headNode
            
            // 找到拖拽链条的尾部，连接到原始的next
            let draggedChainTail = findChainTail(from: headNode, manager: manager) ?? headNode
            draggedChainTail.next = originalNext
            
            // 🔧 FIX: 使用精确对齐重排整个链条
            rearrangeChain(from: targetNode)
        }
    }
    
    // 修复：单节点到链条头部的连接
    private func performConnectionToChainHead_Fixed(_ node: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        print("🔧 单节点连接到链条头部: \(node.blockConfig.name) -> \(targetNode.blockConfig.name)")
        
        // 检查拖拽节点的位置是否在目标链条头部上方
        if node.position.y < targetNode.position.y {
            // 🔧 FIX: 单个节点在上方 - 连接到目标链条的尾部
            print("  - 单节点在上方，连接到目标链条尾部")
            if let targetChainTail = findChainTail(from: targetNode, manager: manager) {
                targetChainTail.next = node
                // 🔧 FIX: 使用精确对齐重排整个链条
                rearrangeChain(from: targetNode)
            }
        } else {
            // 🔧 FIX: 单个节点在下方 - 插入到链条头部下面
            print("  - 单节点在下方，插入到目标链条头部下面")
            
            // 保存目标节点的原始next
            let originalNext = targetNode.next
            
            // 将目标节点连接到拖拽的节点
            targetNode.next = node
            
            // 如果当前拖拽的节点有子链，将子链连接到原来的next
            if let currentChainTail = findChainTail(from: node, manager: manager) {
                currentChainTail.next = originalNext
            } else {
                node.next = originalNext
            }
            
            // 🔧 FIX: 使用精确对齐重排整个链条
            rearrangeChain(from: targetNode)
        }
    }
    
    // MARK: - 私有连接操作方法（保持原有逻辑）
    private func performSimpleConnection(_ node: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        // 首先检查目标节点的真实状态
        let targetIsHead = !hasIncomingConnection(for: targetNode, manager: manager)
        let targetHasNext = targetNode.next != nil
        
        if targetIsHead && targetHasNext {
            // 目标是链条头部 - 使用修复后的连接逻辑
            performConnectionToChainHead_Fixed(node, with: targetNode, manager: manager)
        } else if targetIsHead && !targetHasNext {
            // 目标是独立节点
            if node.position.y < targetNode.position.y {
                // 拖拽节点在上方 - 拖拽节点成为链头
                if let currentTail = findChainTail(from: node, manager: manager) {
                    currentTail.next = targetNode
                } else {
                    node.next = targetNode
                }
                // 🔧 FIX: 使用精确对齐重排
                rearrangeChain(from: node)
            } else {
                // 拖拽节点在下方 - 目标节点成为链头
                targetNode.next = node
                // 🔧 FIX: 使用精确对齐重排
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
            // 🔧 FIX: 使用精确对齐重排
            rearrangeChain(from: headNode)
        } else {
            targetNode.next = headNode
            // 🔧 FIX: 使用精确对齐重排
            rearrangeChain(from: targetNode)
        }
    }
    
    private func performHeadToTailNodeConnection(_ headNode: ChainNode, with targetNode: ChainNode, manager: ChainManager) {
        targetNode.next = headNode
        let targetChainHead = getChainHead(of: targetNode, manager: manager)
        rearrangeChain(from: targetChainHead)
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
    
    // 🔧 FIX: 重新排列链条 - 确保凹凸槽对齐
    private func rearrangeChain(from head: ChainNode) {
        var current: ChainNode? = head
        var yOffset: CGFloat = 0
        
        // 获取链头的凹凸槽位置作为基准
        let headSlotX = getSlotXPosition(for: head)
        
        while let currentNode = current {
            // 计算每个节点的中心位置，使其凹凸槽与基准对齐
            let currentNodeWidth = getBlockWidth(for: currentNode)
            let currentNodeCenterX = headSlotX + (currentNodeWidth / 2) - 20.0 // 20是槽位距离左边的固定偏移
            
            withAnimation(.easeOut(duration: 0.3)) {
                currentNode.position = CGPoint(
                    x: currentNodeCenterX,
                    y: head.position.y + yOffset
                )
            }
            yOffset += 52.0 // 使用与NodeView相同的间距
            current = currentNode.next
        }
    }
    
    // 获取节点的凹凸槽X位置
    private func getSlotXPosition(for targetNode: ChainNode) -> CGFloat {
        let nodeWidth = getBlockWidth(for: targetNode)
        return targetNode.position.x - (nodeWidth / 2) + 20.0 // 20是槽位距离左边的固定偏移
    }
    
    // 获取指定节点的模块宽度
    private func getBlockWidth(for targetNode: ChainNode) -> CGFloat {
        let baseName = targetNode.blockConfig.name
        let baseWidth: CGFloat = 60 + CGFloat(baseName.count * 8)
        
        switch targetNode.blockConfig.inputType {
        case .dropdown(let options):
            let maxOption = options.max(by: { $0.count < $1.count }) ?? ""
            return baseWidth + CGFloat(maxOption.count * 6) + 40
            
        case .textField(let placeholder):
            let maxText = max(targetNode.blockData.textInput.count, placeholder.count)
            return baseWidth + CGFloat(maxText * 6) + 40
            
        case .both(let options, let placeholder):
            let maxOption = options.max(by: { $0.count < $1.count }) ?? ""
            let maxText = max(targetNode.blockData.textInput.count, placeholder.count)
            return baseWidth + CGFloat(maxOption.count * 6) + CGFloat(maxText * 6) + 60
            
        case .none:
            return baseWidth
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
