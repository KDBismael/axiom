import ActivityKit
import SwiftUI
import WidgetKit

struct FocusTimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            FocusTimerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    FocusTimerLockScreenView(context: context)
                        .padding(.vertical, 4)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                FocusTimerElapsedText(context: context)
                    .font(.caption2)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

private struct FocusTimerLockScreenView: View {
    let context: ActivityViewContext<FocusTimerAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.questTitle)
                    .font(.headline)
                if context.state.paused == "true" {
                    Text("En pause")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    FocusTimerElapsedText(context: context)
                        .font(.subheadline)
                }
            }
            Spacer()
            Image(systemName: "timer")
                .font(.title2)
        }
        .padding()
    }
}

/// Renders a live, OS-driven countup from `startedAt` — no per-second
/// updates from the app are needed while running.
private struct FocusTimerElapsedText: View {
    let context: ActivityViewContext<FocusTimerAttributes>

    var body: some View {
        if let startedAtMs = Double(context.attributes.startedAt) {
            let startDate = Date(timeIntervalSince1970: startedAtMs / 1000)
            Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
        } else {
            Text("--:--")
        }
    }
}
