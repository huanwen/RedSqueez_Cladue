//
//  NodeView.swift
//  LinkedListApp
//
//  简化的链条节点视图 - 添加长按删除功能
//

import SwiftUI

struct ChainNodeView: View {
    @ObservedObject var node: ChainNode
    @ObservedObject var manager: ChainManager
    @State private var dragOffset = CGSize.zero
    @State private var isChainHead = false
    @State private var isDragging = false

    @State private var nodeIndex: Int = -1
    @State private var showingDeleteButton = false
    @State private var longPressTimer: Timer?
    
    // 连接逻辑处理器
    private let connectionLogic = ConnectionLogic()
    
    var body: some View {
        ZStack {
            // Scratch风格的拼图块形状
            ScratchBlockShape(
                hasTopSlot: true,
                hasBottomTab: true,
                topSlotHighlight: hasIncomingConnection(),
                bottomTabHighlight: node.next != nil,
                color: getNodeColor(),
                strokeColor: getStrokeColor(),
                strokeWidth: getStrokeWidth()
            )
            .frame(width: 120, height: 66)
            
            // 节点信息显示
            VStack(spacing: 2) {
                if nodeIndex >= 0 {
                    Text("[\(nodeIndex)]")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .bold()
                }
                
                Text("ID: \(node.shortUUID)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .opacity(0.9)
            }
            
            // 删除按钮 - 长按时显示
            if showingDeleteButton {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            deleteNodeWithAnimation()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                }
                .frame(width: 120, height: 66)
            }
        }
        .position(CGPoint(x: node.position.x + dragOffset.width,
                         y: node.position.y + dragOffset.height))
        .onAppear {
            updateNodeInfo()
        }
        .onChange(of: manager.nodes.count) { _ in
            updateNodeInfo()
        }
        .onChange(of: manager.nodes.map { $0.next?.id }) { _ in
            updateNodeInfo()
        }
        .onTapGesture {
            // 如果正在显示删除按钮，先隐藏它
            if showingDeleteButton {
                hideDeleteButton()
            }
        }
        .onLongPressGesture(minimumDuration: 0.6) {
            // 长按显示删除按钮
            showDeleteButton()
        }

        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                    
                    // 拖拽时隐藏删除按钮
                    if showingDeleteButton {
                        hideDeleteButton()
                    }
                }
                .onEnded { value in
                    isDragging = false
                    
                    if isChainHead && hasConnections() {
                        // 链条头部拖拽
                        moveWholeChain(offset: value.translation)
                    } else {
                        // 非头部节点拖拽
                        breakAndMoveSubChain(offset: value.translation)
                    }
                    
                    dragOffset = .zero
                    updateNodeInfo()
                }
        )
    }
    
    // MARK: - 删除按钮相关方法
    private func showDeleteButton() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingDeleteButton = true
        }
        
        // 3秒后自动隐藏删除按钮
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            hideDeleteButton()
        }
    }
    
    private func hideDeleteButton() {
        withAnimation(.easeOut(duration: 0.2)) {
            showingDeleteButton = false
        }
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
    
    private func deleteNodeWithAnimation() {
        // 先隐藏删除按钮
        hideDeleteButton()
        
        // 添加删除动画
        withAnimation(.easeInOut(duration: 0.3)) {
            // 缩放效果
            node.position = CGPoint(x: node.position.x, y: node.position.y - 10)
        }
        
        // 延迟删除，让动画播放完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            deleteCurrentNode()
        }
    }
    
    private func deleteCurrentNode() {
        // 断开前驱连接
        for prevNode in manager.nodes {
            if prevNode.next?.id == node.id {
                prevNode.next = node.next
                
                // 重新排列原链条
                let originalHead = getChainHead(of: prevNode)
                rearrangeChain(from: originalHead)
                break
            }
        }
        
        // 从管理器中移除节点
        manager.nodes.removeAll { $0.id == node.id }
    }
    
    // MARK: - 节点信息更新
    private func updateNodeInfo() {
        isChainHead = !hasIncomingConnection()
        nodeIndex = calculateNodeIndex()
    }
    
    private func calculateNodeIndex() -> Int {
        let head = getChainHead()
        var current: ChainNode? = head
        var index = 0
        
        while let currentNode = current {
            if currentNode.id == node.id {
                return index
            }
            index += 1
            current = currentNode.next
        }
        
        return -1
    }
    
    private func getChainHead() -> ChainNode {
        var head = node
        while let previous = manager.nodes.first(where: { $0.next?.id == head.id }) {
            head = previous
        }
        return head
    }
    
    private func getChainHead(of targetNode: ChainNode) -> ChainNode {
        var head = targetNode
        while let previous = manager.nodes.first(where: { $0.next?.id == head.id }) {
            head = previous
        }
        return head
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
            yOffset += 60
            current = currentNode.next
        }
    }
    
    // MARK: - 视觉样式
    private func getNodeColor() -> Color {
        if isChainHead && hasConnections() {
            return Color.blue.opacity(0.7)
        } else if hasConnections() {
            return Color.green.opacity(0.7)
        } else {
            return Color.gray.opacity(0.6)
        }
    }
    
    private func getStrokeColor() -> Color {
        return hasConnections() ? Color.black : Color.gray
    }
    
    private func getStrokeWidth() -> CGFloat {
        return hasConnections() ? 3 : 2
    }
    
    private func hasConnections() -> Bool {
        return node.next != nil || hasIncomingConnection()
    }
    
    private func hasIncomingConnection() -> Bool {
        return manager.nodes.contains { $0.next?.id == node.id }
    }
    
    // MARK: - 拖拽和移动
    private func moveWholeChain(offset: CGSize) {
        guard isChainHead && hasConnections() else {
            breakAndMoveSubChain(offset: offset)
            return
        }
        
        // 移动头部节点
        node.position.x += offset.width
        node.position.y += offset.height
        
        // 重新排列整条链
        var current = node.next
        var yOffset: CGFloat = 60
        
        while let currentNode = current {
            withAnimation(.easeOut(duration: 0.2)) {
                currentNode.position.x = node.position.x
                currentNode.position.y = node.position.y + yOffset
            }
            yOffset += 60
            current = currentNode.next
        }
        
        // 检查链条间连接
        connectionLogic.checkChainToChainConnection(
            for: node,
            manager: manager,
            isChainHead: isChainHead
        ) {
            updateNodeInfo()
        }
    }
    
    private func breakAndMoveSubChain(offset: CGSize) {
        // 断开前驱连接
        breakFromPreviousNode()
        
        // 移动当前节点
        node.position.x += offset.width
        node.position.y += offset.height
        
        // 移动子链条
        if node.next != nil {
            moveSubChainNodes()
        }
        
        // 检查自动连接
        connectionLogic.checkAutoConnect(
            for: node,
            manager: manager,
            hasIncomingConnection: hasIncomingConnection()
        ) {
            updateNodeInfo()
        }
    }
    
    private func breakFromPreviousNode() {
        for prevNode in manager.nodes {
            if prevNode.next?.id == node.id {
                prevNode.next = nil
                
                let originalHead = getChainHead(of: prevNode)
                rearrangeChain(from: originalHead)
                break
            }
        }
    }
    
    private func moveSubChainNodes() {
        var current = node.next
        var yOffset: CGFloat = 60
        
        while let currentNode = current {
            withAnimation(.easeOut(duration: 0.2)) {
                currentNode.position.x = node.position.x
                currentNode.position.y = node.position.y + yOffset
            }
            yOffset += 60
            current = currentNode.next
        }
    }
}
