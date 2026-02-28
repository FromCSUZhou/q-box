import SwiftUI

struct MigrationBannerView: View {
    @EnvironmentObject var store: TaskStore
    @Binding var isVisible: Bool
    @State private var isExpanded = false

    var body: some View {
        if !store.pendingMigrationTasks.isEmpty && isVisible {
            VStack(spacing: 0) {
                // Summary bar
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.forward.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)

                    Text("你有 \(store.pendingMigrationTasks.count) 个历史未完成的任务")
                        .font(.system(size: 12, weight: .medium))

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button("全部迁移") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.migrateAllTasks()
                        }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.dismissAllMigration()
                            isVisible = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Expanded task list
                if isExpanded {
                    Divider().opacity(0.3).padding(.horizontal, 16)

                    VStack(spacing: 0) {
                        ForEach(store.pendingMigrationTasks) { task in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(task.quadrant.color)
                                    .frame(width: 6, height: 6)
                                Text(task.title)
                                    .font(.system(size: 11.5))
                                    .lineLimit(1)
                                Spacer()
                                Text(task.quadrant.title)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)

                                Button {
                                    withAnimation {
                                        store.migrateTask(task)
                                    }
                                } label: {
                                    Image(systemName: "arrow.uturn.forward")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.orange)
                                }
                                .buttonStyle(.plain)
                                .help("迁移到今天")

                                Button {
                                    withAnimation {
                                        store.dismissMigration(task)
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("忽略")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .background(Color.orange.opacity(0.06))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
