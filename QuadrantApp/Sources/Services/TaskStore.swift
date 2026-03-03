import Foundation
import SwiftUI
import Combine

class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var pendingMigrationTasks: [TaskItem] = []
    @Published var schedule: [TimeBlock] = []

    private let tasksDirectoryURL: URL
    private var fileWatchTimer: Timer?
    private var lastFileModification: Date?
    private var lastKnownDateString: String?

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private let displayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "M月d日 EEEE"
        return df
    }()

    var todayString: String {
        dateFormatter.string(from: Date())
    }

    var todayDisplayString: String {
        displayDateFormatter.string(from: Date())
    }

    var todayFileURL: URL {
        tasksDirectoryURL.appendingPathComponent("\(todayString).json")
    }

    init(tasksDirectory: URL? = nil) {
        self.tasksDirectoryURL = tasksDirectory ?? Self.defaultTasksDirectory()
        ensureDirectoryExists()
        Self.migrateFromLegacyDirectory(to: tasksDirectoryURL)
        loadTodayTasks()
        if schedule.isEmpty { schedule = Self.defaultSchedule }
        checkPendingMigration()
        startFileWatching()
    }

    /// One-time migration from old hardcoded path to Application Support
    private static func migrateFromLegacyDirectory(to newDir: URL) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let legacyDir = homeDir.appendingPathComponent("Desktop/Work/four-quadrant-work/tasks")
        let fm = FileManager.default

        guard fm.fileExists(atPath: legacyDir.path),
              legacyDir.standardizedFileURL != newDir.standardizedFileURL else { return }

        guard let files = try? fm.contentsOfDirectory(atPath: legacyDir.path) else { return }
        let jsonFiles = files.filter { $0.hasSuffix(".json") }
        guard !jsonFiles.isEmpty else { return }

        for file in jsonFiles {
            let src = legacyDir.appendingPathComponent(file)
            let dst = newDir.appendingPathComponent(file)
            if !fm.fileExists(atPath: dst.path) {
                try? fm.copyItem(at: src, to: dst)
            }
        }
    }

    static let defaultSchedule: [TimeBlock] = [
        TimeBlock(startTime: "08:00", endTime: "08:30", quadrant: nil, label: "晨间准备"),
        TimeBlock(startTime: "08:30", endTime: "11:00", quadrant: .urgentImportant, label: "专注处理"),
        TimeBlock(startTime: "11:00", endTime: "12:00", quadrant: .urgentNotImportant, label: "快速处理"),
        TimeBlock(startTime: "12:00", endTime: "13:30", quadrant: nil, label: "午休"),
        TimeBlock(startTime: "13:30", endTime: "15:30", quadrant: .importantNotUrgent, label: "深度工作"),
        TimeBlock(startTime: "15:30", endTime: "16:30", quadrant: .urgentNotImportant, label: "杂事处理"),
        TimeBlock(startTime: "16:30", endTime: "18:00", quadrant: .importantNotUrgent, label: "规划思考"),
        TimeBlock(startTime: "18:00", endTime: "19:00", quadrant: nil, label: "晚餐"),
        TimeBlock(startTime: "19:00", endTime: "21:00", quadrant: .importantNotUrgent, label: "自我提升"),
        TimeBlock(startTime: "21:00", endTime: "22:00", quadrant: .notUrgentNotImportant, label: "放松收尾"),
    ]

    static func defaultTasksDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Q Box/tasks")
    }

    // MARK: - File Operations

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(
            at: tasksDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    func loadTodayTasks() {
        guard FileManager.default.fileExists(atPath: todayFileURL.path),
              let data = try? Data(contentsOf: todayFileURL) else {
            tasks = []
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let daily = try? decoder.decode(DailyTasks.self, from: data) {
            tasks = daily.tasks
            schedule = daily.schedule ?? Self.defaultSchedule
        }
    }

    func saveTasks() {
        let daily = DailyTasks(date: todayString, tasks: tasks, schedule: schedule.isEmpty ? nil : schedule)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let data = try? encoder.encode(daily) {
            try? data.write(to: todayFileURL, options: .atomic)
            lastFileModification = try? FileManager.default
                .attributesOfItem(atPath: todayFileURL.path)[.modificationDate] as? Date
        }
    }

    // MARK: - Task CRUD

    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveTasks()
    }

    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func toggleComplete(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].completed.toggle()
            tasks[index].completedAt = tasks[index].completed ? Date() : nil
            saveTasks()
        }
    }

    func moveTask(_ task: TaskItem, to quadrant: Quadrant) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].quadrant = quadrant
            saveTasks()
        }
    }

    func moveTaskById(_ id: UUID, to quadrant: Quadrant) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].quadrant = quadrant
            saveTasks()
        }
    }

    func tasksFor(quadrant: Quadrant) -> [TaskItem] {
        tasks.filter { $0.quadrant == quadrant }
    }

    func sortedTasks(for quadrant: Quadrant) -> [TaskItem] {
        let quadrantTasks = tasksFor(quadrant: quadrant)
        let incomplete = quadrantTasks
            .filter { !$0.completed }
            .sorted {
                switch ($0.deadline, $1.deadline) {
                case let (d0?, d1?):
                    return d0 < d1
                case (_?, nil):
                    return false
                case (nil, _?):
                    return true
                default:
                    return $0.createdAt < $1.createdAt
                }
            }
        let completed = quadrantTasks
            .filter { $0.completed }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
        return incomplete + completed
    }

    // MARK: - Migration

    func checkPendingMigration() {
        let calendar = Calendar.current
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // First pass: collect completed task titles from today and all recent days
        var completedTitles = Set(tasks.filter(\.completed).map(\.title))
        for dayOffset in 1...3 {
            guard let pastDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let pastDateString = dateFormatter.string(from: pastDate)
            let pastFileURL = tasksDirectoryURL.appendingPathComponent("\(pastDateString).json")

            guard FileManager.default.fileExists(atPath: pastFileURL.path),
                  let data = try? Data(contentsOf: pastFileURL),
                  let daily = try? decoder.decode(DailyTasks.self, from: data) else { continue }

            for task in daily.tasks where task.completed {
                completedTitles.insert(task.title)
            }
        }

        // Second pass: collect incomplete tasks, skipping those completed on any day
        for dayOffset in 1...3 {
            guard let pastDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let pastDateString = dateFormatter.string(from: pastDate)
            let pastFileURL = tasksDirectoryURL.appendingPathComponent("\(pastDateString).json")

            guard FileManager.default.fileExists(atPath: pastFileURL.path),
                  let data = try? Data(contentsOf: pastFileURL),
                  let daily = try? decoder.decode(DailyTasks.self, from: data) else { continue }

            let incomplete = daily.tasks.filter { !$0.completed }
            let existingTitles = Set(tasks.map(\.title) + pendingMigrationTasks.map(\.title))
            let newTasks = incomplete.filter { !existingTitles.contains($0.title) && !completedTitles.contains($0.title) }
            pendingMigrationTasks.append(contentsOf: newTasks)
        }
    }

    func migrateTask(_ task: TaskItem) {
        var newTask = task
        newTask.id = UUID()
        newTask.createdAt = Date()
        newTask.completedAt = nil
        newTask.completed = false
        addTask(newTask)
        pendingMigrationTasks.removeAll { $0.id == task.id }
    }

    func migrateAllTasks() {
        for task in pendingMigrationTasks {
            var newTask = task
            newTask.id = UUID()
            newTask.createdAt = Date()
            newTask.completedAt = nil
            newTask.completed = false
            tasks.append(newTask)
        }
        pendingMigrationTasks.removeAll()
        saveTasks()
    }

    func dismissMigration(_ task: TaskItem) {
        pendingMigrationTasks.removeAll { $0.id == task.id }
    }

    func dismissAllMigration() {
        pendingMigrationTasks.removeAll()
    }

    // MARK: - File Watching

    private func startFileWatching() {
        lastKnownDateString = todayString
        lastFileModification = try? FileManager.default
            .attributesOfItem(atPath: todayFileURL.path)[.modificationDate] as? Date

        fileWatchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkDateChangeAndFileChanges()
        }
    }

    private func checkDateChangeAndFileChanges() {
        let currentDateString = todayString
        // Detect day change: reload today's (empty) tasks and re-check migration
        if currentDateString != lastKnownDateString {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.lastKnownDateString = currentDateString
                self.loadTodayTasks()
                self.pendingMigrationTasks.removeAll()
                self.checkPendingMigration()
                self.lastFileModification = try? FileManager.default
                    .attributesOfItem(atPath: self.todayFileURL.path)[.modificationDate] as? Date
            }
            return
        }

        // Normal file change detection
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: todayFileURL.path),
              let modDate = attrs[.modificationDate] as? Date else { return }

        if let last = lastFileModification, modDate > last {
            DispatchQueue.main.async { [weak self] in
                self?.loadTodayTasks()
                self?.lastFileModification = modDate
            }
        }
    }

    // MARK: - Statistics

    func completionStats() -> (total: Int, completed: Int) {
        let total = tasks.count
        let completed = tasks.filter(\.completed).count
        return (total, completed)
    }

    func quadrantStats() -> [(quadrant: Quadrant, total: Int, completed: Int)] {
        Quadrant.allCases.map { q in
            let qTasks = tasksFor(quadrant: q)
            return (q, qTasks.count, qTasks.filter(\.completed).count)
        }
    }

    // MARK: - Weekly Review

    func weeklyTasks() -> [(date: String, tasks: [TaskItem])] {
        let calendar = Calendar.current
        var result: [(String, [TaskItem])] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            let fileURL = tasksDirectoryURL.appendingPathComponent("\(dateString).json")

            guard FileManager.default.fileExists(atPath: fileURL.path),
                  let data = try? Data(contentsOf: fileURL) else { continue }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let daily = try? decoder.decode(DailyTasks.self, from: data) {
                result.append((dateString, daily.tasks))
            }
        }

        return result
    }
}
