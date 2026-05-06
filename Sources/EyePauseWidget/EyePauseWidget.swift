import EyePauseCore
import SwiftUI
import WidgetKit

struct EyePauseWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct EyePauseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> EyePauseWidgetEntry {
        EyePauseWidgetEntry(
            date: Date(),
            snapshot: WidgetSnapshot(
                nextBreakAt: Date().addingTimeInterval(20 * 60),
                status: "Active"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (EyePauseWidgetEntry) -> Void) {
        completion(EyePauseWidgetEntry(date: Date(), snapshot: WidgetSnapshotStore().load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EyePauseWidgetEntry>) -> Void) {
        let entry = EyePauseWidgetEntry(date: Date(), snapshot: WidgetSnapshotStore().load())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: entry.date) ?? entry.date

        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct EyePauseWidgetView: View {
    let entry: EyePauseWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EyePause")
                .font(.headline)

            Text(entry.snapshot?.status ?? "Not running")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            countdownText
                .font(.title2.monospacedDigit())
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .widgetBackground()
    }

    @ViewBuilder
    private var countdownText: some View {
        if let nextBreakAt = entry.snapshot?.nextBreakAt {
            Text(nextBreakAt, style: .timer)
        } else {
            Text("Not running")
        }
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(macOSApplicationExtension 14.0, *) {
            containerBackground(.background, for: .widget)
        } else {
            background(Color.clear)
        }
    }
}

@main
struct EyePauseWidget: Widget {
    let kind = "EyePauseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EyePauseWidgetProvider()) { entry in
            EyePauseWidgetView(entry: entry)
        }
        .configurationDisplayName("EyePause")
        .description("Shows the next EyePause break countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
