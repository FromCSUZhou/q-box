import SwiftUI
import UniformTypeIdentifiers

struct TaskRowView: View {
    let task: TaskItem
    @EnvironmentObject var store: TaskStore
    @State private var isEditing = false
    @State private var editText: String = ""
    @State private var isHovering = false
    @State private var isEditingDeadline = false
    @State private var editDeadline: Date = Date()

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.toggleComplete(task)
                }
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(task.completed ? Color.green.opacity(0.8) : .secondary)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                    .onSubmit { submitEdit() }
                    .onExitCommand { cancelEdit() }
            } else {
                Text(task.title)
                    .font(.system(size: 12.5))
                    .strikethrough(task.completed, color: .secondary.opacity(0.5))
                    .foregroundStyle(task.completed ? .secondary : .primary)
                    .lineLimit(2)
                    .onTapGesture(count: 2) { startEditing() }
            }

            Spacer(minLength: 4)

            if isHovering || !task.tags.isEmpty || task.deadline != nil {
                HStack(spacing: 4) {
                    ForEach(task.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                    if let deadline = task.deadline, !task.completed {
                        deadlineLabel(deadline)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(isHovering ? Color.primary.opacity(0.04) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onHover { isHovering = $0 }
        .onDrag {
            NSItemProvider(object: task.id.uuidString as NSString)
        }
        .contextMenu { contextMenuContent }
        .popover(isPresented: $isEditingDeadline, arrowEdge: .bottom) {
            VStack(spacing: 8) {
                Text("截止时间")
                    .font(.system(size: 12, weight: .medium))
                DatePicker("", selection: $editDeadline, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                HStack(spacing: 8) {
                    Button("取消") { isEditingDeadline = false }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    Button("确定") { submitDeadline() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button("编辑标题") { startEditing() }

        if task.deadline != nil {
            Button("修改截止时间") { startEditingDeadline() }
            Button("清除截止时间") {
                var updated = task
                updated.deadline = nil
                store.updateTask(updated)
            }
        } else {
            Button("设置截止时间") { startEditingDeadline() }
        }

        Menu("移动到...") {
            ForEach(Quadrant.allCases) { q in
                if q != task.quadrant {
                    Button {
                        store.moveTask(task, to: q)
                    } label: {
                        Label(q.title, systemImage: q.icon)
                    }
                }
            }
        }

        Divider()

        Button("删除", role: .destructive) {
            withAnimation(.easeInOut(duration: 0.2)) {
                store.deleteTask(task)
            }
        }
    }

    private func deadlineLabel(_ deadline: Date) -> some View {
        let isOverdue = deadline < Date()
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(deadline)
        let isTomorrow = calendar.isDateInTomorrow(deadline)

        let text: String
        if isToday {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            text = "今天 \(formatter.string(from: deadline))"
        } else if isTomorrow {
            text = "明天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            text = formatter.string(from: deadline)
        }

        return Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(isOverdue ? .red : (isToday ? .orange : .secondary))
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(isOverdue ? Color.red.opacity(0.1) : Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func startEditing() {
        editText = task.title
        isEditing = true
    }

    private func submitEdit() {
        let text = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty && text != task.title {
            var updated = task
            updated.title = text
            store.updateTask(updated)
        }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }

    private func startEditingDeadline() {
        editDeadline = task.deadline ?? Date()
        isEditingDeadline = true
    }

    private func submitDeadline() {
        var updated = task
        updated.deadline = editDeadline
        store.updateTask(updated)
        isEditingDeadline = false
    }
}
