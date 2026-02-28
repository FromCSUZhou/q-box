import SwiftUI
import AppKit
import UserNotifications

class PomodoroTimer: ObservableObject {
    enum State: Equatable {
        case idle
        case working(remaining: Int)
        case shortBreak(remaining: Int)
        case longBreak(remaining: Int)
    }

    @Published var state: State = .idle
    @Published var completedPomodoros: Int = 0

    let workDuration = 25 * 60      // 25 min
    let shortBreakDuration = 5 * 60 // 5 min
    let longBreakDuration = 15 * 60 // 15 min
    let pomodorosBeforeLong = 4

    private var timer: Timer?

    var isRunning: Bool {
        if case .idle = state { return false }
        return true
    }

    var displayTime: String {
        let secs: Int
        switch state {
        case .idle: return "25:00"
        case .working(let r): secs = r
        case .shortBreak(let r): secs = r
        case .longBreak(let r): secs = r
        }
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }

    var stateLabel: String {
        switch state {
        case .idle: return "就绪"
        case .working: return "专注中"
        case .shortBreak: return "短休息"
        case .longBreak: return "长休息"
        }
    }

    var stateColor: Color {
        switch state {
        case .idle: return .secondary
        case .working: return Color(red: 0.88, green: 0.28, blue: 0.28)
        case .shortBreak: return Color(red: 0.22, green: 0.53, blue: 0.88)
        case .longBreak: return Color(red: 0.22, green: 0.53, blue: 0.88)
        }
    }

    var progress: Double {
        switch state {
        case .idle: return 0
        case .working(let r): return 1.0 - Double(r) / Double(workDuration)
        case .shortBreak(let r): return 1.0 - Double(r) / Double(shortBreakDuration)
        case .longBreak(let r): return 1.0 - Double(r) / Double(longBreakDuration)
        }
    }

    func startWork() {
        state = .working(remaining: workDuration)
        startTicking()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
    }

    func skip() {
        timer?.invalidate()
        timer = nil
        handleCompletion()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        switch state {
        case .idle:
            timer?.invalidate()
        case .working(let r):
            if r <= 1 {
                completedPomodoros += 1
                handleCompletion()
            } else {
                state = .working(remaining: r - 1)
            }
        case .shortBreak(let r):
            if r <= 1 {
                handleCompletion()
            } else {
                state = .shortBreak(remaining: r - 1)
            }
        case .longBreak(let r):
            if r <= 1 {
                handleCompletion()
            } else {
                state = .longBreak(remaining: r - 1)
            }
        }
    }

    private func handleCompletion() {
        timer?.invalidate()
        timer = nil
        sendNotification()

        switch state {
        case .working:
            if completedPomodoros % pomodorosBeforeLong == 0 {
                state = .longBreak(remaining: longBreakDuration)
            } else {
                state = .shortBreak(remaining: shortBreakDuration)
            }
            startTicking()
        case .shortBreak, .longBreak:
            state = .idle
        case .idle:
            break
        }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        switch state {
        case .working:
            content.title = "番茄钟完成！"
            content.body = "已完成 \(completedPomodoros) 个番茄，休息一下吧"
        case .shortBreak, .longBreak:
            content.title = "休息结束"
            content.body = "准备开始下一个番茄"
        case .idle:
            return
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
        NSSound.beep()
    }
}

struct PomodoroBarView: View {
    @ObservedObject var pomodoro: PomodoroTimer

    var body: some View {
        HStack(spacing: 5) {
            // Pomodoro count dots
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < (pomodoro.completedPomodoros % 4) ? Color.red.opacity(0.7) : Color.primary.opacity(0.1))
                        .frame(width: 4, height: 4)
                }
            }

            if pomodoro.isRunning {
                // Timer display
                HStack(spacing: 4) {
                    // Mini progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1.5)
                        Circle()
                            .trim(from: 0, to: pomodoro.progress)
                            .stroke(pomodoro.stateColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 12, height: 12)

                    Text(pomodoro.displayTime)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(pomodoro.stateColor)

                    Text(pomodoro.stateLabel)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)

                    // Stop button
                    Button {
                        pomodoro.stop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    // Skip button
                    Button {
                        pomodoro.skip()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(pomodoro.stateColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                // Start button
                Button {
                    pomodoro.startWork()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text("番茄")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help("开始 25 分钟番茄钟")
            }

            if pomodoro.completedPomodoros > 0 {
                Text("\(pomodoro.completedPomodoros)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
