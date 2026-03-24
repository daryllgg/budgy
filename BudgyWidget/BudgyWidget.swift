import WidgetKit
import SwiftUI

struct BudgyProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgyEntry {
        BudgyEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgyEntry) -> Void) {
        completion(BudgyEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgyEntry>) -> Void) {
        let entry = BudgyEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct BudgyEntry: TimelineEntry {
    let date: Date
}

struct BudgyWidgetEntryView: View {
    var entry: BudgyProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(spacing: 12) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.blue)

            Text("Budgy")
                .font(.headline)
                .fontWeight(.bold)

            Link(destination: URL(string: "budgy://add-expense")!) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text("Add Expense")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Budgy")
                        .font(.title3.bold())
                }

                Text("Quick Actions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 8) {
                Link(destination: URL(string: "budgy://add-expense")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text("Add Expense")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Link(destination: URL(string: "budgy://dashboard")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.subheadline)
                        Text("Dashboard")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(width: 160)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct BudgyWidget: Widget {
    let kind: String = "BudgyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgyProvider()) { entry in
            BudgyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budgy")
        .description("Quick access to add expenses and more.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
