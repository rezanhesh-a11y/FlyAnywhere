import SwiftUI

// هفته‌ها برای فیلتر روزهای خروج
enum Weekday: String, CaseIterable, Identifiable, Hashable {
    case any = "Any", mon = "Mon", tue = "Tue", wed = "Wed", thu = "Thu", fri = "Fri", sat = "Sat", sun = "Sun"
    var id: String { rawValue }
}

struct FlexibleDatesSheet: View {
    // ⬅️ تغییر مهم: به‌جای یک تاریخ، مجموعه‌ای از ماه‌ها
    @Binding var selectedMonths: Set<Date>
    @Binding var minNights: Int
    @Binding var maxNights: Int
    @Binding var selectedWeekdays: Set<Weekday>

    @Environment(\.dismiss) private var dismiss

    // MARK: - ثابت‌ها و داده‌ها
    private let weekdayItems: [Weekday] = [.any, .mon, .tue, .wed, .thu, .fri, .sat, .sun]
    private let monthOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()
    private let monthCols: [GridItem]   = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private let weekdayCols: [GridItem] = [GridItem(.adaptive(minimum: 70), spacing: 10)]

    /// 12 ماه آینده (نرمال‌شده به اولِ هر ماه)
    private var anchors: [Date] {
        let cal = Calendar.current
        let today = Date()
        return (0..<12).compactMap { i in
            guard let m = cal.date(byAdding: .month, value: i, to: today) else { return nil }
            return normalizeToMonth(m)
        }
    }

    // MARK: - UI
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // When do you want to leave?
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When do you want to leave?")
                            .font(.headline)

                        LazyVGrid(columns: monthCols, spacing: 12) {
                            ForEach(anchors, id: \.self) { date in
                                let normalized = normalizeToMonth(date)               // روز اول همان ماه
                                MonthAnchorButton(
                                    title: monthLabelMMM(for: normalized),            // فقط "MMM"
                                    isSelected: containsMonth(normalized)             // مقایسه بر اساس سال/ماه
                                ) {
                                    toggleMonth(normalized)                           // انتخاب/حذف همان ماه
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // How long would you like to stay?
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How long would you like to stay?")
                            .font(.headline)

                        Text("\(minNights) to \(maxNights) nights")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // اسلایدر دو سر (۱ تا ۳۱ شب)
                        RangeNightsSlider(
                            range: Binding(
                                get: { Double(minNights)...Double(maxNights) },
                                set: {
                                    var lower = Int(floor($0.lowerBound))
                                    var upper = Int(ceil($0.upperBound))
                                    lower = max(1, min(lower, 31))
                                    upper = max(1, min(upper, 31))
                                    if lower > upper { lower = upper }
                                    minNights = lower
                                    maxNights = upper
                                }
                            ),
                            bounds: 1...31
                        )
                        HStack {
                            Text("1 night").font(.footnote).foregroundStyle(.secondary)
                            Spacer()
                            Text("31 nights").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // What days would you like to leave?
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What days would you like to leave?")
                            .font(.headline)

                        LazyVGrid(columns: weekdayCols, spacing: 10) {
                            ForEach(weekdayItems) { day in
                                WeekdayToggleCell(
                                    day: day,
                                    isOn: selectedWeekdays.contains(day),
                                    onTap: { toggle(day) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 16)
                }
                .padding(.top, 10)
            }
            .navigationTitle("Flexible dates")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                    }
                }
            }
            // دکمه Apply بزرگ در پایین صفحه
            Button {
                dismiss()
            } label: {
                Text("Apply")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Helpers
    private func normalizeToMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    private func monthLabelMMM(for date: Date) -> String {
        monthOnlyFormatter.string(from: date)
    }

    private func containsMonth(_ monthDate: Date) -> Bool {
        let cal = Calendar.current
        let key = cal.dateComponents([.year, .month], from: monthDate)
        return selectedMonths.contains {
            cal.dateComponents([.year, .month], from: $0) == key
        }
    }

    private func toggleMonth(_ monthDate: Date) {
        let cal = Calendar.current
        let key = cal.dateComponents([.year, .month], from: monthDate)

        if let existing = selectedMonths.first(where: {
            cal.dateComponents([.year, .month], from: $0) == key
        }) {
            selectedMonths.remove(existing)
        } else {
            var c = key; c.day = 1
            let normalized = cal.date(from: c) ?? monthDate
            selectedMonths.insert(normalized)
        }
    }

    private func toggle(_ day: Weekday) {
        if day == .any {
            selectedWeekdays = [.any]
        } else {
            selectedWeekdays.remove(.any)
            if selectedWeekdays.contains(day) {
                selectedWeekdays.remove(day)
            } else {
                selectedWeekdays.insert(day)
            }
        }
    }
}

// دکمه‌ی هر ماه
private struct MonthAnchorButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct WeekdayToggleCell: View {
    let day: Weekday
    let isOn: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(day.rawValue)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isOn ? Color.accentColor.opacity(0.15)
                                 : Color(.secondarySystemBackground))
                .foregroundStyle(isOn ? Color.accentColor : Color.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? Color.accentColor : Color.secondary.opacity(0.25))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Range slider دو سر (۱..۳۱ شب)
private struct RangeNightsSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>

    private let trackHeight: CGFloat = 4
    private let knobSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let span = bounds.upperBound - bounds.lowerBound
            let xMin = CGFloat((range.lowerBound - bounds.lowerBound) / span) * w
            let xMax = CGFloat((range.upperBound - bounds.lowerBound) / span) * w

            ZStack(alignment: .leading) {
                Capsule().fill(Color(.tertiarySystemFill)).frame(height: trackHeight)
                Capsule().fill(Color.accentColor)
                    .frame(width: max(0, xMax - xMin), height: trackHeight)
                    .offset(x: xMin)

                knob.offset(x: xMin - knobSize/2)
                    .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                        let clampedX = max(0, min(v.location.x, w))
                        let value = bounds.lowerBound + Double(clampedX / w) * span
                        let newLower = min(value, range.upperBound)
                        range = newLower...range.upperBound
                    })

                knob.offset(x: xMax - knobSize/2)
                    .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                        let clampedX = max(0, min(v.location.x, w))
                        let value = bounds.lowerBound + Double(clampedX / w) * span
                        let newUpper = max(value, range.lowerBound)
                        range = range.lowerBound...newUpper
                    })
            }
            .frame(height: knobSize)
        }
        .frame(height: knobSize)
    }

    private var knob: some View {
        Circle()
            .fill(.background)
            .overlay(Circle().stroke(Color.secondary, lineWidth: 0.5))
            .frame(width: knobSize, height: knobSize)
            .shadow(radius: 0.5)
    }
}

// Preview
#Preview {
    FlexibleDatesSheet(
        selectedMonths: .constant([Date()]),
        minNights: .constant(2),
        maxNights: .constant(9),
        selectedWeekdays: .constant([.any])
    )
}
