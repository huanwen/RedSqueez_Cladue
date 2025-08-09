//
//  NodeView.swift
//  LinkedListApp
//
//  简化的链条节点视图 - 磁性吸附系统（修复凹凸槽位置）
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
    @State private var nearbyTargetNode: ChainNode? = nil
    @State private var snapPreviewPosition: CGPoint? = nil
    
    // 🔧 FIX: 本地高亮状态，避免全局状态污染
    @State private var localTopSlotHighlight = false
    @State private var localBottomTabHighlight = false
    
    // 连接逻辑处理器
    private let connectionLogic = ConnectionLogic()
    
    var body: some View {
        ZStack {
            // Scratch风格的拼图块形状
            ScratchBlockShape(
                hasTopSlot: true,
                hasBottomTab: true,
                // 🔧 FIX: 使用本地高亮状态而不是全局状态
                topSlotHighlight: localTopSlotHighlight,
                bottomTabHighlight: localBottomTabHighlight,
                color: node.blockConfig.color.opacity(0.8),
                strokeColor: getStrokeColor(),
                strokeWidth: getStrokeWidth()
            )
            .frame(width: getBlockWidth(), height: 80)
            
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
                .frame(width: getBlockWidth(), height: 80)
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
        // 🔧 FIX: 监听全局吸附状态变化，只有目标节点才更新本地高亮状态
        .onChange(of: manager.snapTargetNodeId) { targetId in
            updateLocalHighlightState(targetId: targetId)
        }
        .onChange(of: manager.snapTargetSlot) { targetSlot in
            updateLocalHighlightState(targetId: manager.snapTargetNodeId)
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
                    
                    // 只做吸附预览，不实际移动到吸附位置
                    let potentialPosition = CGPoint(
                        x: node.position.x + value.translation.width,
                        y: node.position.y + value.translation.height
                    )
                    
                    let snapResult = findSnapTarget(at: potentialPosition)
                    
                    // 🔧 FIX: 更新全局吸附状态，但本地高亮状态由onChange监听器处理
                    if let targetNode = snapResult.targetNode {
                        manager.snapTargetNodeId = targetNode.id
                        // 使用吸附检测中确定的槽位类型
                        let candidates = findDetailedSnapCandidates(at: potentialPosition)
                        manager.snapTargetSlot = candidates.first?.slotType
                        nearbyTargetNode = targetNode
                        snapPreviewPosition = snapResult.snapPosition
                    } else {
                        manager.snapTargetNodeId = nil
                        manager.snapTargetSlot = nil
                        nearbyTargetNode = nil
                        snapPreviewPosition = nil
                    }
                    
                    // 正常拖拽移动
                    if isChainHead && hasConnections() {
                        moveWholeChainDuringDrag(offset: value.translation)
                    } else {
                        if dragOffset == .zero {
                            breakFromPreviousNode()
                        }
                        moveSubChainDuringDrag(offset: value.translation)
                    }
                    
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    
                    // 🔧 FIX: 清除吸附预览状态
                    manager.snapTargetNodeId = nil
                    manager.snapTargetSlot = nil
                    
                    // 如果有吸附目标，先移动到吸附位置，然后连接
                    if let targetNode = nearbyTargetNode, let snapPosition = snapPreviewPosition {
                        // 磁性吸附动画
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if isChainHead && hasConnections() {
                                moveWholeChainToPosition(snapPosition)
                            } else {
                                moveSubChainToPosition(snapPosition)
                            }
                        }
                        
                        // 延迟执行连接，让动画先完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.executeDirectConnection(with: targetNode)
                        }
                    } else {
                        // 没有吸附目标，重新整理链条
                        rearrangeCurrentChain()
                    }
                    
                    nearbyTargetNode = nil
                    snapPreviewPosition = nil
                    dragOffset = .zero
                    updateNodeInfo()
                }
        )
    }
    
    // 🔧 FIX: 新增方法 - 更新本地高亮状态
    private func updateLocalHighlightState(targetId: UUID?) {
        // 只有当前节点是目标节点时才高亮
        if let targetId = targetId, targetId == node.id {
            // 根据目标槽位类型设置对应的高亮
            switch manager.snapTargetSlot {
            case .topSlot:
                localTopSlotHighlight = true
                localBottomTabHighlight = false
            case .bottomTab:
                localTopSlotHighlight = false
                localBottomTabHighlight = true
            case .none:
                localTopSlotHighlight = false
                localBottomTabHighlight = false
            }
        } else {
            // 不是目标节点，清除所有高亮
            localTopSlotHighlight = false
            localBottomTabHighlight = false
        }
    }
    
    // MARK: - 模块宽度计算方法
    
    // 🔧 FIX: 获取指定节点的模块宽度
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
    
    // 根据内容动态计算当前模块宽度
    private func getBlockWidth() -> CGFloat {
        return getBlockWidth(for: node)
    }
    
    // 🔧 FIX: 计算节点凹凸槽的实际位置
    private func getSlotPosition(for targetNode: ChainNode) -> CGPoint {
        let slotLeftOffset: CGFloat = 20.0 // 凹凸槽距离左边的固定距离
        let targetBlockWidth = getBlockWidth(for: targetNode) // 获取目标节点的宽度
        
        // 计算凹凸槽的实际X位置
        let slotX = targetNode.position.x - (targetBlockWidth / 2) + slotLeftOffset
        
        return CGPoint(x: slotX, y: targetNode.position.y)
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
    
    private func rearrangeChain(from head: ChainNode) {
        // 🔧 FIX: 重新排列链条，减小间距让凹凸槽紧密贴合
        var current: ChainNode? = head
        var yOffset: CGFloat = 0
        
        // 🔧 FIX: 获取链头的凹凸槽位置作为基准
        let headSlotPosition = getSlotPosition(for: head)
        let baseSlotX = headSlotPosition.x
        
        while let currentNode = current {
            // 🔧 FIX: 计算每个节点的中心位置，使其凹凸槽与基准对齐
            let currentNodeWidth = getBlockWidth(for: currentNode)
            let currentNodeCenterX = baseSlotX + (currentNodeWidth / 2) - 20.0
            
            withAnimation(.easeOut(duration: 0.3)) {
                currentNode.position = CGPoint(
                    x: currentNodeCenterX,
                    y: head.position.y + yOffset
                )
            }
            yOffset += 72.0 // 🔧 FIX: 从80改为72，减少空隙
            current = currentNode.next
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
    
    // MARK: - 磁性吸附移动方法
    private func moveWholeChainToPosition(_ targetPosition: CGPoint) {
        // 链头磁性吸附 - 整条链移动到目标位置
        var current: ChainNode? = node
        var yOffset: CGFloat = 0
        
        while let currentNode = current {
            currentNode.position = CGPoint(
                x: targetPosition.x,
                y: targetPosition.y + yOffset
            )
            yOffset += 80
            current = currentNode.next
        }
    }
    
    private func moveSubChainToPosition(_ targetPosition: CGPoint) {
        // 子链磁性吸附 - 整个子链移动到目标位置
        var current: ChainNode? = node
        var yOffset: CGFloat = 0
        
        while let currentNode = current {
            currentNode.position = CGPoint(
                x: targetPosition.x,
                y: targetPosition.y + yOffset
            )
            yOffset += 80
            current = currentNode.next
        }
    }
    
    private func rearrangeCurrentChain() {
        // 🔧 FIX: 拖拽结束后重新整理链条，减小间距让凹凸槽紧密贴合
        var current: ChainNode? = node
        var yOffset: CGFloat = 0
        
        // 🔧 FIX: 获取当前节点的凹凸槽位置作为基准
        let currentSlotPosition = getSlotPosition(for: node)
        let baseSlotX = currentSlotPosition.x
        
        while let currentNode = current {
            // 🔧 FIX: 计算每个节点的中心位置，使其凹凸槽与基准对齐
            let currentNodeWidth = getBlockWidth(for: currentNode)
            let currentNodeCenterX = baseSlotX + (currentNodeWidth / 2) - 20.0
            
            withAnimation(.easeOut(duration: 0.2)) {
                currentNode.position = CGPoint(
                    x: currentNodeCenterX,
                    y: node.position.y + yOffset
                )
            }
            yOffset += 72.0 // 🔧 FIX: 从80改为72，减少空隙
            current = currentNode.next
        }
    }
    
    // MARK: - 改进的吸附系统 - 基于节点中心距离范围
    private func findSnapTarget(at position: CGPoint) -> (targetNode: ChainNode?, snapPosition: CGPoint?) {
        // 🔧 FIX: 改为更宽松的吸附范围检测
        let maxSnapDistance: CGFloat = 100.0 // 增大吸附范围
        let horizontalTolerance: CGFloat = 80.0 // 增大水平容忍度
        let verticalTolerance: CGFloat = 80.0 // 增大垂直容忍度
        let minDistance: CGFloat = 10.0 // 最小距离，避免重叠
        
        var candidates: [(node: ChainNode, distance: CGFloat, priority: Int, slotType: SlotType)] = []
        
        for targetNode in manager.nodes {
            if targetNode.id == node.id { continue }
            if isNodeInSameChain(targetNode) { continue }
            
            // 🔧 FIX: 使用节点中心点距离进行初步检测（更容易吸附）
            let draggedNodeCenter = position
            let targetNodeCenter = targetNode.position // 使用目标节点中心，不是凹凸槽位置
            
            let horizontalDistance = abs(draggedNodeCenter.x - targetNodeCenter.x)
            let verticalDistance = abs(draggedNodeCenter.y - targetNodeCenter.y)
            let actualDistance = sqrt(horizontalDistance * horizontalDistance + verticalDistance * verticalDistance)
            
            // 🔧 FIX: 更宽松的检测条件，基于节点中心距离
            var shouldConsiderForSnap = false
            
            if actualDistance > minDistance && actualDistance < maxSnapDistance {
                // 情况1：垂直接近（上下连接）- 更宽松的条件
                if horizontalDistance < horizontalTolerance && verticalDistance > 20 && verticalDistance < verticalTolerance {
                    shouldConsiderForSnap = true
                }
                // 情况2：侧面插入 - 更宽松的条件
                else if horizontalDistance > 30 && horizontalDistance < horizontalTolerance && verticalDistance < 40 {
                    shouldConsiderForSnap = true
                }
                // 情况3：一般接近 - 非常宽松的条件
                else if actualDistance < maxSnapDistance * 0.8 {
                    shouldConsiderForSnap = true
                }
            }
            
            if shouldConsiderForSnap {
                // 🔧 FIX: 严格的凹凸槽匹配检查
                if let matchingSlot = findStrictMatchingSlot(for: targetNode, draggedFrom: position) {
                    let priority = calculateNodePriority(for: targetNode, draggedFrom: position)
                    
                    candidates.append((node: targetNode, distance: actualDistance, priority: priority, slotType: matchingSlot))
                }
            }
        }
        
        // 按距离排序，选择最近的有效候选
        candidates.sort { $0.distance < $1.distance }
        
        if let bestCandidate = candidates.first {
            let snapPosition = calculatePreciseSnapPosition(for: bestCandidate.node, draggedFrom: position)
            return (bestCandidate.node, snapPosition)
        }
        
        return (nil, nil)
    }
    
    // 🔧 FIX: 严格的凹凸槽匹配逻辑 - 支持插入操作
    private func findStrictMatchingSlot(for targetNode: ChainNode, draggedFrom position: CGPoint) -> SlotType? {
        let verticalDirection = position.y - targetNode.position.y
        let horizontalDirection = position.x - targetNode.position.x
        
        // 检查目标节点的状态
        let targetIsHead = !manager.nodes.contains { $0.next?.id == targetNode.id }
        let targetHasNext = targetNode.next != nil
        
        // 检查当前拖拽节点的状态
        let currentNodeHasNext = node.next != nil
        let currentNodeIsHead = !hasIncomingConnection()
        
        // 🔧 FIX: 重新定义槽位可用性，支持插入功能
        
        // 情况1：从上方接近（verticalDirection < -20）
        // 允许：拖拽节点的底部凸槽 → 目标节点的顶部凹槽
        if verticalDirection < -20 {
            let draggedBottomTabAvailable = !currentNodeHasNext
            let targetTopSlotAvailable = targetIsHead
            
            if draggedBottomTabAvailable && targetTopSlotAvailable {
                return .topSlot
            }
        }
        
        // 情况2：从下方接近（verticalDirection > 20）
        // 允许：目标节点的底部凸槽 → 拖拽节点的顶部凹槽
        else if verticalDirection > 20 {
            let targetBottomTabAvailable = !targetHasNext
            let draggedTopSlotAvailable = currentNodeIsHead
            
            if targetBottomTabAvailable && draggedTopSlotAvailable {
                return .bottomTab
            }
        }
        
        // 🔧 FIX: 情况3：侧面插入（horizontalDirection 有明显偏移，verticalDirection 较小）
        // 允许插入到链条中间
        else if abs(horizontalDirection) > 20 && abs(verticalDirection) <= 20 {
            // 侧面插入：断开目标节点与其next的连接，插入拖拽节点
            let draggedTopSlotAvailable = currentNodeIsHead
            
            if targetHasNext && draggedTopSlotAvailable {
                // 插入到目标节点下方
                return .bottomTab // 高亮目标的底部凸槽（插入点）
            }
        }
        
        return nil
    }
    
    private func calculateNodePriority(for targetNode: ChainNode, draggedFrom position: CGPoint) -> Int {
        let targetIsHead = !manager.nodes.contains { $0.next?.id == targetNode.id }
        let targetHasNext = targetNode.next != nil
        let verticalDirection = position.y - targetNode.position.y
        
        // 优先级计算：数值越高优先级越高
        if !targetIsHead && !targetHasNext {
            // 链条尾部节点 - 最高优先级（用于连接到链条末尾）
            return 100
        } else if targetIsHead && !targetHasNext {
            // 独立节点 - 高优先级
            return 80
        } else if targetIsHead && targetHasNext {
            // 链条头部 - 中等优先级
            if verticalDirection < 0 {
                // 从上方接近链头（成为新链头）- 稍高优先级
                return 70
            } else {
                // 从下方接近链头（插入） - 中等优先级
                return 60
            }
        } else if !targetIsHead && targetHasNext {
            // 链条中间节点 - 可插入，给予合理优先级
            if verticalDirection > 0 {
                // 从下方接近中间节点（插入操作）- 中低优先级
                return 40
            } else {
                // 从上方接近中间节点 - 较低优先级
                return 20
            }
        } else {
            // 其他情况 - 最低优先级
            return 10
        }
    }
    
    private func calculatePreciseSnapPosition(for targetNode: ChainNode, draggedFrom position: CGPoint) -> CGPoint {
        let targetIsHead = !manager.nodes.contains { $0.next?.id == targetNode.id }
        let targetHasNext = targetNode.next != nil
        // 🔧 FIX: 减小连接间距，让凹凸槽完全贴合
        let connectionSpacing: CGFloat = 72.0 // 从80改为72，减少8px空隙
        
        // 计算拖拽方向
        let verticalDirection = position.y - targetNode.position.y
        
        // 🔧 FIX: 计算凹凸槽对齐的正确位置
        let targetSlotPosition = getSlotPosition(for: targetNode) // 目标凹凸槽的真实位置
        let draggedNodeWidth = getBlockWidth(for: node) // 拖拽节点的宽度
        
        // 🔧 FIX: 计算拖拽节点中心点位置，使其凹凸槽与目标凹凸槽对齐
        let draggedNodeCenterX = targetSlotPosition.x + (draggedNodeWidth / 2) - 20.0 // 20是槽位偏移量
        
        if targetIsHead && targetHasNext {
            // 目标是链条头部
            if verticalDirection < -20 {
                // 明确从上方拖拽 - 成为新链头
                return CGPoint(
                    x: draggedNodeCenterX, // 使用计算后的中心位置
                    y: targetNode.position.y - connectionSpacing
                )
            } else {
                // 从下方或侧面拖拽 - 插入到头部下面
                return CGPoint(
                    x: draggedNodeCenterX,
                    y: targetNode.position.y + connectionSpacing
                )
            }
        } else if targetIsHead && !targetHasNext {
            // 目标是独立节点
            if verticalDirection < 0 {
                // 拖拽节点在上方
                return CGPoint(
                    x: draggedNodeCenterX,
                    y: targetNode.position.y - connectionSpacing
                )
            } else {
                // 拖拽节点在下方
                return CGPoint(
                    x: draggedNodeCenterX,
                    y: targetNode.position.y + connectionSpacing
                )
            }
        } else if !targetIsHead && !targetHasNext {
            // 目标是链条尾部 - 只能连接到下方
            return CGPoint(
                x: draggedNodeCenterX,
                y: targetNode.position.y + connectionSpacing
            )
        } else {
            // 目标是链条中间节点 - 插入到下方
            return CGPoint(
                x: draggedNodeCenterX,
                y: targetNode.position.y + connectionSpacing
            )
        }
    }
    
    private func executeDirectConnection(with targetNode: ChainNode) {
        // 直接执行连接，不依赖旧的重叠检测系统
        let targetIsHead = !manager.nodes.contains { $0.next?.id == targetNode.id }
        let targetHasNext = targetNode.next != nil
        let currentPosition = node.position
        
        if targetIsHead && targetHasNext {
            // 目标是链条头部
            if currentPosition.y < targetNode.position.y {
                // 当前节点成为新链头
                if let currentTail = findChainTail() {
                    currentTail.next = targetNode
                } else {
                    node.next = targetNode
                }
                // 重新排列从新链头开始
                rearrangeEntireChain(from: node)
            } else {
                // 插入到头部下面
                let originalNext = targetNode.next
                targetNode.next = node
                if let currentTail = findChainTail() {
                    currentTail.next = originalNext
                } else {
                    node.next = originalNext
                }
                // 重新排列从原链头开始
                rearrangeEntireChain(from: targetNode)
            }
        } else if targetIsHead && !targetHasNext {
            // 目标是独立节点
            if currentPosition.y < targetNode.position.y {
                // 当前节点在上方
                if let currentTail = findChainTail() {
                    currentTail.next = targetNode
                } else {
                    node.next = targetNode
                }
                rearrangeEntireChain(from: node)
            } else {
                // 目标节点在上方
                targetNode.next = node
                rearrangeEntireChain(from: targetNode)
            }
        } else if !targetIsHead && !targetHasNext {
            // 目标是链条尾部
            targetNode.next = node
            let chainHead = getChainHead(of: targetNode)
            rearrangeEntireChain(from: chainHead)
        } else {
            // 目标是链条中间节点 - 插入
            let originalNext = targetNode.next
            targetNode.next = node
            if let currentTail = findChainTail() {
                currentTail.next = originalNext
            } else {
                node.next = originalNext
            }
            let chainHead = getChainHead(of: targetNode)
            rearrangeEntireChain(from: chainHead)
        }
        
        updateNodeInfo()
    }
    
    private func rearrangeEntireChain(from head: ChainNode) {
        // 🔧 FIX: 重新排列整条链，减小间距让凹凸槽紧密贴合
        var current: ChainNode? = head
        var yOffset: CGFloat = 0
        
        // 🔧 FIX: 获取链头的凹凸槽位置作为基准
        let headSlotPosition = getSlotPosition(for: head)
        let baseSlotX = headSlotPosition.x
        
        while let currentNode = current {
            // 🔧 FIX: 计算每个节点的中心位置，使其凹凸槽与基准对齐
            let currentNodeWidth = getBlockWidth(for: currentNode)
            let currentNodeCenterX = baseSlotX + (currentNodeWidth / 2) - 20.0 // 20是槽位偏移量
            
            withAnimation(.easeOut(duration: 0.2)) {
                currentNode.position = CGPoint(
                    x: currentNodeCenterX, // 使用计算后的中心位置
                    y: head.position.y + yOffset
                )
            }
            yOffset += 72.0 // 🔧 FIX: 从80改为72，减少空隙
            current = currentNode.next
        }
    }
    
    private func getChainHead(of targetNode: ChainNode) -> ChainNode {
        var head = targetNode
        while let previous = manager.nodes.first(where: { $0.next?.id == head.id }) {
            head = previous
        }
        return head
    }
    
    private func findChainTail() -> ChainNode? {
        var current = node
        while let next = current.next {
            current = next
        }
        return current == node ? nil : current
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
    
    private func isNodeInSameChain(_ targetNode: ChainNode) -> Bool {
        let head = getChainHead()
        var current: ChainNode? = head
        while let currentNode = current {
            if currentNode.id == targetNode.id {
                return true
            }
            current = currentNode.next
        }
        return false
    }
    
    private func findDetailedSnapCandidates(at position: CGPoint) -> [(node: ChainNode, slotType: SlotType)] {
        // 🔧 FIX: 使用与主检测相同的宽松逻辑
        let maxSnapDistance: CGFloat = 100.0 // 与主检测保持一致
        let horizontalTolerance: CGFloat = 80.0 // 与主检测保持一致
        let verticalTolerance: CGFloat = 80.0 // 与主检测保持一致
        let minDistance: CGFloat = 10.0 // 与主检测保持一致
        
        var candidates: [(node: ChainNode, slotType: SlotType)] = []
        
        for targetNode in manager.nodes {
            if targetNode.id == node.id { continue }
            if isNodeInSameChain(targetNode) { continue }
            
            // 🔧 FIX: 使用节点中心距离，而不是凹凸槽距离
            let draggedNodeCenter = position
            let targetNodeCenter = targetNode.position
            
            let horizontalDistance = abs(draggedNodeCenter.x - targetNodeCenter.x)
            let verticalDistance = abs(draggedNodeCenter.y - targetNodeCenter.y)
            let actualDistance = sqrt(horizontalDistance * horizontalDistance + verticalDistance * verticalDistance)
            
            // 🔧 FIX: 使用相同的宽松检测条件
            var shouldConsiderForSnap = false
            
            if actualDistance > minDistance && actualDistance < maxSnapDistance {
                // 情况1：垂直接近（上下连接）
                if horizontalDistance < horizontalTolerance && verticalDistance > 20 && verticalDistance < verticalTolerance {
                    shouldConsiderForSnap = true
                }
                // 情况2：侧面插入
                else if horizontalDistance > 30 && horizontalDistance < horizontalTolerance && verticalDistance < 40 {
                    shouldConsiderForSnap = true
                }
                // 情况3：一般接近
                else if actualDistance < maxSnapDistance * 0.8 {
                    shouldConsiderForSnap = true
                }
            }
            
            if shouldConsiderForSnap {
                if let matchingSlot = findStrictMatchingSlot(for: targetNode, draggedFrom: position) {
                    candidates.append((node: targetNode, slotType: matchingSlot))
                }
            }
        }
        
        return candidates
    }
}
