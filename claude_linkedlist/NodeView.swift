//
//  NodeView.swift
//  LinkedListApp
//
//  简化的链条节点视图 - 调整为紧凑高度
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
    @State private var showingBlockSelector = false
    @State private var showingDropdown = false
    @State private var isEditingText = false
    @State private var tempTextInput = ""
    
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
                color: node.blockConfig.color.opacity(0.8),
                strokeColor: getStrokeColor(),
                strokeWidth: getStrokeWidth()
            )
            .frame(width: getBlockWidth(), height: 60) // 🔧 FIX: 高度从80调整为60
            
            // 节点内容 - Scratch风格的内嵌控件
            HStack(spacing: 6) {
                if nodeIndex >= 0 {
                    Text("[\(nodeIndex)]")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .bold()
                }
                
                // 模块名称
                Text(node.blockConfig.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                // 根据输入类型显示不同的控件
                switch node.blockConfig.inputType {
                case .dropdown(let options):
                    createDropdownView(options: options)
                    
                case .textField(let placeholder):
                    createTextFieldView(placeholder: placeholder)
                    
                case .both(let options, let placeholder):
                    createDropdownView(options: options)
                    createTextFieldView(placeholder: placeholder)
                    
                case .none:
                    EmptyView()
                }
            }
            .frame(width: getBlockWidth() - 10)
            
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
                .frame(width: getBlockWidth(), height: 60) // 🔧 FIX: 高度从80调整为60
            }
        }
        .position(node.position)
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
            // Scratch风格不需要跳转页面编辑
        }
        .onLongPressGesture(minimumDuration: 0.6) {
            // 长按显示删除按钮
            showDeleteButton()
        }
        .sheet(isPresented: $showingBlockSelector) {
            BlockSelectorView(selectedConfig: $node.blockConfig)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    
                    // 拖拽时隐藏删除按钮
                    if showingDeleteButton {
                        hideDeleteButton()
                    }
                    
                    if isChainHead && hasConnections() {
                        // 链头拖拽 - 整条链条一起移动
                        moveWholeChainDuringDrag(offset: value.translation)
                    } else {
                        // 中间模块拖拽 - 先断开，然后整体移动子链条
                        if dragOffset == .zero {
                            // 第一次拖拽时断开
                            breakFromPreviousNode()
                        }
                        // 移动当前节点及其子链条作为整体
                        moveSubChainDuringDrag(offset: value.translation)
                    }
                    
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    
                    // 重新整理链条排列，保持凹凸槽对齐
                    rearrangeCurrentChain()
                    
                    // 检查连接 - 根据节点状态选择合适的连接方法
                    let currentIsChainHead = !hasIncomingConnection()
                    let currentHasNext = node.next != nil
                    
                    if currentIsChainHead && currentHasNext {
                        // 拖拽的是链条头部 - 使用链条间连接检测
                        connectionLogic.checkChainToChainConnection(
                            for: node,
                            manager: manager,
                            isChainHead: true
                        ) {
                            updateNodeInfo()
                        }
                    } else {
                        // 拖拽的是单个节点或断开的子链条 - 使用自动连接检测
                        connectionLogic.checkAutoConnect(
                            for: node,
                            manager: manager,
                            hasIncomingConnection: hasIncomingConnection()
                        ) {
                            updateNodeInfo()
                        }
                    }
                    
                    dragOffset = .zero
                    updateNodeInfo()
                }
        )
    }
    
    // MARK: - Scratch风格内嵌控件创建方法
    @ViewBuilder
    private func createDropdownView(options: [String]) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    node.blockData.selectedDropdown = option
                }
            }
        } label: {
            HStack(spacing: 2) {
                Text(node.blockData.selectedDropdown ?? options.first ?? "选择")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
            }
            .background(Color.white)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func createTextFieldView(placeholder: String) -> some View {
        HStack(spacing: 2) {
            if isEditingText {
                TextField("", text: $tempTextInput, onCommit: {
                    node.blockData.textInput = tempTextInput
                    isEditingText = false
                })
                .font(.system(size: 11, weight: .medium))
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.black)
                .background(Color.white)
                .cornerRadius(6)
                .frame(width: 40, height: 20)
                .onAppear {
                    tempTextInput = node.blockData.textInput
                }
            } else {
                Button(action: {
                    tempTextInput = node.blockData.textInput
                    isEditingText = true
                }) {
                    Text(node.blockData.textInput.isEmpty ? placeholder : node.blockData.textInput)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // 根据内容动态计算模块宽度
    private func getBlockWidth() -> CGFloat {
        let baseName = node.blockConfig.name
        let baseWidth: CGFloat = 60 + CGFloat(baseName.count * 8)
        
        switch node.blockConfig.inputType {
        case .dropdown(let options):
            let maxOption = options.max(by: { $0.count < $1.count }) ?? ""
            return baseWidth + CGFloat(maxOption.count * 6) + 40
            
        case .textField(let placeholder):
            let maxText = max(node.blockData.textInput.count, placeholder.count)
            return baseWidth + CGFloat(maxText * 6) + 40
            
        case .both(let options, let placeholder):
            let maxOption = options.max(by: { $0.count < $1.count }) ?? ""
            let maxText = max(node.blockData.textInput.count, placeholder.count)
            return baseWidth + CGFloat(maxOption.count * 6) + CGFloat(maxText * 6) + 60
            
        case .none:
            return baseWidth
        }
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
                
                // 重新排列原链条，保持凹凸槽对齐
                let originalHead = getChainHead(of: prevNode)
                rearrangeChainWithAlignment(from: originalHead)
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
    
    // MARK: - 链条重排（保持凹凸槽对齐）
    private func rearrangeChainWithAlignment(from head: ChainNode) {
        var current: ChainNode? = head
        var yOffset: CGFloat = 0
        
        // 获取链头的凹凸槽位置作为基准
        let headSlotX = getSlotXPosition(for: head)
        
        while let currentNode = current {
            // 计算每个节点的中心位置，使其凹凸槽与基准对齐
            let currentNodeWidth = getBlockWidth(for: currentNode)
            let currentNodeCenterX = headSlotX + (currentNodeWidth / 2) - 20.0
            
            withAnimation(.easeOut(duration: 0.3)) {
                currentNode.position = CGPoint(
                    x: currentNodeCenterX,
                    y: head.position.y + yOffset
                )
            }
            yOffset += 52.0 // 🔧 FIX: 调整间距使凹凸槽完美贴合(模块高度60-槽高8-边距8)
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
    
    // MARK: - 视觉样式
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
    private func moveWholeChainDuringDrag(offset: CGSize) {
        // 链头拖拽时，整条链条实时移动
        let deltaX = offset.width - dragOffset.width
        let deltaY = offset.height - dragOffset.height
        
        var current: ChainNode? = node
        while let currentNode = current {
            currentNode.position.x += deltaX
            currentNode.position.y += deltaY
            current = currentNode.next
        }
    }
    
    private func moveSubChainDuringDrag(offset: CGSize) {
        // 中间模块拖拽时，子链条整体实时移动
        let deltaX = offset.width - dragOffset.width
        let deltaY = offset.height - dragOffset.height
        
        var current: ChainNode? = node
        while let currentNode = current {
            currentNode.position.x += deltaX
            currentNode.position.y += deltaY
            current = currentNode.next
        }
    }
    
    private func rearrangeCurrentChain() {
        // 🔧 OPTIMIZED: 统一使用精确的凹凸槽对齐方法
        rearrangeChainWithAlignment(from: node)
    }
    
    private func breakFromPreviousNode() {
        for prevNode in manager.nodes {
            if prevNode.next?.id == node.id {
                prevNode.next = nil
                
                let originalHead = getChainHead(of: prevNode)
                rearrangeChainWithAlignment(from: originalHead)
                break
            }
        }
    }
}
