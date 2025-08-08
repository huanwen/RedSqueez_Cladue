//
//  NodeView.swift
//  LinkedListApp
//
//  简化的链条节点视图
//

import SwiftUI

struct ChainNodeView: View {
    @ObservedObject var node: ChainNode
    @ObservedObject var manager: ChainManager
    @State private var dragOffset = CGSize.zero
    @State private var isChainHead = false
    @State private var isDragging = false
    @State private var showingInsertMenu = false
    @State private var nodeIndex: Int = -1
    
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
            showingInsertMenu = true
        }
        .sheet(isPresented: $showingInsertMenu) {
            InsertMenuView(node: node, manager: manager, nodeIndex: nodeIndex)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
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
    
    // MARK: - 辅助方法
    private func getChainHead(of node: ChainNode) -> ChainNode {
        var head = node
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
}

// MARK: - 插入菜单视图
struct InsertMenuView: View {
    let node: ChainNode
    @ObservedObject var manager: ChainManager
    let nodeIndex: Int
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("节点操作")
                    .font(.title)
                    .bold()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("节点信息:")
                        .font(.headline)
                    Text("完整UUID: \(node.id.uuidString)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if nodeIndex >= 0 {
                        Text("链表位置: [\(nodeIndex)]")
                            .font(.subheadline)
                    } else {
                        Text("独立节点（未连接）")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                VStack(spacing: 12) {
                    Button("在此节点后插入新节点") {
                        insertNewNode()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("删除此节点") {
                        deleteCurrentNode()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("节点 [\(nodeIndex >= 0 ? String(nodeIndex) : "独立")]")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func insertNewNode() {
        let insertPosition = CGPoint(
            x: node.position.x + 20,
            y: node.position.y + 60
        )
        let newNode = ChainNode(position: insertPosition)
        
        let originalNext = node.next
        node.next = newNode
        newNode.next = originalNext
        
        manager.nodes.append(newNode)
        rearrangeChainFromHead()
    }
    
    private func deleteCurrentNode() {
        for managerNode in manager.nodes {
            if managerNode.next?.id == node.id {
                managerNode.next = node.next
                break
            }
        }
        
        manager.nodes.removeAll { $0.id == node.id }
    }
    
    private func rearrangeChainFromHead() {
        var head = node
        while let previous = manager.nodes.first(where: { $0.next?.id == head.id }) {
            head = previous
        }
        
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
}
