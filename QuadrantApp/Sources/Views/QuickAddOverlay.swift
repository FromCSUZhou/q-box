import SwiftUI

struct QuickAddOverlay: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: TaskStore
    @State private var title = ""
    @State private var selectedQuadrant: Quadrant = .urgentImportant
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            if isPresented {
                // Dimmed background
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                // Quick add card
                VStack(spacing: 14) {
                    // Input field
                    TextField("输入任务内容...", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .focused($isFocused)
                        .onSubmit { submit() }
                        .onExitCommand { dismiss() }

                    Divider().opacity(0.3)

                    // Quadrant selector
                    HStack(spacing: 6) {
                        ForEach(Quadrant.allCases) { q in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedQuadrant = q
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(q.color)
                                        .frame(width: 7, height: 7)
                                    Text(q.title)
                                        .font(.system(size: 10.5, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    selectedQuadrant == q
                                        ? q.color.opacity(0.12)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
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
                            HStack(spacing: 4) {
                                Image(systemName: hasDeadline ? "calendar.badge.clock" : "calendar")
                                    .font(.system(size: 11))
                                Text(hasDeadline ? "截止时间" : "设置截止时间")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(hasDeadline ? .primary : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(hasDeadline ? Color.orange.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
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
                            .controlSize(.small)
                            .transition(.opacity)
                        }

                        Spacer()
                    }

                    // Hint
                    HStack {
                        Text("↵ 添加  ·  ESC 取消")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                }
                .padding(18)
                .frame(width: 420)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
                .onAppear { isFocused = true }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: isPresented)
    }

    private func submit() {
        let text = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.addTask(TaskItem(
            title: text,
            quadrant: selectedQuadrant,
            deadline: hasDeadline ? deadline : nil
        ))
        dismiss()
    }

    private func dismiss() {
        title = ""
        hasDeadline = false
        deadline = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        isPresented = false
    }
}
