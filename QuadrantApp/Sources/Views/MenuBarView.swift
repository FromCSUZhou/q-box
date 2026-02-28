import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var store: TaskStore
    @EnvironmentObject var pomodoro: PomodoroTimer
    @State private var newTaskTitle = ""
    @State private var selectedQuadrant: Quadrant = .urgentImportant
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()

    private var isEndOfDay: Bool {
        Calendar.current.component(.hour, from: Date()) >= 17
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Q Box")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text(store.todayDisplayString)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().opacity(0.3)

            // Pomodoro section
            pomodoroSection

            Divider().opacity(0.3)

            // Quick add section
            quickAddSection

            Divider().opacity(0.3)

            // Today's overview with summary
            dailySummarySection

            Divider().opacity(0.3)

            // Footer
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                    Text("退出")
                        .font(.system(size: 11.5))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 280)
    }

    // MARK: - Pomodoro

    private var pomodoroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("番茄钟")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if pomodoro.completedPomodoros > 0 {
                    Text("今日 \(pomodoro.completedPomodoros) 个")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: pomodoro.progress)
                        .stroke(pomodoro.stateColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: pomodoro.progress)

                    Text(pomodoro.displayTime)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(pomodoro.isRunning ? pomodoro.stateColor : .secondary)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pomodoro.stateLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(pomodoro.isRunning ? pomodoro.stateColor : .primary)

                    // Pomodoro count dots
                    HStack(spacing: 3) {
                        ForEach(0..<4, id: \.self) { i in
                            Circle()
                                .fill(i < (pomodoro.completedPomodoros % 4) ? Color.red.opacity(0.7) : Color.primary.opacity(0.1))
                                .frame(width: 6, height: 6)
                        }
                        Text("每 4 个长休息")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }

                    HStack(spacing: 6) {
                        if pomodoro.isRunning {
                            Button {
                                pomodoro.stop()
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 9))
                                    Text("停止")
                                        .font(.system(size: 10))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)

                            Button {
                                pomodoro.skip()
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 9))
                                    Text("跳过")
                                        .font(.system(size: 10))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                pomodoro.startWork()
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 9))
                                    Text("开始专注")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(14)
    }

    // MARK: - Quick Add

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速添加")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("任务内容...", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .onSubmit { addTask() }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(Quadrant.allCases) { q in
                    Button {
                        selectedQuadrant = q
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(q.color)
                                .frame(width: 7, height: 7)
                            Text(q.title)
                                .font(.system(size: 10.5, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            selectedQuadrant == q
                                ? q.color.opacity(0.12)
                                : Color.primary.opacity(0.04)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Deadline toggle
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hasDeadline.toggle()
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: hasDeadline ? "calendar.badge.clock" : "calendar")
                            .font(.system(size: 10))
                        Text("截止时间")
                            .font(.system(size: 10.5))
                    }
                    .foregroundStyle(hasDeadline ? .primary : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(hasDeadline ? Color.orange.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)

                if hasDeadline {
                    DatePicker(
                        "",
                        selection: $deadline,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .controlSize(.mini)
                }
                Spacer()
            }

            Button {
                addTask()
            } label: {
                Text("添加")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(14)
    }

    // MARK: - Daily Summary

    private var dailySummarySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isEndOfDay ? "今日总结" : "今日概览")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if isEndOfDay {
                    efficiencyBadge
                }
            }

            ForEach(Quadrant.allCases) { q in
                let tasks = store.tasksFor(quadrant: q)
                let completed = tasks.filter(\.completed).count
                let total = tasks.count

                HStack(spacing: 6) {
                    Circle()
                        .fill(q.color)
                        .frame(width: 7, height: 7)
                    Text(q.title)
                        .font(.system(size: 11.5))
                    Spacer()

                    if total > 0 && completed == total {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }

                    Text("\(completed)/\(total)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    if total > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(q.color.opacity(0.6))
                                    .frame(
                                        width: geo.size.width * CGFloat(completed) / CGFloat(total),
                                        height: 4
                                    )
                            }
                        }
                        .frame(width: 40, height: 4)
                    }
                }
            }

            // Total progress
            let stats = store.completionStats()
            if stats.total > 0 {
                Divider().opacity(0.2)

                HStack {
                    Text("总进度")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()

                    // Progress bar
                    let pct = Double(stats.completed) / Double(stats.total)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.primary.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(progressColor(pct).opacity(0.5))
                                .frame(width: geo.size.width * pct)
                        }
                    }
                    .frame(width: 50, height: 6)

                    Text("\(stats.completed)/\(stats.total)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                    Text("(\(Int(pct * 100))%)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                // Motivational message at end of day
                if isEndOfDay {
                    motivationalMessage(pct: Double(stats.completed) / Double(stats.total))
                }
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private var efficiencyBadge: some View {
        let stats = store.completionStats()
        if stats.total > 0 {
            let pct = Double(stats.completed) / Double(stats.total)
            Text(pct >= 0.8 ? "高效" : (pct >= 0.5 ? "良好" : "加油"))
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(progressColor(pct))
                .clipShape(Capsule())
        }
    }

    private func motivationalMessage(pct: Double) -> some View {
        let message: String = {
            if pct >= 1.0 { return "完美！今天所有任务都完成了" }
            if pct >= 0.8 { return "做得很好！剩余任务明天继续" }
            if pct >= 0.5 { return "进展不错，重要的事已处理大半" }
            return "明天继续加油，先完成重要的事"
        }()

        return HStack(spacing: 4) {
            Image(systemName: pct >= 0.8 ? "star.fill" : "lightbulb.fill")
                .font(.system(size: 9))
                .foregroundStyle(pct >= 0.8 ? Color.yellow : Color.orange)
            Text(message)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 2)
    }

    private func progressColor(_ pct: Double) -> Color {
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }

    private func addTask() {
        let text = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.addTask(TaskItem(
            title: text,
            quadrant: selectedQuadrant,
            deadline: hasDeadline ? deadline : nil
        ))
        newTaskTitle = ""
        hasDeadline = false
        deadline = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
