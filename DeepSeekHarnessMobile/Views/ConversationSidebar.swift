import SwiftUI

/// 侧边栏触发的导航动作。首页抽屉与会话页悬浮侧栏共用同一份定义。
struct AppSidebarActions {
    var openSession: (SessionSummary) -> Void = { _ in }
    var openNewSession: () -> Void = {}
    var openPlugins: () -> Void = {}
    var openScheduledTasks: () -> Void = {}
    var openSettings: () -> Void = {}
}

/// ChatGPT 式侧边栏内容，首页抽屉与会话页悬浮侧栏共用：
/// 品牌 + 搜索 → 插件 / 定时任务 → 分割线 → 项目文件夹（展开显示真实历史会话）→ 可选设置行。
///
/// 只接收数据、不持有数据源：调用方传入「与首页同一口径」的 workspaces / sessions，
/// 展开状态与搜索词由本组件自己维护，导航通过 `actions` 回传。
struct AppSidebar: View {
    /// 已按首页口径过滤好的可见会话（排除团队子会话、子代理与已归档会话）。
    let sessions: [SessionSummary]
    let workspaces: [GatewayWorkspace]
    let selectedSessionID: String?
    /// 内容检索结果（来自 AppStore.search），可为空。
    let searchResults: [GatewaySearchItem]
    var actions = AppSidebarActions()
    /// 抽屉底部安全区高度（Home Indicator），底部按钮据此留白。
    var bottomInset: CGFloat = 0
    /// 搜索词变化时回传，由调用方决定是否调用 AppStore.search。
    var onSearchQueryChange: (String) -> Void = { _ in }

    private static let ungroupedKey = "__ungrouped__"

    @Environment(\.colorScheme) private var colorScheme
    /// 展开的工作区 id（逗号分隔），只用于持久化；渲染读 expandedKeys。
    @AppStorage("conversationSidebar.expandedWorkspaces") private var expandedStorage = ""
    @State private var expandedKeys: Set<String> = []
    @State private var groups = SessionGroups()
    @State private var groupingSignature = ""
    @State private var isSearching = false
    @State private var searchText = ""
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isSearching {
                searchField
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        searchResultRows
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                }
            } else {
                navigationRow("插件", action: actions.openPlugins) {
                    Image("DshPluginPinwheel")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                navigationRow("定时任务", action: actions.openScheduledTasks) {
                    Image(systemName: "clock")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.regular)
                        .frame(width: 19, height: 19)
                }

                sectionDivider

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        folderRows
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                }
            }

            bottomBar
        }
        .foregroundStyle(Color(uiColor: .label))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("app-sidebar")
        .onAppear {
            expandedKeys = Set(expandedStorage.split(separator: ",").map(String.init))
            refreshGroups(force: true)
        }
        .onChangeCompat(of: groupingSignature) { _, _ in
            refreshGroups()
        }
        .onChangeCompat(of: searchText) { _, value in
            onSearchQueryChange(value)
        }
        .onDisappear {
            if isSearching { onSearchQueryChange("") }
        }
    }

    // MARK: - 分组缓存

    /// 会话或工作区变化时才重算分组；流式输出导致的其它重绘不会重复分组。
    private var currentGroupingSignature: String {
        "\(workspaces.count)|\(sessions.count)|\(sessions.lazy.map(\.id).joined(separator: ","))"
    }

    private func refreshGroups(force: Bool = false) {
        let signature = currentGroupingSignature
        guard force || signature != groupingSignature else { return }
        groupingSignature = signature
        groups = SessionGroups.group(sessions: sessions, workspaces: workspaces)
    }

    // MARK: - 区域 A：品牌 + 搜索

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            HarnessMark(onDarkBackground: colorScheme == .dark, width: 168)
            Spacer(minLength: 4)
            if !isSearching {
                searchButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var searchButton: some View {
        Button {
            isSearching = true
            searchFieldFocused = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("搜索会话")
        .accessibilityIdentifier("app-sidebar-search")
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            TextField("搜索会话", text: $searchText)
                .textFieldStyle(.plain)
                .appFont(.system(size: 15))
                .focused($searchFieldFocused)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityIdentifier("app-sidebar-search-field")
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除搜索")
            }
            Button("取消") { endSearch() }
                .appFont(.system(size: 14))
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Color.primary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    private func endSearch() {
        searchFieldFocused = false
        isSearching = false
        searchText = ""
    }

    // MARK: - 搜索

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 标题命中：本地已加载会话，按最近活动倒序。
    private var titleMatches: [SessionSummary] {
        let query = trimmedQuery
        guard !query.isEmpty else { return [] }
        return sortedByActivity(
            sessions.filter { $0.title.localizedCaseInsensitiveContains(query) }
        )
    }

    /// 内容命中：AppStore 缓存检索 + 后端 searchSessions 的结果（带片段）。
    private var contentMatches: [GatewaySearchItem] {
        guard !trimmedQuery.isEmpty else { return [] }
        let titleIDs = Set(titleMatches.map(\.id))
        return searchResults.filter { !titleIDs.contains($0.sessionId) }
    }

    @ViewBuilder
    private var searchResultRows: some View {
        if trimmedQuery.isEmpty {
            Text("输入关键词搜索会话标题与内容")
                .appFont(.system(size: 13))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        } else if titleMatches.isEmpty && contentMatches.isEmpty {
            Text("没有匹配的会话")
                .appFont(.system(size: 13))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        } else {
            ForEach(titleMatches) { session in
                sessionRow(session)
            }
            if !contentMatches.isEmpty {
                Text("内容匹配")
                    .appFont(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    .padding(.bottom, 2)
                ForEach(contentMatches) { hit in
                    if let session = sessions.first(where: { $0.id == hit.sessionId }) {
                        contentHitRow(session: session, snippet: hit.snippet)
                    }
                }
            }
        }
    }

    private func contentHitRow(session: SessionSummary, snippet: String) -> some View {
        Button {
            actions.openSession(session)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.title.isEmpty ? String(localized: "未命名会话") : session.title)
                    .lineLimit(1)
                    .appFont(.system(size: 15, weight: .medium))
                Text(snippet)
                    .lineLimit(2)
                    .appFont(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("app-sidebar-search-hit-\(session.id)")
    }

    // MARK: - 区域 B / C 之间的分割线

    private var sectionDivider: some View {
        Divider()
            .opacity(0.25)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    // MARK: - 区域 C：项目文件夹与历史会话

    @ViewBuilder
    private var folderRows: some View {
        ForEach(workspaces) { workspace in
            folderSection(
                key: workspace.id,
                title: folderTitle(workspace),
                sessions: groups.byWorkspace[workspace.id] ?? []
            )
        }
        if !groups.ungrouped.isEmpty {
            folderSection(
                key: Self.ungroupedKey,
                title: String(localized: "未分组"),
                icon: "tray",
                sessions: groups.ungrouped
            )
        }
        if workspaces.isEmpty && groups.ungrouped.isEmpty {
            Text("暂无会话")
                .appFont(.system(size: 13))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
    }

    /// 文件夹名来自后端工作区标题，缺失时回退到目录最后一级（不硬编码）。
    private func folderTitle(_ workspace: GatewayWorkspace) -> String {
        workspace.title.isEmpty
            ? URL(fileURLWithPath: workspace.path).lastPathComponent
            : workspace.title
    }

    @ViewBuilder
    private func folderSection(
        key: String,
        title: String,
        icon: String = "folder",
        sessions: [SessionSummary]
    ) -> some View {
        let isExpanded = expandedKeys.contains(key)
        let containsCurrent = selectedSessionID.map { id in sessions.contains { $0.id == id } } ?? false
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { toggle(key) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 10)
                Image(systemName: icon)
                    .appFont(.system(size: 16))
                    .frame(width: 22)
                    .foregroundStyle(containsCurrent ? DSHColor.ocean : .secondary)
                Text(title)
                    .lineLimit(1)
                    .appFont(.system(size: 16, weight: .medium))
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? Text("已展开") : Text("已收起"))

        if isExpanded {
            let ordered = sortedByActivity(sessions)
            if ordered.isEmpty {
                Text("暂无会话")
                    .appFont(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 50)
                    .padding(.vertical, 6)
            } else {
                ForEach(ordered) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: SessionSummary) -> some View {
        let selected = session.id == selectedSessionID
        return Button {
            actions.openSession(session)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(session.isRunning ? Color.green : Color.secondary.opacity(0.35))
                    .frame(width: 6, height: 6)
                Text(session.title.isEmpty ? String(localized: "未命名会话") : session.title)
                    .lineLimit(1)
                    .appFont(.system(size: 15, weight: selected ? .medium : .regular))
                Spacer(minLength: 6)
                Text(session.lastActivity.formatted(.relative(presentation: .named)))
                    .lineLimit(1)
                    .appFont(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 40)
            .padding(.leading, 34)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.07))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("app-sidebar-session-\(session.id)")
    }

    private func sortedByActivity(_ sessions: [SessionSummary]) -> [SessionSummary] {
        sessions.sorted { $0.lastActivity > $1.lastActivity }
    }

    // MARK: - 展开状态

    private func setExpanded(_ keys: Set<String>) {
        expandedKeys = keys
        expandedStorage = keys.sorted().joined(separator: ",")
    }

    private func toggle(_ key: String) {
        var keys = expandedKeys
        if keys.contains(key) { keys.remove(key) } else { keys.insert(key) }
        setExpanded(keys)
    }

    // MARK: - 底部操作栏（对齐 ChatGPT：左下黑色「聊天」胶囊 + 右下圆形设置）

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                actions.openNewSession()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                    Text("聊天")
                        .appFont(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                .padding(.horizontal, 20)
                .frame(height: 48)
                .background(
                    colorScheme == .dark ? Color.white : Color.black,
                    in: Capsule()
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("新建会话")
            .accessibilityIdentifier("app-sidebar-new-session")

            Spacer(minLength: 0)

            Button {
                actions.openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("设置")
            .accessibilityIdentifier("app-sidebar-settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, max(10, bottomInset))
    }

    // MARK: - 导航行

    private func navigationRow<Icon: View>(
        _ title: String,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon().frame(width: 22)
                Text(title).appFont(.system(size: 16))
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 侧栏的工作区分组结果。抽成独立类型是为了可以单测 —— 原本是 View 内部的私有逻辑。
struct SessionGroups: Equatable {
    var byWorkspace: [String: [SessionSummary]] = [:]
    var ungrouped: [SessionSummary] = []

    /// 同一会话属于多个工作区时，每个工作区各列一份；
    /// 不属于任何工作区的会话归入「未分组」。没有会话内容的会话不进入任何一组。
    static func group(sessions: [SessionSummary], workspaces: [GatewayWorkspace]) -> SessionGroups {
        var owners: [String: [String]] = [:]
        for workspace in workspaces {
            for sessionID in workspace.sessionIds {
                owners[sessionID, default: []].append(workspace.id)
            }
        }
        // 只连接一个项目目录时，全部可见会话都属于它：网关的 sessionIds 映射经常为空或只覆盖部分会话，
        // 按映射渲染会得到「目录空 + 一堆未分组」。多目录时仍严格按映射 + 未分组展示。
        let singleWorkspace = workspaces.count == 1 ? workspaces[0] : nil
        var result = SessionGroups()
        for session in sessions where session.isVisibleInHistory {
            if let singleWorkspace {
                result.byWorkspace[singleWorkspace.id, default: []].append(session)
            } else if let workspaceIDs = owners[session.id] {
                for workspaceID in workspaceIDs {
                    result.byWorkspace[workspaceID, default: []].append(session)
                }
            } else {
                result.ungrouped.append(session)
            }
        }
        return result
    }
}
