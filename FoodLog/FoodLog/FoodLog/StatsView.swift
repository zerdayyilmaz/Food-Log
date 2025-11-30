//
//  StatsView.swift
//  FoodLog
//
//  Created by Zerda Yilmaz on 22.05.2025.
//

import SwiftUI
import Charts
import Firebase
import FirebaseAuth

// StatsViewModel sınıfına ekle
enum ChartType: String, CaseIterable {
    case symptoms = "Symptoms"
    case mood = "Mood"
    case both = "Symptoms & Mood"
}

// StatsView.swift - Sınıfı değiştir
@MainActor
class StatsViewModel: ObservableObject {
    
    @Published var burnedCount: Int = 0
    @Published var safeCount: Int = 0
    @Published var mostBurnedFoods: [(String, Int)] = []
    @Published var mostSafeFoods: [(String, Int)] = []
    @Published var selectedFoodForSymptomStats: String = ""
    @Published var allFoods: [String] = []
    @Published var foodSymptomCounts: [(String, Int)] = []
    @Published var foodMoodCounts: [(String, Int)] = []
    
    @Published var selectedChartType: ChartType = .both
    @Published var weeklyTrends: [(date: Date, burned: Int, safe: Int)] = []
    @Published var symptomFrequency: [(String, Int)] = []
    @Published var moodFrequency: [(String, Int)] = []
    @Published var symptomTopFoods: [String: [(String, Int)]] = [:]
    @Published var dailyComments: [(date: Date, text: String)] = []
    
    @Published var weeklyReport: WeeklyReport?
    
    func fetchStats() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                var burned: Set<String> = []
                var safe: Set<String> = []

                for doc in documents {
                    let data = doc.data()
                    if let burnedFoods = data["burnedFoods"] as? [String] {
                        burned.formUnion(burnedFoods)
                    }
                    if let safeFoods = data["safeFoods"] as? [String] {
                        safe.formUnion(safeFoods)
                    }
                }

                DispatchQueue.main.async {
                    self.burnedCount = burned.count
                    self.safeCount = safe.count
                }
            }
    }

    func fetchMostBurnedFoods() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                var burnedFreq: [String: Int] = [:]

                for doc in documents {
                    let data = doc.data()
                    if let burnedFoods = data["burnedFoods"] as? [String] {
                        for food in burnedFoods {
                            burnedFreq[food, default: 0] += 1
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.mostBurnedFoods = burnedFreq.sorted { $0.value > $1.value }
                }
            }
    }

    func fetchMostSafeFoods() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                var safeFoodFreq: [String: Int] = [:]

                for doc in documents {
                    let data = doc.data()
                    if let safeFoods = data["safeFoods"] as? [String] {
                        for food in safeFoods {
                            safeFoodFreq[food, default: 0] += 1
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.mostSafeFoods = safeFoodFreq.sorted { $0.value > $1.value }
                }
            }
    }

    func fetchAllBurnedFoods() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                var allFoodsSet: Set<String> = []

                for doc in documents {
                    let data = doc.data()
                    if let burnedFoods = data["burnedFoods"] as? [String] {
                        allFoodsSet.formUnion(burnedFoods)
                    }
                    if let safeFoods = data["safeFoods"] as? [String] {
                        allFoodsSet.formUnion(safeFoods)
                    }
                }

                DispatchQueue.main.async {
                    self.allFoods = Array(allFoodsSet).sorted()
                    if self.selectedFoodForSymptomStats.isEmpty, let first = self.allFoods.first {
                        self.selectedFoodForSymptomStats = first
                        self.fetchSymptomsLinkedTo(foodName: first)
                    }
                }
            }
    }
    
    func fetchSymptomsLinkedTo(foodName: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                var symptomCounts: [String: Int] = [:]

                for doc in documents {
                    let data = doc.data()
                    let burned = (data["burnedFoods"] as? [String]) ?? []
                    let safe = (data["safeFoods"] as? [String]) ?? []
                    let symptoms = (data["symptoms"] as? [String]) ?? []

                    if burned.contains(foodName.lowercased()) || safe.contains(foodName.lowercased()) {
                        for symptom in symptoms {
                            symptomCounts[symptom, default: 0] += 1
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.foodSymptomCounts = symptomCounts.sorted { $0.value > $1.value }
                }
            }
    }

    func fetchMoodsLinkedTo(foodName: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                var moodCounts: [String: Int] = [:]

                for doc in documents {
                    let data = doc.data()
                    let burned = (data["burnedFoods"] as? [String]) ?? []
                    let safe = (data["safeFoods"] as? [String]) ?? []
                    let mood = data["mood"] as? String ?? ""

                    if burned.contains(foodName.lowercased()) || safe.contains(foodName.lowercased()) {
                        if !mood.isEmpty {
                            moodCounts[mood, default: 0] += 1
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.foodMoodCounts = moodCounts.sorted { $0.value > $1.value }
                }
            }
    }

    // Haftalık trendleri getiren fonksiyon
    func fetchWeeklyTrends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                var dailyData: [Date: (burned: Int, safe: Int)] = [:]
                
                // 7 günlük boş veri oluştur
                for dayOffset in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                        let startOfDay = calendar.startOfDay(for: date)
                        dailyData[startOfDay] = (0, 0)
                    }
                }
                
                // Gerçek verileri doldur
                for doc in documents {
                    let data = doc.data()
                    if let timestamp = data["date"] as? Timestamp {
                        let date = timestamp.dateValue()
                        let startOfDay = calendar.startOfDay(for: date)
                        
                        let burnedCount = (data["burnedFoods"] as? [String])?.count ?? 0
                        let safeCount = (data["safeFoods"] as? [String])?.count ?? 0
                        
                        dailyData[startOfDay] = (burnedCount, safeCount)
                    }
                }
                
                DispatchQueue.main.async {
                    self.weeklyTrends = dailyData
                        .sorted(by: { $0.key < $1.key })
                        .map { (date: $0.key, burned: $0.value.burned, safe: $0.value.safe) }
                }
                self.fetchDailyCommentsForWeeklyTrends()
            }
    }

    // Tüm semptom frekanslarını getir
    func fetchAllSymptomsFrequency() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                var symptomFreq: [String: Int] = [:]
                
                for doc in documents {
                    let data = doc.data()
                    if let symptoms = data["symptoms"] as? [String] {
                        for symptom in symptoms {
                            symptomFreq[symptom, default: 0] += 1
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.symptomFrequency = symptomFreq.sorted { $0.value > $1.value }
                }
            }
    }

    // Tüm mood frekanslarını getir
    func fetchAllMoodsFrequency() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                var moodFreq: [String: Int] = [:]
                
                for doc in documents {
                    let data = doc.data()
                    if let mood = data["mood"] as? String, !mood.isEmpty {
                        moodFreq[mood, default: 0] += 1
                    }
                }
                
                DispatchQueue.main.async {
                    self.moodFrequency = moodFreq.sorted { $0.value > $1.value }
                }
            }
    }

    func fetchDailyCommentsForWeeklyTrends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let cal = Calendar.current
        let now = Date()

        // 👇 Haftalık trendten bağımsız: her zaman son 7 günün startOfDay set'i
        var wanted: Set<Date> = []
        for i in 0..<7 {
            if let d = cal.date(byAdding: .day, value: -i, to: now) {
                wanted.insert(cal.startOfDay(for: d))
            }
        }

        // "yyyy-MM-dd" docID'lerini parse etmek için
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snap, _ in
                guard let docs = snap?.documents else { return }

                var arr: [(date: Date, text: String)] = []

                for d in docs {
                    let data = d.data()
                    let comment = (data["comment"] as? String)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if comment.isEmpty { continue }

                    // Gün belirleme: önce Timestamp "date" varsa onu kullan, yoksa docID parse et
                    var day: Date?
                    if let ts = data["date"] as? Timestamp {
                        day = cal.startOfDay(for: ts.dateValue())
                    } else if let parsed = df.date(from: d.documentID) {
                        day = cal.startOfDay(for: parsed)
                    }

                    if let day, wanted.contains(day) {
                        arr.append((date: day, text: comment))
                    }
                }

                arr.sort { $0.date < $1.date }
                DispatchQueue.main.async {
                    self.dailyComments = arr
                }
            }
    }



    
}

// ViewModel extension
extension StatsViewModel {
    func generatePDF() -> URL? {
        // Calculate values
        let totalDays = calculateTotalDaysTracked()
        let avgSafe = totalDays > 0 ? Double(safeCount) / Double(totalDays) : 0
        let avgBurned = totalDays > 0 ? Double(burnedCount) / Double(totalDays) : 0
        
        let pdfData = StatsPDFData(
            burnedCount: burnedCount,
            safeCount: safeCount,
            mostBurnedFoods: mostBurnedFoods,
            mostSafeFoods: mostSafeFoods,
            foodSymptomCounts: foodSymptomCounts,
            foodMoodCounts: foodMoodCounts,
            selectedFood: selectedFoodForSymptomStats,
            generatedDate: Date(),
            weeklyTrends: weeklyTrends,
            symptomFrequency: symptomFrequency,
            moodFrequency: moodFrequency,
            totalDaysTracked: totalDays,
            averageSafePerDay: avgSafe,
            averageBurnedPerDay: avgBurned,
            symptomTopFoods: symptomTopFoods
        )
        
        return exportStatsToPDF(statsData: pdfData)
    }
    
    func sharePDF() {
        if let pdfURL = generatePDF() {
            DispatchQueue.main.async {
                let av = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    
                    if let popoverController = av.popoverPresentationController {
                        popoverController.sourceView = rootViewController.view
                        popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                                            y: rootViewController.view.bounds.midY,
                                                            width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                    }
                    
                    rootViewController.present(av, animated: true)
                }
            }
        }
    }
    
    private func calculateTotalDaysTracked() -> Int {
        // Calculate total days from weekly trends or use a default
        return max(weeklyTrends.count, 1)
    }
    
    func fetchSymptomTopFoods() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                var map: [String: [String: Int]] = [:] // symptom -> (food -> count)

                for doc in documents {
                    let data = doc.data()
                    let symptoms = (data["symptoms"] as? [String])?.map { $0.lowercased() } ?? []
                    let burned = (data["burnedFoods"] as? [String])?.map { $0.lowercased() } ?? []
                    let safe   = (data["safeFoods"]   as? [String])?.map { $0.lowercased() } ?? []
                    let foods = burned + safe
                    if symptoms.isEmpty || foods.isEmpty { continue }

                    for s in symptoms {
                        var dict = map[s] ?? [:]
                        for f in foods { dict[f, default: 0] += 1 }
                        map[s] = dict
                    }
                }

                // sıralayıp ilk 5’i al
                let sorted: [String: [(String, Int)]] = map.mapValues {
                    Array($0.sorted { $0.value > $1.value }.prefix(5))
                }

                DispatchQueue.main.async { self.symptomTopFoods = sorted }
            }
    }
    
}

struct StatsView: View {
    
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        ZStack(alignment: .topLeading) {
            ColorPalette.Green5.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    //Burned vs Safe
                    VStack {
                        HStack {
                            Text("Trigger vs Safe Foods")
                                .bold()
                                .font(.system(size: 18))
                            Spacer()
                        }
                        Chart {
                            if viewModel.burnedCount > 0 {
                                SectorMark(
                                    angle: .value("Trigger Food", viewModel.burnedCount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1
                                )
                                .foregroundStyle(Color.red.opacity(0.5))
                            }
                            
                            if viewModel.safeCount > 0 {
                                SectorMark(
                                    angle: .value("Safe", viewModel.safeCount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1
                                )
                                .foregroundStyle(Color.green.opacity(0.5))
                            }
                        }
                        .frame(height: 250)
                        .chartLegend(.visible)
                        .padding()
                        .emptyChartOverlay(viewModel.burnedCount == 0 && viewModel.safeCount == 0)
                        
                        HStack {
                            Text("Safe: \(viewModel.safeCount)")
                                .padding(5)
                                .foregroundColor(ColorPalette.Green1)
                                .background(.green.opacity(0.3))
                                .cornerRadius(12)
                            Spacer()
                            Text("Trigger: \(viewModel.burnedCount)")
                                .padding(5)
                                .foregroundColor(.red)
                                .background(.red.opacity(0.3))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.Green6.opacity(0.2), lineWidth: 1)
                    )
                    
                    VStack {
                        //Most burned foods
                        VStack {
                            HStack {
                                Text("Most triggered foods")
                                    .bold()
                                    .font(.system(size: 18))
                                Spacer()
                            }
                            Chart {
                                ForEach(viewModel.mostBurnedFoods.prefix(8), id: \.0) { (food, count) in
                                    BarMark(
                                        x: .value("Food", food.capitalized),
                                        y: .value("Count", count)
                                    )
                                    .foregroundStyle(Color.red.gradient)
                                }
                            }
                            .emptyChartOverlay(viewModel.mostBurnedFoods.isEmpty)
                        }
                        
                        
                        //Most safe foods
                        VStack {
                            HStack {
                                Text("Most safe foods")
                                    .bold()
                                    .font(.system(size: 18))
                                Spacer()
                            }
                            Chart {
                                ForEach(viewModel.mostSafeFoods.prefix(8), id: \.0) { (food, count) in
                                    BarMark(
                                        x: .value("Food", food.capitalized),
                                        y: .value("Count", count)
                                    )
                                    .foregroundStyle(Color.green.gradient)
                                }
                            }
                            .emptyChartOverlay(viewModel.mostSafeFoods.isEmpty)
                        }
                        
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.Green6.opacity(0.2), lineWidth: 1)
                    )
                    
                    //
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Select a food to see related symptoms")
                            Spacer()
                        }
                        .bold()
                        .font(.system(size: 18))
                        
                        Picker("Food", selection: $viewModel.selectedFoodForSymptomStats) {
                            ForEach(viewModel.allFoods, id: \.self) { food in
                                Text(food.capitalized).tag(food)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(.black)
                        .onChange(of: viewModel.selectedFoodForSymptomStats) { newFood in
                            if !newFood.isEmpty {
                                viewModel.fetchSymptomsLinkedTo(foodName: newFood)
                                viewModel.fetchMoodsLinkedTo(foodName: newFood)
                            }
                        }
                        
                        if !viewModel.foodSymptomCounts.isEmpty {
                            Chart {
                                ForEach(viewModel.foodSymptomCounts, id: \.0) { (symptom, count) in
                                    BarMark(
                                        x: .value("Symptom", symptom),
                                        y: .value("Count", count)
                                    )
                                    .foregroundStyle(.purple.gradient)
                                }
                            }
                            .frame(height: 250)
                        } else {
                            EmptyChart(message: "Not enough data", height: 250)
                        }
                        
                        if !viewModel.foodMoodCounts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mood distribution for selected food")
                                    .font(.headline)
                                
                                Chart {
                                    ForEach(viewModel.foodMoodCounts, id: \.0) { (mood, count) in
                                        BarMark(
                                            x: .value("Mood", mood),
                                            y: .value("Count", count)
                                        )
                                        .foregroundStyle(Color.blue.gradient)
                                    }
                                }
                                .frame(height: 250)
                            }
                        } else {
                            EmptyChart(message: "Not enough data", height: 250)
                        }
                        
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.Green6.opacity(0.2), lineWidth: 1)
                    )
                    
                    VStack {
                        HStack {
                            Text("Weekly Trends")
                                .bold()
                                .font(.system(size: 18))
                            Spacer()
                        }
                        
                        Chart {
                            ForEach(viewModel.weeklyTrends, id: \.date) { day in
                                LineMark(
                                    x: .value("Day", day.date, unit: .day),
                                    y: .value("Trigger Foods", day.burned)
                                )
                                .foregroundStyle(.red)
                                .symbol(Circle())
                                
                                LineMark(
                                    x: .value("Day", day.date, unit: .day),
                                    y: .value("Safe Foods", day.safe)
                                )
                                .foregroundStyle(.green)
                                .symbol(Circle())
                            }
                        }
                        .chartLegend {
                            HStack {
                                Label("Trigger", systemImage: "circle.fill").foregroundColor(.red)
                                Label("Safe", systemImage: "circle.fill").foregroundColor(.green)
                            }
                        }
                        .frame(height: 250)
                        .emptyChartOverlay(viewModel.weeklyTrends.isEmpty)
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.Green6.opacity(0.2), lineWidth: 1)
                    )

                    // Tüm Semptomlar Chart'ı
                    VStack {
                        HStack {
                            Text("All Symptoms Frequency")
                                .bold()
                                .font(.system(size: 18))
                            Spacer()
                        }
                        
                        Chart {
                            ForEach(viewModel.symptomFrequency.prefix(10), id: \.0) { (symptom, count) in
                                BarMark(
                                    x: .value("Symptom", symptom),
                                    y: .value("Count", count)
                                )
                                .foregroundStyle(.purple.gradient)
                            }
                        }
                        .frame(height: 250)
                        .emptyChartOverlay(viewModel.symptomFrequency.isEmpty)
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.Green6.opacity(0.2), lineWidth: 1)
                    )

                    // Tüm Mood'lar Chart'ı
                    VStack {
                        HStack {
                            Text("Mood Distribution")
                                .bold()
                                .font(.system(size: 18))
                            Spacer()
                        }
                        
                        Chart {
                            ForEach(viewModel.moodFrequency, id: \.0) { (mood, count) in
                                SectorMark(
                                    angle: .value("Count", count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1
                                )
                                .foregroundStyle(by: .value("Mood", mood))
                            }
                        }
                        .frame(height: 250)
                        .chartLegend(.visible)
                        .emptyChartOverlay(viewModel.moodFrequency.isEmpty)
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.Green6.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Notes for the week (daily comments)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Notes for these days")
                                .bold()
                                .font(.system(size: 18))
                            Spacer()
                        }

                        if viewModel.dailyComments.isEmpty {
                            Text("No notes for these days.")
                                .font(.callout)
                                .foregroundColor(.black)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(Array(viewModel.dailyComments.enumerated()), id: \.offset) { _, item in
                                VStack(alignment: .leading) {
                                    Text(item.text)
                                        .foregroundColor(.black)
                                        
                                    
                                    HStack {
                                        Spacer()
                                        Text(shortDate(item.date))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(10)
                                .background(ColorPalette.Green5)
                                .cornerRadius(10)
                                .contentShape(Rectangle())
                                    .onTapGesture {
                                        NotificationCenter.default.post(
                                            name: .jumpToDate,
                                            object: nil,
                                            userInfo: ["date": item.date]
                                        )
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(ColorPalette.Green6.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.Green6.opacity(0.2), lineWidth: 1)
                    )

                    
                }
                .padding()
                
                .onAppear {
                    viewModel.fetchStats()
                    viewModel.fetchMostBurnedFoods()
                    viewModel.fetchMostSafeFoods()
                    viewModel.fetchAllBurnedFoods()
                    viewModel.fetchWeeklyTrends()
                    viewModel.fetchAllSymptomsFrequency()
                    viewModel.fetchAllMoodsFrequency()
                    viewModel.fetchSymptomTopFoods()
                }
            }
        }
    }
    
    private func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "EEE, MMM d"
        return df.string(from: date)
    }
    
}

// Boş grafiğe merkezde mesaj bindirmek için
extension View {
    func emptyChartOverlay(_ condition: Bool,
                           message: String = "Not enough data") -> some View {
        self.overlay(alignment: .center) {
            if condition {
                Text(message)
                    .font(.callout)
                    .foregroundColor(.black)
            }
        }
    }
}

// Alternatif: tamamen boş yere "placeholder kart" göstermek istersen
struct EmptyChart: View {
    var message: String = "Not enough data"
    var height: CGFloat = 250
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorPalette.Green5.opacity(0.55))
            Text(message)
                .font(.callout)
                .foregroundColor(.black)
        }
        .frame(height: height)
    }
}

#Preview {
    StatsView()
}
