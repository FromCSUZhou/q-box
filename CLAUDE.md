# Q Box - 项目指南

## 项目概述

macOS 桌面四象限（艾森豪威尔矩阵）任务管理工具，帮助用户每天按重要性和紧急度规划工作。

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI, AppKit
- **最低系统**: macOS 14+
- **构建**: Swift Package Manager (`swift build -c release`)
- **打包**: `QuadrantApp/build.sh` → 生成 `Q Box.app`

## 项目结构

```
four-quadrant-work/
├── CLAUDE.md
├── QuadrantApp/                # SwiftUI macOS 应用
│   ├── Package.swift
│   ├── build.sh                # 编译 + 打包 .app bundle
│   ├── generate_icon.swift     # 图标生成脚本
│   ├── Info.plist
│   ├── AppIcon.icns
│   └── Sources/
│       ├── QuadrantApp.swift   # @main 入口
│       ├── Models/
│       │   └── TaskItem.swift  # TaskItem, Quadrant, TimeBlock, DailyTasks
│       ├── Services/
│       │   └── TaskStore.swift # 文件 I/O、任务 CRUD、迁移、统计
│       ├── Views/
│       │   ├── ContentView.swift         # 主布局 (标题栏+时间线+四象限+专注模式)
│       │   ├── QuadrantPanelView.swift   # 单个象限面板
│       │   ├── TaskRowView.swift         # 任务行 (勾选/编辑/拖拽/右键菜单)
│       │   ├── QuickAddOverlay.swift     # ⌘N 快速添加浮层
│       │   ├── MenuBarView.swift         # 菜单栏弹窗 (快速添加+概览+番茄钟)
│       │   ├── MigrationBannerView.swift # 历史未完成任务迁移提示
│       │   ├── TimelineView.swift        # 8:00-22:00 时间线视图
│       │   └── PomodoroView.swift        # 番茄钟 (PomodoroTimer + PomodoroBarView)
│       └── Helpers/
│           └── VisualEffect.swift        # NSVisualEffectView 桥接、窗口配置、拖拽区域
├── tasks/                      # 每日任务数据 (JSON)
│   └── YYYY-MM-DD.json
└── .claude/
    └── skills/
        └── plan.md             # /plan 交互式每日规划 skill
```

## 数据格式

任务文件存储在 `tasks/YYYY-MM-DD.json`，格式：

```json
{
  "date": "2026-02-28",
  "tasks": [
    {
      "id": "UUID",
      "title": "任务标题",
      "quadrant": "urgent-important",
      "completed": false,
      "createdAt": "ISO8601",
      "deadline": "ISO8601 或 null",
      "tags": [],
      "completedAt": null
    }
  ],
  "schedule": [
    {
      "id": "UUID",
      "startTime": "09:00",
      "endTime": "11:00",
      "quadrant": "urgent-important 或 null(休息)",
      "label": "专注处理"
    }
  ]
}
```

**Quadrant 枚举值**: `urgent-important`, `important-not-urgent`, `urgent-not-important`, `not-urgent-not-important`

## 构建与运行

```bash
cd QuadrantApp
./build.sh          # 编译 + 打包
open "Q Box.app"    # 运行
```

修改代码后重启：
```bash
pkill -f QuadrantApp; sleep 1 && ./build.sh && open "Q Box.app"
```

## 功能清单

- **四象限面板**: 毛玻璃效果，添加/完成/编辑/删除/拖拽移动任务
- **截止时间**: 所有添加入口都支持设置 DDL
- **时间线**: 8:00-22:00 水平时间条，彩色区块对应象限，红线标记当前时间
- **专注模式**: 双击象限标题放大该象限，ESC 退出
- **番茄钟**: 25分钟工作/5分钟休息/4轮后15分钟长休息，系统通知提醒
- **菜单栏**: 快速添加、进度概览、番茄钟面板、收工总结
- **历史迁移**: 自动检测近 3 天未完成任务，提示迁移
- **文件同步**: 2 秒轮询监听 JSON 变化，/plan skill 写入后 app 自动刷新
- **/plan skill**: 交互式每日规划，分析 DDL 和重要性，生成象限分配 + 时间段安排

## 开发注意事项

- 窗口使用 `.hiddenTitleBar` + `.ignoresSafeArea()` + 自定义标题栏，拖拽窗口仅通过顶部 `WindowDragHandle`
- 任务拖拽: `TaskRowView` 用 `.onDrag` 提供 UUID，`QuadrantPanelView` 用 `.onDrop` 接收
- 新增 `DailyTasks` 字段必须是 Optional，确保旧 JSON 文件向后兼容
- `TaskStore` 默认路径为 `~/Library/Application Support/Q Box/tasks/`（首次运行会自动从旧路径 `~/Desktop/Work/four-quadrant-work/tasks/` 迁移数据）
- 番茄钟状态不持久化，每次启动重置
- 手写 JSON 中的 UUID 必须是合法十六进制（`0-9`, `A-F`），**不能包含 G-Z 等字符**，否则 Swift `UUID` 解码会失败导致整个文件无法加载
