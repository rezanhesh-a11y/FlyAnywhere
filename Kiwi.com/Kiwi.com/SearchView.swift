import SwiftUI

// MARK: - Trip Type Enum
enum TripType: String, CaseIterable, Identifiable {
    case returnTrip = "Return"
    case oneWay     = "One way"
    var id: String { rawValue }
}

// لیبل کوچک بالای هر فیلد (مثل Ryanair)
private struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 2)
    }
}

// بک‌گراند کارت‌های ورودی
private struct FieldCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Main Search View
struct SearchView: View {
    // فیلدها
    @State private var tripType: TripType = .returnTrip
    @State private var from = "Naples"
    @State private var to = ""
    @State private var passengers = 1

    // تاریخ معمولی
    @State private var departDate = Date()
    @State private var returnDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

    // Flexible
    @State private var flexibleDates = true
    @State private var selectedMonths: Set<Date> = []
    @State private var minNights = 2
    @State private var maxNights = 7
    @State private var selectedWeekdays: Set<Weekday> = [.any]
    // Sheet
    @State private var showDateSheet = false
    @State private var goResults = false
    // ⬇️ این 3 قطعه را درست زیر Stateها و قبل از var body بگذار
    // شروع ماه (نرمالایز: فقط سال/ماه)
    // شروع ماه (normalize) برای مقایسه
    private func normalizeMonth(_ d: Date) -> Date {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month], from: d)
        return cal.date(from: c) ?? d
    }

    // فرمت کوتاه ماه (Nov, Dec, ...)
    private let monthAbbrev: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    /// از مجموعه‌ی ماه‌های انتخاب‌شده، رشته‌ی نمایشی بساز:
    //  - ماه‌های پشتِ‌سرِهم: به شکل "Nov–Jan"
    //  - ماه‌های غیرپیوسته: با کاما "Nov, Feb, Apr"
    private func monthRangesText(from months: Set<Date>) -> String {
        let cal = Calendar.current

        // یکتا + نرمال به اولِ ماه + مرتب
        let uniq = Array(months.map(normalizeMonth)).sorted()
        if uniq.isEmpty { return "" }

        var parts: [String] = []
        var i = 0
        while i < uniq.count {
            let start = uniq[i]
            var end = start
            var j = i + 1

            // تا وقتی ماه بعدی دقیقاً +۱ ماه باشد، ادامه بده
            while j < uniq.count {
                let expectedNext = cal.date(byAdding: .month, value: 1, to: end)!
                if cal.isDate(uniq[j], equalTo: expectedNext, toGranularity: .month) {
                    end = uniq[j]
                    j += 1
                } else {
                    break
                }
            }

            // یک ماه یا رِنج؟
            if start == end {
                parts.append(monthAbbrev.string(from: start))
            } else {
                parts.append("\(monthAbbrev.string(from: start))–\(monthAbbrev.string(from: end))")
            }

            i = j
        }

        return parts.joined(separator: ", ")
    }
    // فرمت‌های تاریخ
    private let monthLongFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"      // November
        return f
    }()
    private let monthShortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"     // Nov 1
        return f
    }()
    private let dayShortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"     // 1 Nov
        return f
    }()

    // متنِ نمایشی Travel dates بر اساس حالت‌ها
    private var builtParams: SearchParams {
        SearchParams(
            from: from,
            to: to,
            tripType: tripType,
            flexibleDates: flexibleDates,
            departDate: departDate,
            returnDate: returnDate,
            selectedMonths: Array(selectedMonths).sorted(),
            minNights: minNights,
            maxNights: maxNights,
            passengers: passengers
        )
    }
    private func travelDatesLabel() -> String {
        if flexibleDates {
            // اگر کاربر هنوز انتخاب نکرده بود، می‌تونی خالی برگردونی یا ماه جاری را نمایش بده
            let monthsSet = selectedMonths.isEmpty ? [] : selectedMonths
            let monthsText = monthRangesText(from: monthsSet)

            if tripType == .oneWay {
                // One way: فقط ماه‌ها
                return monthsText.isEmpty ? "Select month(s)" : monthsText
            } else {
                // Return: ماه‌ها + تعداد شب‌ها
                return monthsText.isEmpty
                    ? "Select month(s) • \(minNights)–\(maxNights) nights"
                    : "\(monthsText) • \(minNights)–\(maxNights) nights"
            }
        } else {
            // — این بخش همانی بماند که داری —
            let f = DateFormatter(); f.dateFormat = "d MMM"
            if tripType == .oneWay {
                return f.string(from: departDate)
            } else {
                let r = max(returnDate, departDate)
                return "\(f.string(from: departDate)) – \(f.string(from: r))"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {

                // Return / One-way (بالا)
                Picker("Trip type", selection: $tripType) {
                    Text("Return").tag(TripType.returnTrip)
                    Text("One way").tag(TripType.oneWay)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)

                // FROM
                FieldLabel(text: "From")
                HStack {
                    Image(systemName: "airplane.departure")
                        .foregroundStyle(.tint)
                    TextField("City or airport", text: $from)
                        .textInputAutocapitalization(.words)
                }
                .modifier(FieldCard())

                // TO
                FieldLabel(text: "To")
                HStack {
                    Image(systemName: "airplane.arrival")
                        .foregroundStyle(.tint)
                    TextField("Any destination", text: $to)
                        .textInputAutocapitalization(.words)
                }
                .modifier(FieldCard())

                // Flexible toggle — بین To و Travel dates
                HStack(spacing: 8) {
                    Spacer()
                    Text("Flexible dates")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Toggle("", isOn: $flexibleDates)
                        .labelsHidden()
                }
                .padding(.top, 2)

                // TRAVEL DATES
                FieldLabel(text: "Travel dates")
                Button {
                    showDateSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                        Text(travelDatesLabel())
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .modifier(FieldCard())

                // PASSENGERS
                HStack {
                    Image(systemName: "person.fill")
                    Stepper("\(passengers) adult\(passengers > 1 ? "s" : "")",
                            value: $passengers, in: 1...9)
                }
                .modifier(FieldCard())

                // SEARCH
                Button {
                    goResults = true
                } label: {
                    Label("Search flights", systemImage: "airplane.departure")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .navigationTitle("Search")
            // ✅ نتایج: وقتی goResults true شد برو به ResultsView
            .navigationDestination(isPresented: $goResults) {
                ResultsView(params: builtParams)
            }
        }
        // Sheet انتخاب تاریخ (شرطی بر اساس Flexible)
        .fullScreenCover(isPresented: $showDateSheet) {
            if flexibleDates {
                FlexibleDatesSheet(
                    selectedMonths: $selectedMonths,
                    minNights: $minNights,
                    maxNights: $maxNights,
                    selectedWeekdays: $selectedWeekdays
                )
                .presentationDetents(Set([.medium, .large]))
            } else {
                DatePickerSheet(
                    tripType: $tripType,
                    departDate: $departDate,
                    returnDate: $returnDate
                )
                .presentationDetents(Set([.medium, .large]))
            }
        }
    }

    
}

/// MARK: - Date Picker Sheet (حالت غیر Flexible)
private struct DatePickerSheet: View {
    enum Leg: String, CaseIterable, Identifiable { case flyOut = "Fly out", flyBack = "Fly back"; var id: String { rawValue } }

    @Binding var tripType: TripType
    @Binding var departDate: Date
    @Binding var returnDate: Date

    @State private var leg: Leg = .flyOut
    @Environment(\.dismiss) private var dismiss

    private let minDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                // تب: Fly out / Fly back
                Picker("Leg", selection: $leg) {
                    Text("Fly out").tag(Leg.flyOut)
                    if tripType == .returnTrip {
                        Text("Fly back").tag(Leg.flyBack)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // تقویم تاریخ رفت
                if leg == .flyOut || tripType == .oneWay {
                    Form {
                        Section(header: Text("Departure")) {
                            DatePicker(
                                "Choose date",
                                selection: $departDate,
                                in: minDate...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)   // اسکرول ماه‌ها
                        }
                    }
                    .onChange(of: departDate) { _, _ in
                        if tripType == .returnTrip { leg = .flyBack }     // بعد از انتخاب، برو روی برگشت
                        if returnDate < departDate { returnDate = departDate }
                    }
                }

                // تقویم تاریخ برگشت (فقط برای Return)
                if tripType == .returnTrip && leg == .flyBack {
                    Form {
                        Section(header: Text("Return")) {
                            DatePicker(
                                "Choose date",
                                selection: Binding(
                                    get: { max(returnDate, departDate) },
                                    set: { newVal in returnDate = max(newVal, departDate) }
                                ),
                                in: departDate...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Travel dates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
// MARK: - Preview (فقط یکی برای جلوگیری از مشکل ماکرو)
#Preview {
    NavigationStack { SearchView() }
}
