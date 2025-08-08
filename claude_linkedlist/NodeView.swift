//
//  NodeView.swift
//  LinkedListApp
//
//  Scratch风格拼图块节点视图
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
    
    var body: some View {
        ZStack {
            // Scratch风格的拼图块形状
            ScratchBlockShape(
                hasTopSlot: true,  // 始终显示顶部凹槽
                hasBottomTab: true,  // 始终显示底部凸起
                topSlotHighlight: hasIncomingConnection(),  // 有连接时高亮
                bottomTabHighlight: node.next != nil,  // 有连接时高亮
                color: getNodeColor(),
                strokeColor: getStrokeColor(),
                strokeWidth: getStrokeWidth()
            )
            .frame(width: 120, height: 66)  // 增加高度以容纳凸起
            
            // 节点信息显示
            VStack(spacing: 2) {
                // 节点顺序
                if nodeIndex >= 0 {
                    Text("[\(nodeIndex)]")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .bold()
                }
                
                // UUID简短显示
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
                        // 如果是链条头且有连接，移动整条链
                        moveWholeChain(offset: value.translation)
                    } else {
                        // 非头部节点移动 - 断开并形成新链条
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
        // 找到链条头
        let head = getChainHead()
        
        // 从头开始计算位置
        var current: ChainNode? = head
        var index = 0
        
        while let currentNode = current {
            if currentNode.id == node.id {
                return index
            }
            index += 1
            current = currentNode.next
        }
        
        return -1 // 独立节点
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
            return Color.blue.opacity(0.7) // 蓝色表示链条头部
        } else if hasConnections() {
            return Color.green.opacity(0.7) // 绿色表示已连接的节点
        } else {
            return Color.gray.opacity(0.6) // 灰色表示独立节点
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
        // 确保这是链条头部
        guard isChainHead && hasConnections() else {
            // 如果不是链条头部，调用断开逻辑
            breakAndMoveSubChain(offset: offset)
            return
        }
        
        // 移动头部节点
        node.position.x += offset.width
        node.position.y += offset.height
        
        // 重新排列整条链的所有节点
        var current = node.next
        var yOffset: CGFloat = 60  // 调整为包含凸起的间距
        
        while let currentNode = current {
            withAnimation(.easeOut(duration: 0.2)) {
                currentNode.position.x = node.position.x
                currentNode.position.y = node.position.y + yOffset
            }
            yOffset += 60
            current = currentNode.next
        }
        
        // 拖拽结束后检查是否可以连接到其他链条
        checkChainToChainConnection()
    }
    
    private func breakAndMoveSubChain(offset: CGSize) {
        // 如果当前节点有前驱节点，断开连接
        breakFromPreviousNode()
        
        // 移动当前节点
        node.position.x += offset.width
        node.position.y += offset.height
        
        // 如果当前节点有后续节点，一起移动（形成新的子链条）
        if node.next != nil {
            moveSubChainNodes()
        }
        
        // 检查是否可以连接到其他节点或链条
        checkAutoConnect()
    }
    
    private func breakFromPreviousNode() {
        // 找到指向当前节点的前驱节点，断开连接
        for prevNode in manager.nodes {
            if prevNode.next?.id == node.id {
                prevNode.next = nil
                
                // 重新排列原来的链条（如果前驱节点还在链条中）
                let originalHead = getChainHead(of: prevNode)
                rearrangeChain(from: originalHead)
                break
            }
        }
    }
    
    private func moveSubChainNodes() {
        // 移动当前节点后面的所有节点，形成新的子链条
        var current = node.next
        var yOffset: CGFloat = 60  // 包含凸起的间距
        
        while let currentNode = current {
            withAnimation(.easeOut(duration: 0.2)) {
                currentNode.position.x = node.position.x
                currentNode.position.y = node.position.y + yOffset
            }
            yOffset += 60
            current = currentNode.next
        }
    }
    
    // MARK: - 连接逻辑
    private func checkChainToChainConnection() {
        let snapDistance: CGFloat = 40.0
        
        // 只有链条头部才能进行链条间连接
        guard isChainHead else { return }
        
        for targetNode in manager.nodes {
            if targetNode.id == node.id { continue }
            if isNodeInSameChain(targetNode) { continue } // 不能连接到同一条链表
            
            let horizontalDistance = abs(node.position.x - targetNode.position.x)
            let verticalDistance = abs(node.position.y - targetNode.position.y)
            
            if horizontalDistance < snapDistance && verticalDistance < snapDistance {
                // 检查目标节点的状态
                let targetIsHead = !hasIncomingConnection(for: targetNode)
                let targetHasNext = targetNode.next != nil
                let targetIsTail = !targetIsHead && !targetHasNext  // 检查是否是尾部节点
                
                if targetIsHead && !targetHasNext {
                    // 情况1: 目标是独立节点，根据位置决定连接顺序
                    performHeadToNodeConnection(with: targetNode)
                } else if targetIsTail {
                    // 情况2: 目标是链条尾部节点，直接连接到其后
                    performHeadToTailNodeConnection(with: targetNode)
                } else if targetIsHead && targetHasNext {
                    // 情况3: 目标是链条头部，连接到该链条尾部
                    performHeadToChainTailConnection(with: targetNode)
                } else {
                    // 情况4: 目标是链条中间节点，插入当前链条
                    performChainInsertion(at: targetNode)
                }
                
                updateNodeInfo()
                break
            }
        }
    }
    
    private func checkAutoConnect() {
        let snapDistance: CGFloat = 40.0
        
        // 只有独立节点或链条头部才能进行连接
        guard !hasIncomingConnection() else { return }
        
        for targetNode in manager.nodes {
            if targetNode.id == node.id { continue }
            if isNodeInSameChain(targetNode) { continue } // 不能连接到同一条链表
            
            let horizontalDistance = abs(node.position.x - targetNode.position.x)
            let verticalDistance = abs(node.position.y - targetNode.position.y)
            
            if horizontalDistance < snapDistance && verticalDistance < snapDistance {
                // 检查目标节点的状态
                let targetIsHead = !hasIncomingConnection(for: targetNode)
                let targetHasNext = targetNode.next != nil
                let targetIsTail = !targetIsHead && !targetHasNext  // 新增：检查是否是尾部节点
                
                if targetIsHead && !targetHasNext {
                    // 情况1: 目标是独立节点
                    performSimpleConnection(with: targetNode)
                } else if targetIsTail {
                    // 情况2: 目标是链条尾部节点，直接连接到其后
                    performConnectionToTailNode(with: targetNode)
                } else if targetIsHead && targetHasNext {
                    // 情况3: 目标是链条头部，连接到该链条尾部
                    performConnectionToChainTail(with: targetNode)
                } else {
                    // 情况4: 目标是链条中间节点，插入到该位置
                    performNodeInsertion(at: targetNode)
                }
                
                updateNodeInfo()
                break
            }
        }
    }
    
    // MARK: - 连接操作函数
    private func performSimpleConnection(with targetNode: ChainNode) {
        // 检查目标节点是否真的是独立节点
        if targetNode.next == nil && !hasIncomingConnection(for: targetNode) {
            // 两个独立节点连接，根据位置决定顺序
            if node.position.y < targetNode.position.y {
                if let currentTail = findChainTail(from: node) {
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
    
    private func performConnectionToTailNode(with targetNode: ChainNode) {
        // 目标是链条尾部节点，直接连接到其后面
        targetNode.next = node
        
        // 找到链条头部并重新排列
        let chainHead = getChainHead(of: targetNode)
        rearrangeChain(from: chainHead)
    }
    
    private func performConnectionToChainTail(with targetNode: ChainNode) {
        // 连接到现有链条的尾部（目标是链条头部）
        if let chainTail = findChainTail(from: targetNode) {
            if chainTail.next == nil {
                chainTail.next = node  // 直接连接到尾部，不交换位置
                rearrangeChain(from: targetNode) // 从目标链条头部重新排列
            }
        }
    }
    
    private func performNodeInsertion(at targetNode: ChainNode) {
        // 插入到目标节点的后面，而不是替换目标节点
        // 保存目标节点的下一个节点
        let targetNext = targetNode.next
        
        // 建立新连接：targetNode -> currentNode/Chain -> targetNext
        let currentChainTail = findChainTail(from: node) ?? node
        targetNode.next = node
        currentChainTail.next = targetNext
        
        // 重新排列整个链条
        let chainHead = getChainHead(of: targetNode)
        rearrangeChain(from: chainHead)
    }
    
    private func performHeadToNodeConnection(with targetNode: ChainNode) {
        // 与独立节点连接，根据位置决定顺序
        if node.position.y < targetNode.position.y {
            // 当前链条连接到目标节点
            let currentTail = findChainTail(from: node) ?? node
            currentTail.next = targetNode
            rearrangeChain(from: node)
        } else {
            // 目标节点连接到当前链条头部
            targetNode.next = node
            rearrangeChain(from: targetNode)
        }
    }
    
    private func performHeadToTailNodeConnection(with targetNode: ChainNode) {
        // 目标是链条尾部节点，将当前链条连接到其后面
        targetNode.next = node
        
        // 找到目标链条的头部并重新排列
        let targetChainHead = getChainHead(of: targetNode)
        rearrangeChain(from: targetChainHead)
    }
    
    private func performHeadToChainTailConnection(with targetNode: ChainNode) {
        // 连接到目标链条的尾部
        if let targetChainTail = findChainTail(from: targetNode) {
            if targetChainTail.next == nil {
                targetChainTail.next = node
                rearrangeChain(from: targetNode)  // 从目标链条头部重新排列
            }
        }
    }
    
    private func performChainInsertion(at targetNode: ChainNode) {
        // 插入到目标节点的后面，而不是替换目标节点位置
        // 保存目标节点的下一个节点
        let targetNext = targetNode.next
        
        // 建立新连接：targetNode -> currentChain -> targetNext
        let currentChainTail = findChainTail(from: node) ?? node
        targetNode.next = node
        currentChainTail.next = targetNext
        
        // 重新排列整个合并后的链条
        let chainHead = getChainHead(of: targetNode)
        rearrangeChain(from: chainHead)
    }
    
    // MARK: - 辅助函数
    private func hasIncomingConnection(for targetNode: ChainNode) -> Bool {
        return manager.nodes.contains { $0.next?.id == targetNode.id }
    }
    
    private func getChainHead(of node: ChainNode) -> ChainNode {
        var head = node
        while let previous = manager.nodes.first(where: { $0.next?.id == head.id }) {
            head = previous
        }
        return head
    }
    
    private func findChainTail(from startNode: ChainNode) -> ChainNode? {
        let head = getChainHead(of: startNode)
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
            yOffset += 60  // 包含凸起的间距
            current = currentNode.next
        }
    }
    
    private func isNodeInSameChain(_ targetNode: ChainNode) -> Bool {
        // 检查目标节点是否在当前节点的链条中
        var current: ChainNode? = getChainHead()
        while let currentNode = current {
            if currentNode.id == targetNode.id {
                return true
            }
            current = currentNode.next
        }
        return false
    }
}

// MARK: - Scratch风格拼图块形状
struct ScratchBlockShape: View {
    let hasTopSlot: Bool
    let hasBottomTab: Bool
    let topSlotHighlight: Bool
    let bottomTabHighlight: Bool
    let color: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    
    var body: some View {
        ZStack {
            // 主体形状
            ScratchPath(hasTopSlot: hasTopSlot, hasBottomTab: hasBottomTab)
                .fill(color)
                .overlay(
                    ScratchPath(hasTopSlot: hasTopSlot, hasBottomTab: hasBottomTab)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
            
            // 顶部凹槽高亮
            if topSlotHighlight {
                TopSlotHighlight()
                    .fill(Color.yellow.opacity(0.6))
                    .animation(.easeInOut(duration: 0.3), value: topSlotHighlight)
            }
            
            // 底部凸起高亮
            if bottomTabHighlight {
                BottomTabHighlight()
                    .fill(Color.yellow.opacity(0.6))
                    .animation(.easeInOut(duration: 0.3), value: bottomTabHighlight)
            }
        }
    }
}

// MARK: - Scratch拼图块路径
struct ScratchPath: Shape {
    let hasTopSlot: Bool
    let hasBottomTab: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 8
        let slotWidth: CGFloat = 20
        let slotHeight: CGFloat = 6
        let tabWidth: CGFloat = 20
        let tabHeight: CGFloat = 6
        
        // 开始绘制路径
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // 顶部边缘
        if hasTopSlot {
            // 绘制顶部凹槽
            let slotStart = (width - slotWidth) / 2
            let slotEnd = slotStart + slotWidth
            
            path.addLine(to: CGPoint(x: slotStart, y: 0))
            path.addLine(to: CGPoint(x: slotStart, y: slotHeight))
            path.addArc(center: CGPoint(x: slotStart + slotWidth/2, y: slotHeight),
                       radius: slotWidth/2,
                       startAngle: .degrees(180),
                       endAngle: .degrees(0),
                       clockwise: true)
            path.addLine(to: CGPoint(x: slotEnd, y: 0))
        }
        
        // 顶部右角
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addArc(center: CGPoint(x: width - cornerRadius, y: cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(-90),
                   endAngle: .degrees(0),
                   clockwise: false)
        
        // 右边缘
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        
        // 底部右角
        path.addArc(center: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(0),
                   endAngle: .degrees(90),
                   clockwise: false)
        
        // 底部边缘
        if hasBottomTab {
            // 绘制底部凸起
            let tabStart = (width - tabWidth) / 2
            let tabEnd = tabStart + tabWidth
            
            path.addLine(to: CGPoint(x: tabEnd, y: height))
            path.addLine(to: CGPoint(x: tabEnd, y: height + tabHeight))
            path.addArc(center: CGPoint(x: tabEnd - tabWidth/2, y: height + tabHeight),
                       radius: tabWidth/2,
                       startAngle: .degrees(0),
                       endAngle: .degrees(180),
                       clockwise: true)
            path.addLine(to: CGPoint(x: tabStart, y: height))
        }
        
        // 底部左角
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        path.addArc(center: CGPoint(x: cornerRadius, y: height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(90),
                   endAngle: .degrees(180),
                   clockwise: false)
        
        // 左边缘
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        
        // 顶部左角
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(180),
                   endAngle: .degrees(270),
                   clockwise: false)
        
        path.closeSubpath()
        return path
    }
}

// MARK: - 顶部凹槽高亮形状
struct TopSlotHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let slotWidth: CGFloat = 20
        let slotHeight: CGFloat = 6
        let slotStart = (width - slotWidth) / 2
        
        // 绘制凹槽高亮区域
        path.move(to: CGPoint(x: slotStart, y: 0))
        path.addLine(to: CGPoint(x: slotStart, y: slotHeight))
        path.addArc(center: CGPoint(x: slotStart + slotWidth/2, y: slotHeight),
                   radius: slotWidth/2,
                   startAngle: .degrees(180),
                   endAngle: .degrees(0),
                   clockwise: true)
        path.addLine(to: CGPoint(x: slotStart + slotWidth, y: 0))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 底部凸起高亮形状
struct BottomTabHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let tabWidth: CGFloat = 20
        let tabHeight: CGFloat = 6
        let tabStart = (width - tabWidth) / 2
        
        // 绘制凸起高亮区域
        path.move(to: CGPoint(x: tabStart, y: height))
        path.addLine(to: CGPoint(x: tabStart, y: height + tabHeight))
        path.addArc(center: CGPoint(x: tabStart + tabWidth/2, y: height + tabHeight),
                   radius: tabWidth/2,
                   startAngle: .degrees(180),
                   endAngle: .degrees(0),
                   clockwise: false)
        path.addLine(to: CGPoint(x: tabStart + tabWidth, y: height))
        path.closeSubpath()
        
        return path
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
            y: node.position.y + 60  // 包含凸起的间距
        )
        let newNode = ChainNode(position: insertPosition)
        
        // 保存原来的下一个节点
        let originalNext = node.next
        
        // 插入新节点
        node.next = newNode
        newNode.next = originalNext
        
        // 添加到节点数组
        manager.nodes.append(newNode)
        
        // 重新排列链条
        rearrangeChainFromHead()
    }
    
    private func deleteCurrentNode() {
        // 找到指向要删除节点的节点，断开连接
        for managerNode in manager.nodes {
            if managerNode.next?.id == node.id {
                managerNode.next = node.next // 跳过被删除的节点
                break
            }
        }
        
        // 从数组中移除
        manager.nodes.removeAll { $0.id == node.id }
    }
    
    private func rearrangeChainFromHead() {
        // 找到链条头
        var head = node
        while let previous = manager.nodes.first(where: { $0.next?.id == head.id }) {
            head = previous
        }
        
        // 重新排列整条链条的位置
        var current: ChainNode? = head
        var yOffset: CGFloat = 0
        
        while let currentNode = current {
            withAnimation(.easeOut(duration: 0.3)) {
                currentNode.position = CGPoint(
                    x: head.position.x,
                    y: head.position.y + yOffset
                )
            }
            yOffset += 60  // 包含凸起的间距
            current = currentNode.next
        }
    }
}
