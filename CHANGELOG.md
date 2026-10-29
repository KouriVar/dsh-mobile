# Changelog

## [Unreleased] — 合并上游 4 个提交（upstream/main @ 1d4f603）

### 合并
- 合并 `upstream/main`（`de9bace` 完善 Android 功能与界面、`1fa7aa7` 移除 3083 行废弃代码、`8859a80` 会话分页与顶部玻璃蒙层、`1d4f603` Android 架构与功能）。冲突文件 4 个：`ConversationView.swift`、`RootView.swift`、`ConversationViewport.swift`、`project.pbxproj`。
- 冲突策略：保留我方 ChatGPT 风格导航栏与输入框改版的结构与视觉，移植上游功能增量（会话侧栏、分页指示器、`topContentInset` 容器契约、非 iOS 26 顶部玻璃蒙层、数学公式与代码高亮、Live Activity 扩展）。
- 上游 `AgentLiveActivityWidget` 扩展 target 带入了其个人签名配置（`DEVELOPMENT_TEAM = SHVN6YQNQF / T58RY5HUA7`、`com.lichaofan.dshmobile` 包名硬编码），已统一改回 `$(LOCAL_DEVELOPMENT_TEAM)` / `$(LOCAL_BUNDLE_IDENTIFIER)`，否则本机无法签名装机。
- 我方 `ConversationView` 的键盘安全区（GeometryReader + Home Indicator）与输入框折叠动画整体保留；上游 `topContentInset` 契约接入为 `pageTopInset`。

### 修复
- 导航栏副标题重复：上游把标题移入 principal `ToolbarItem`，与 `navigationSubtitle` 叠加后出现三行；已改回系统标题位（`navigationTitle` + `navigationSubtitle`），恢复「标题 + 文件夹 · 主机」两行。
- `ConversationViewport` 合并后 `topInset` 重复声明、`topInset`/`bottomInset` 实参顺序与上游声明顺序不一致，均已修正。

### 调整（标题栏定稿）
- 标题栏只保留三项：**返回**（系统）、**项目名称**（`navigationTitle`）、**项目文件夹**（`navigationSubtitle`）。
- 移除会话侧栏按钮（`sidebarButton`、`showsSidebar`、侧栏 popover 与 `ConversationSidebar` 接线一并删除；侧栏视图文件保留备用）。
- 移除「新建会话」笔按钮（`newSessionButton`）；`onNewSession` 通道保留供后续入口复用。
- 「成员」入口（`TeamNavigationEntry`）移到原新建按钮的位置，与「更多」合并为一个工具栏胶囊；`compactHeader` 下右侧仅 2 个图标。
- 同时移除未被启用的上游 principal 标题组件（`pageTitle`），标题统一走系统标题位。

### 已知
- 副标题目前仍为「文件夹 · 主机」（如 `默认文件-DeepSeek · 192.168.31.131`）；若只需文件夹名可再收窄。
- 会话侧栏功能已无 UI 入口（代码保留），如需恢复建议挂到「更多」菜单。

## [Unreleased] — 移动端对话页 UI 改版（基于 v1.7.11 源码 9bf3955）

### 新增 / 改进
- 顶部恢复 iOS 26 风格渐进模糊：内容滑入导航栏下方时由系统 soft 边缘效果柔化淡出，去掉硬分隔线，并隐藏系统 hard 边缘（iOS 27 默认）以还原柔和观感。
- 导航栏改为 ChatGPT 风格：左侧返回；标题下方显示「工作区文件夹 · 主机」动态副标题；右侧新增「新建会话」笔按钮与「更多」菜单。
- 输入框按 ChatGPT 重做：内间距 12、图标间距 12、图标颜色自适应（深色白 / 浅色黑）；发送按钮随模式反转（深色白底黑图标、浅色黑底白图标），默认语音波形、有文字时变发送箭头。
- 权限控件仅保留图标（去除「完全访问」等文字）；模型控件改为图标（cube）并移至发送按钮左侧；「上下文用量」入口移入右上角「更多」菜单。
- 输入框滚动折叠：离开底部时收拢为胶囊（仅保留＋与语音），点开或回到底部展开，使用 matchedGeometryEffect + 弹簧动画平滑形变。

### 修复
- 修复输入法弹出后输入框被键盘遮挡的问题（容器高度按 Home Indicator 计算，键盘弹出时随之上移）；输入框底部间距调整为 40。
- 修复新建会话时主线程栈溢出闪退（拆分 composer 工具栏为 composerControls 并加入 AnyView 类型边界）。
- 权限名称汉化（auto / read-only / workspace-write / danger-full-access / custom）；版本号更新至 1.7.11 (32)。
