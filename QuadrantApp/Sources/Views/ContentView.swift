import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TaskStore
    @EnvironmentObject var pomodoro: PomodoroTimer
    @State private var showMigration = true
    @State private var showQuickAdd = false
    @State private var showTimeline = true
    @State private var focusedQuadrant: Quadrant? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                titleBar
                MigrationBannerView(isVisible: $showMigration)

                if showTimeline {
                    TimelineView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                quadrantGrid
            }
            .background(WindowConfigurator())
            .background(VisualEffectBackground(material: .underWindowBackground, blendingMode: .behindWindow))

            QuickAddOverlay(isPresented: $showQuickAdd)
        }
        .ignoresSafeArea()
        .frame(minWidth: 700, minHeight: 500)
        .keyboardShortcut(for: $showQuickAdd)
        .onExitCommand {
            if focusedQuadrant != nil {
                withAnimation(.spring(duration: 0.35)) {
                    focusedQuadrant = nil
                }
            }
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        ZStack {
            WindowDragHandle()

            HStack(spacing: 0) {
                Color.clear.frame(width: 76, height: 1)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Q Box")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.8))
                }

                Spacer()

                HStack(spacing: 10) {
                    // Pomodoro timer
                    PomodoroBarView(pomodoro: pomodoro)

                    // Timeline toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showTimeline.toggle()
                        }
                    } label: {
                        Image(systemName: showTimeline ? "chart.bar.fill" : "chart.bar")
                            .font(.system(size: 12))
                            .foregroundStyle(showTimeline ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("时间线")

                    // Focus mode indicator
                    if focusedQuadrant != nil {
                        Button {
                            withAnimation(.spring(duration: 0.35)) {
                                focusedQuadrant = nil
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                    .font(.system(size: 9, weight: .bold))
                                Text("退出专注")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }

                    Text(store.todayDisplayString)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Button {
                        withAnimation { showQuickAdd = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("快速添加任务 (⌘N)")

                    let stats = store.completionStats()
                    if stats.total > 0 {
                        Text("\(stats.completed)/\(stats.total)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 38)
        .background(.bar)
    }

    // MARK: - Quadrant Grid (with focus mode)

    private var quadrantGrid: some View {
        GeometryReader { geo in
            let w = geo.size.width - 1   // 1px gap
            let h = geo.size.height - 1

            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    quadrantPanel(.urgentImportant, totalW: w)
                    quadrantPanel(.importantNotUrgent, totalW: w)
                }
                .frame(height: rowHeight(isTop: true, total: h))

                HStack(spacing: 1) {
                    quadrantPanel(.urgentNotImportant, totalW: w)
                    quadrantPanel(.notUrgentNotImportant, totalW: w)
                }
                .frame(height: rowHeight(isTop: false, total: h))
            }
            .animation(.spring(duration: 0.35), value: focusedQuadrant)
        }
    }

    private func quadrantPanel(_ q: Quadrant, totalW: CGFloat) -> some View {
        QuadrantPanelView(quadrant: q, onFocusToggle: {
            withAnimation(.spring(duration: 0.35)) {
                focusedQuadrant = focusedQuadrant == q ? nil : q
            }
        })
        .frame(width: colWidth(q, total: totalW))
        .opacity(focusedQuadrant == nil || focusedQuadrant == q ? 1.0 : 0.5)
    }

    // MARK: - Focus Mode Layout

    private func isLeftColumn(_ q: Quadrant) -> Bool {
        q == .urgentImportant || q == .urgentNotImportant
    }

    private func isTopRow(_ q: Quadrant) -> Bool {
        q == .urgentImportant || q == .importantNotUrgent
    }

    private func colWidth(_ q: Quadrant, total: CGFloat) -> CGFloat {
        guard let focused = focusedQuadrant else { return total / 2 }
        let sameCol = isLeftColumn(focused) == isLeftColumn(q)
        return sameCol ? total * 0.65 : total * 0.35
    }

    private func rowHeight(isTop: Bool, total: CGFloat) -> CGFloat {
        guard let focused = focusedQuadrant else { return total / 2 }
        let focusedIsTop = isTopRow(focused)
        return focusedIsTop == isTop ? total * 0.7 : total * 0.3
    }
}

// MARK: - Keyboard Shortcut Modifier

struct KeyboardShortcutModifier: ViewModifier {
    @Binding var flag: Bool

    func body(content: Content) -> some View {
        content
            .background(
                Button("") {
                    withAnimation { flag.toggle() }
                }
                .keyboardShortcut("n", modifiers: .command)
                .opacity(0)
            )
    }
}

extension View {
    func keyboardShortcut(for flag: Binding<Bool>) -> some View {
        modifier(KeyboardShortcutModifier(flag: flag))
    }
}
