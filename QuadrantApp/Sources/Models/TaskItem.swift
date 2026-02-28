import Foundation
import SwiftUI

enum Quadrant: String, Codable, CaseIterable, Identifiable {
    case urgentImportant = "urgent-important"
    case importantNotUrgent = "important-not-urgent"
    case urgentNotImportant = "urgent-not-important"
    case notUrgentNotImportant = "not-urgent-not-important"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .urgentImportant: return "重要且紧急"
        case .importantNotUrgent: return "重要不紧急"
        case .urgentNotImportant: return "紧急不重要"
        case .notUrgentNotImportant: return "不紧急不重要"
        }
    }

    var subtitle: String {
        switch self {
        case .urgentImportant: return "DO · 立即执行"
        case .importantNotUrgent: return "PLAN · 计划安排"
        case .urgentNotImportant: return "DELEGATE · 委托处理"
        case .notUrgentNotImportant: return "ELIMINATE · 考虑删除"
        }
    }

    var icon: String {
        switch self {
        case .urgentImportant: return "flame.fill"
        case .importantNotUrgent: return "calendar.badge.clock"
        case .urgentNotImportant: return "arrow.right.circle.fill"
        case .notUrgentNotImportant: return "archivebox"
        }
    }

    var color: Color {
        switch self {
        case .urgentImportant: return Color(red: 0.88, green: 0.28, blue: 0.28)
        case .importantNotUrgent: return Color(red: 0.22, green: 0.53, blue: 0.88)
        case .urgentNotImportant: return Color(red: 0.90, green: 0.66, blue: 0.18)
        case .notUrgentNotImportant: return Color(red: 0.52, green: 0.52, blue: 0.56)
        }
    }
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var quadrant: Quadrant
    var completed: Bool
    var createdAt: Date
    var deadline: Date?
    var tags: [String]
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        quadrant: Quadrant,
        completed: Bool = false,
        createdAt: Date = Date(),
        deadline: Date? = nil,
        tags: [String] = [],
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.quadrant = quadrant
        self.completed = completed
        self.createdAt = createdAt
        self.deadline = deadline
        self.tags = tags
        self.completedAt = completedAt
    }
}

struct TimeBlock: Identifiable, Codable, Equatable {
    var id: UUID
    var startTime: String  // "HH:mm"
    var endTime: String    // "HH:mm"
    var quadrant: Quadrant?  // nil for breaks
    var label: String

    init(id: UUID = UUID(), startTime: String, endTime: String, quadrant: Quadrant? = nil, label: String) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.quadrant = quadrant
        self.label = label
    }

    /// Convert "HH:mm" to fractional hours (e.g., "09:30" → 9.5)
    static func fractionalHour(_ timeStr: String) -> CGFloat {
        let parts = timeStr.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2 else { return 0 }
        return CGFloat(parts[0]) + CGFloat(parts[1]) / 60.0
    }
}

struct DailyTasks: Codable {
    var date: String
    var tasks: [TaskItem]
    var schedule: [TimeBlock]?
}
