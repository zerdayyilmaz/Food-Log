//
//  WeeklyHealthReportView.swift
//  FoodLog
//
//  Created by Zerda Yılmaz on 29.08.2025.
//

import SwiftUI
import Charts
import Firebase
import FirebaseAuth

struct WeeklyReport: Identifiable {
    var id: String { weekKey }
    let weekKey: String
    let start: Date
    let end: Date
    let totalDaysLogged: Int
    let totalTrigger: Int
    let totalSafe: Int
    let topTriggers: [(String, Int)]
    let topSafe: [(String, Int)]
    let symptomFrequency: [(String, Int)]
    let moodFrequency: [(String, Int)]
    let mealBreakdown: [String: Int]
}

extension StatsViewModel {

    func buildWeeklyReport(weekOffset: Int = 0) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let cal = Calendar(identifier: .iso8601)
        let now = Date()
        let ref = cal.date(byAdding: .weekOfYear, value: weekOffset, to: now) ?? now
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: ref)
        guard let weekStart = cal.date(from: comps) else { return }
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart)!

        let wk = comps.weekOfYear ?? 0
        let yr = comps.yearForWeekOfYear ?? cal.component(.year, from: now)
        let weekKey = String(format: "%04d-W%02d", yr, wk)

        let snap = try? await Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments()

        var totalTrigger = 0, totalSafe = 0
        var trigFreq: [String:Int] = [:], safeFreq: [String:Int] = [:]
        var symptomFreq: [String:Int] = [:], moodFreq: [String:Int] = [:]
        var mealBreak: [String:Int] = ["breakfast":0,"snack":0,"dinner":0,"additional":0]
        var daysLogged: Set<Date> = []

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"

        for doc in (snap?.documents ?? []) {
            let data = doc.data()

            var day: Date?
            if let ts = data["date"] as? Timestamp {
                day = cal.startOfDay(for: ts.dateValue())
            } else if let parsed = df.date(from: doc.documentID) {
                day = cal.startOfDay(for: parsed)
            }
            guard let d = day, d >= weekStart && d < weekEnd else { continue }
            daysLogged.insert(d)

            let burned = (data["burnedFoods"] as? [String]) ?? []
            let safe   = (data["safeFoods"]   as? [String]) ?? []
            totalTrigger += burned.count
            totalSafe    += safe.count
            burned.forEach { trigFreq[$0, default:0] += 1 }
            safe.forEach   { safeFreq[$0, default:0] += 1 }

            if let symptoms = data["symptoms"] as? [String] {
                symptoms.forEach { symptomFreq[$0, default:0] += 1 }
            }
            if let mood = data["mood"] as? String, !mood.isEmpty {
                moodFreq[mood, default:0] += 1
            }
            if let meals = data["meals"] as? [String:[String]] {
                for (k,v) in meals { mealBreak[k, default:0] += v.count }
            }
        }

        func top5(_ dict: [String:Int]) -> [(String,Int)] {
            Array(dict.sorted { $0.value > $1.value }.prefix(5))
        }

        let report = WeeklyReport(
            weekKey: weekKey, start: weekStart, end: weekEnd,
            totalDaysLogged: daysLogged.count,
            totalTrigger: totalTrigger, totalSafe: totalSafe,
            topTriggers: top5(trigFreq), topSafe: top5(safeFreq),
            symptomFrequency: top5(symptomFreq),
            moodFrequency: Array(moodFreq.sorted { $0.value > $1.value }),
            mealBreakdown: mealBreak
        )
        await MainActor.run { self.weeklyReport = report }
    }
}

struct WeeklyHealthReportView: View {
    @EnvironmentObject var vm: StatsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var weekOffset: Int = 0  // 0=bu hafta, -1=geçen hafta

    private var score: Int {
        // Basit health score: Safe oranı + log gün sayısı etkisi (0–100)
        guard let r = vm.weeklyReport else { return 0 }
        let total = max(1, r.totalSafe + r.totalTrigger)
        let ratio = Double(r.totalSafe) / Double(total)       // 0..1
        let daysFactor = min(1.0, Double(r.totalDaysLogged)/7.0)
        return Int((ratio*0.8 + daysFactor*0.2) * 100.0)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Özet kart
                    VStack(alignment: .leading, spacing: 8) {
                        Text(titleText)
                            .bold().font(.system(size: 20))
                        HStack {
                            Label("Tracked days: \(vm.weeklyReport?.totalDaysLogged ?? 0)", systemImage: "calendar")
                            Spacer()
                            Label("Score: \(score)", systemImage: "heart.text.square.fill")
                        }
                        .foregroundColor(ColorPalette.Green1)
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.12))
                    .cornerRadius(12)

                    // Trigger vs Safe – donut
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trigger vs Safe")
                            .bold().font(.system(size: 18))
                        Chart {
                            if let r = vm.weeklyReport {
                                SectorMark(angle: .value("Trigger", r.totalTrigger),
                                           innerRadius: .ratio(0.6))
                                    .foregroundStyle(.red.opacity(0.6))
                                SectorMark(angle: .value("Safe", r.totalSafe),
                                           innerRadius: .ratio(0.6))
                                    .foregroundStyle(.green.opacity(0.6))
                            }
                        }
                        .frame(height: 220)
                        .emptyChartOverlay(vm.weeklyReport == nil || ((vm.weeklyReport?.totalTrigger ?? 0) + (vm.weeklyReport?.totalSafe ?? 0) == 0))
                        HStack {
                            Text("Safe: \(vm.weeklyReport?.totalSafe ?? 0)")
                                .padding(6).background(.green.opacity(0.25)).cornerRadius(10)
                            Spacer()
                            Text("Trigger: \(vm.weeklyReport?.totalTrigger ?? 0)")
                                .padding(6).background(.red.opacity(0.25)).cornerRadius(10)
                        }
                        .foregroundColor(.black)
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)

                    // Top lists
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Top Triggers").bold()
                            if let arr = vm.weeklyReport?.topTriggers, !arr.isEmpty {
                                ForEach(arr, id: \.0) { f, c in Text("• \(f.capitalized) (\(c))") }
                            } else { Text("Not enough data").foregroundColor(.secondary) }
                        }
                        Spacer(minLength: 12)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Top Safe").bold()
                            if let arr = vm.weeklyReport?.topSafe, !arr.isEmpty {
                                ForEach(arr, id: \.0) { f, c in Text("• \(f.capitalized) (\(c))") }
                            } else { Text("Not enough data").foregroundColor(.secondary) }
                        }
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)

                    // Semptom & Mood chip’leri
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Symptoms & Mood (weekly)").bold()
                        if let r = vm.weeklyReport, !(r.symptomFrequency.isEmpty && r.moodFrequency.isEmpty) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                                ForEach(r.symptomFrequency, id: \.0) { s, c in
                                    Text("\(s) \(c)")
                                        .padding(8)
                                        .background(ColorPalette.Green5).cornerRadius(10)
                                }
                                ForEach(r.moodFrequency, id: \.0) { m, c in
                                    Text("\(m) \(c)")
                                        .padding(8)
                                        .background(ColorPalette.Green5).cornerRadius(10)
                                }
                            }
                        } else {
                            EmptyChart(message: "Not enough data", height: 80)
                        }
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)

                    // Öğün dağılımı
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal breakdown").bold()
                        if let m = vm.weeklyReport?.mealBreakdown, m.values.reduce(0,+) > 0 {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                                ForEach(m.sorted(by: {$0.key < $1.key}), id: \.key) { k, v in
                                    Text("\(k.capitalized): \(v)")
                                        .padding(8)
                                        .background(ColorPalette.Green5).cornerRadius(10)
                                }
                            }
                        } else {
                            EmptyChart(message: "Not enough data", height: 80)
                        }
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .task { await vm.buildWeeklyReport(weekOffset: weekOffset) }
            .navigationTitle("Weekly Health Report")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("This week") { weekOffset = 0; Task { await vm.buildWeeklyReport(weekOffset: 0) } }
                        Button("Last week") { weekOffset = -1; Task { await vm.buildWeeklyReport(weekOffset: -1) } }
                    } label: { Image(systemName: "calendar") }
                }
            }
        }
    }

    private var titleText: String {
        if let r = vm.weeklyReport {
            let df = DateFormatter(); df.dateFormat = "MMM d"
            return "\(df.string(from: r.start)) – \(df.string(from: r.end.addingTimeInterval(-86400)))"
        }
        return "This week"
    }
}

#Preview {
    WeeklyHealthReportView()
        .environmentObject(StatsViewModel())
        .environmentObject(AuthViewModel())
}
