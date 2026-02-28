import SwiftUI

struct QuadrantPanelView: View {
    let quadrant: Quadrant
    var onFocusToggle: (() -> Void)? = nil
    @EnvironmentObject var store: TaskStore
    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @FocusState private var isAddFieldFocused: Bool
    @State private var isTargeted = false

    var sortedTasks: [TaskItem] {
        store.sortedTasks(for: quadrant)
    }

    var incompleteCount: Int {
        store.tasksFor(quadrant: quadrant).filter { !$0.completed }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent color bar
            quadrant.color
                .frame(height: 3)

            // Header
            header
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()
                .opacity(0.5)
                .padding(.horizontal, 14)

            // Task list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sortedTasks) { task in
                        TaskRowView(task: task)
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 0)

            // Add task area
            addTaskArea
        }
        .frame(minWidth: 200, minHeight: 180)
        .background(VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(
                    isTargeted ? quadrant.color.opacity(0.4) : .clear,
                    lineWidth: 2
                )
        )
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: quadrant.icon)
                        .font(.system(size: 11))
                        .foregroundStyle(quadrant.color)
                    Text(quadrant.title)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(quadrant.subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if incompleteCount > 0 {
                Text("\(incompleteCount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(quadrant.color.opacity(0.8))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(quadrant.color.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onFocusToggle?()
        }
    }

    @ViewBuilder
    private var addTaskArea: some View {
        if isAddingTask {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                    TextField("输入任务内容，回车添加", text: $newTaskTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12.5))
                        .focused($isAddFieldFocused)
                        .onSubmit { submitNewTask() }
                        .onExitCommand { resetAddState() }
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hasDeadline.toggle()
                        }
                    } label: {
                        Image(systemName: hasDeadline ? "calendar.badge.clock" : "calendar")
                            .font(.system(size: 12))
                            .foregroundStyle(hasDeadline ? quadrant.color : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("设置截止时间")
                    Button {
                        resetAddState()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }

                if hasDeadline {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        DatePicker(
                            "",
                            selection: $deadline,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .controlSize(.small)
                        Spacer()
                    }
                    .padding(.leading, 22)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))
            .onAppear { isAddFieldFocused = true }
        } else {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isAddingTask = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                    Text("添加任务")
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
    }

    private func submitNewTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let task = TaskItem(
            title: title,
            quadrant: quadrant,
            deadline: hasDeadline ? deadline : nil
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            store.addTask(task)
        }
        newTaskTitle = ""
        hasDeadline = false
        deadline = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        // Keep adding mode open for rapid entry
        isAddFieldFocused = true
    }

    private func resetAddState() {
        isAddingTask = false
        newTaskTitle = ""
        hasDeadline = false
        deadline = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, _ in
            var idString: String?
            if let data = data as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let string = data as? String {
                idString = string
            }
            guard let idStr = idString, let uuid = UUID(uuidString: idStr) else { return }
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.moveTaskById(uuid, to: quadrant)
                }
            }
        }
        return true
    }
}
