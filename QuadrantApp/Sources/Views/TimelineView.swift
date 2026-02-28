import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var store: TaskStore
    @State private var currentMinute: Int = 0
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private let startHour: CGFloat = 8
    private let endHour: CGFloat = 22
    private var totalHours: CGFloat { endHour - startHour }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack(alignment: .topLeading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.04))
                    .frame(height: 22)
                    .offset(y: 16)

                // Time blocks
                ForEach(store.schedule) { block in
                    timeBlockView(block, in: w)
                }

                // Hour markers (every 2 hours for readability)
                ForEach(Array(stride(from: Int(startHour), through: Int(endHour), by: 2)), id: \.self) { hour in
                    VStack(spacing: 1) {
                        Text(String(format: "%d:00", hour))
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        Rectangle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 0.5, height: 22)
                    }
                    .position(x: xPos(hour: CGFloat(hour), in: w), y: 22)
                }

                // Odd hour tick marks (subtle)
                ForEach(Array(stride(from: Int(startHour) + 1, to: Int(endHour), by: 2)), id: \.self) { hour in
                    Rectangle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 0.5, height: 12)
                        .position(x: xPos(hour: CGFloat(hour), in: w), y: 27)
                }

                // Current time indicator
                currentTimeMarker(in: w)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onReceive(timer) { _ in
            currentMinute = Calendar.current.component(.minute, from: Date())
        }
    }

    private func xPos(hour: CGFloat, in width: CGFloat) -> CGFloat {
        ((hour - startHour) / totalHours) * width
    }

    private func xPosFromString(_ timeStr: String, in width: CGFloat) -> CGFloat {
        let fh = TimeBlock.fractionalHour(timeStr)
        return ((fh - startHour) / totalHours) * width
    }

    private func timeBlockView(_ block: TimeBlock, in width: CGFloat) -> some View {
        let startX = xPosFromString(block.startTime, in: width)
        let endX = xPosFromString(block.endTime, in: width)
        let blockWidth = max(endX - startX, 0)

        return Group {
            if let q = block.quadrant {
                RoundedRectangle(cornerRadius: 3)
                    .fill(q.color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(q.color.opacity(0.35), lineWidth: 0.5)
                    )
                    .overlay(
                        Text(block.label)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(q.color.opacity(0.9))
                            .lineLimit(1)
                            .padding(.horizontal, 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.03))
                    .overlay(
                        Text(block.label)
                            .font(.system(size: 7))
                            .foregroundStyle(.quaternary)
                    )
            }
        }
        .frame(width: blockWidth, height: 20)
        .position(x: startX + blockWidth / 2, y: 27)
    }

    @ViewBuilder
    private func currentTimeMarker(in width: CGFloat) -> some View {
        let now = Date()
        let cal = Calendar.current
        let h = CGFloat(cal.component(.hour, from: now))
        let m = CGFloat(cal.component(.minute, from: now))
        let fractional = h + m / 60.0

        if fractional >= startHour && fractional <= endHour {
            let x = ((fractional - startHour) / totalHours) * width

            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 1.5, height: 28)
                .position(x: x, y: 24)

            Circle()
                .fill(Color.red)
                .frame(width: 5, height: 5)
                .position(x: x, y: 9)
        }
    }
}
