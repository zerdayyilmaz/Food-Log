
import UIKit
import SwiftUI

func exportStatsToPDF(statsData: StatsPDFData, fileName: String = "FoodLog_Health_Report.pdf") -> URL? {
    // PDF sayfa boyutu (A4)
    let pageSize = CGSize(width: 595, height: 842)
    let pageRect = CGRect(origin: .zero, size: pageSize)
    
    // PDF renderer oluştur
    let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect)
    
    let data = pdfRenderer.pdfData { context in
        // Sayfa numarası takibi
        var currentPage = 0
        
        // 1. SAYFA: Header, Summary, Insights, Footer
        context.beginPage()
        currentPage += 1
        drawPageFooter(context: context, pageRect: pageRect)
        
        let firstPageView = FirstPageView(statsData: statsData)
        let firstHostingController = UIHostingController(rootView: firstPageView)
        firstHostingController.view.frame = pageRect
        firstHostingController.view.drawHierarchy(in: pageRect, afterScreenUpdates: true)
        
        // 2. SAYFA: Detailed Food Analysis
        context.beginPage()
        currentPage += 1
        drawPageFooter(context: context, pageRect: pageRect)
        
        let foodAnalysisView = DetailedFoodAnalysisView(statsData: statsData)
        let foodHostingController = UIHostingController(rootView: foodAnalysisView)
        foodHostingController.view.frame = pageRect.insetBy(dx: 30, dy: 60)
        foodHostingController.view.drawHierarchy(in: pageRect.insetBy(dx: 30, dy: 60), afterScreenUpdates: true)
        
        // 3. SAYFA: Weekly Trends (eğer veri varsa)
        if !statsData.weeklyTrends.isEmpty {
            context.beginPage()
            currentPage += 1
            drawPageFooter(context: context, pageRect: pageRect)
            
            let weeklyTrendsView = WeeklyTrendsView(statsData: statsData)
            let trendsHostingController = UIHostingController(rootView: weeklyTrendsView)
            trendsHostingController.view.frame = pageRect.insetBy(dx: 30, dy: 60)
            trendsHostingController.view.drawHierarchy(in: pageRect.insetBy(dx: 30, dy: 60), afterScreenUpdates: true)
        }
        
        // 4. SAYFA: Symptom Overview
        context.beginPage()
        currentPage += 1
        drawPageFooter(context: context, pageRect: pageRect)
        
        let symptomView = SymptomOverviewView(statsData: statsData)
        let symptomHostingController = UIHostingController(rootView: symptomView)
        symptomHostingController.view.frame = pageRect.insetBy(dx: 30, dy: 60)
        symptomHostingController.view.drawHierarchy(in: pageRect.insetBy(dx: 30, dy: 60), afterScreenUpdates: true)
        
        // 5. SAYFA: Mood Overview
        context.beginPage()
        currentPage += 1
        drawPageFooter(context: context, pageRect: pageRect)
        
        let moodView = MoodOverviewView(statsData: statsData)
        let moodHostingController = UIHostingController(rootView: moodView)
        moodHostingController.view.frame = pageRect.insetBy(dx: 30, dy: 60)
        moodHostingController.view.drawHierarchy(in: pageRect.insetBy(dx: 30, dy: 60), afterScreenUpdates: true)
        
        // 6. SAYFA: Detailed Symptom Analysis (eğer veri varsa)
        if !statsData.symptomFrequency.isEmpty {
            context.beginPage()
            currentPage += 1
            drawPageFooter(context: context, pageRect: pageRect)
            
            let detailedSymptomView = DetailedSymptomAnalysisView(statsData: statsData)
            let detailedSymptomHostingController = UIHostingController(rootView: detailedSymptomView)
            detailedSymptomHostingController.view.frame = pageRect.insetBy(dx: 30, dy: 60)
            detailedSymptomHostingController.view.drawHierarchy(in: pageRect.insetBy(dx: 30, dy: 60), afterScreenUpdates: true)
        }
        
        // 7. SAYFA: Detailed Mood Analysis (eğer veri varsa)
        if !statsData.moodFrequency.isEmpty {
            context.beginPage()
            currentPage += 1
            drawPageFooter(context: context, pageRect: pageRect)
            
            let detailedMoodView = DetailedMoodAnalysisView(statsData: statsData)
            let detailedMoodHostingController = UIHostingController(rootView: detailedMoodView)
            detailedMoodHostingController.view.frame = pageRect.insetBy(dx: 30, dy: 60)
            detailedMoodHostingController.view.drawHierarchy(in: pageRect.insetBy(dx: 30, dy: 60), afterScreenUpdates: true)
        }
    }
    
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    do {
        try data.write(to: url)
        return url
    } catch {
        print("❌ PDF could not be written: \(error)")
        return nil
    }
}

// 1. SAYFA View
struct FirstPageView: View {
    let statsData: StatsPDFData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // Header
            headerSection
            
            // Summary Statistics
            summarySection
            
            // Insights
            insightsSection
            
            // Footer
            footerSection
        }
        .padding(40)
        .background(Color.white)
        .foregroundColor(.black)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("FOODLOG")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    Text("Comprehensive Health Report")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Report Date:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(statsData.generatedDate, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                    Text(statsData.generatedDate, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Summary Statistics")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)
            
            HStack(spacing: 25) {
                StatCard(title: "Total Days Tracked", value: "\(statsData.totalDaysTracked)", color: .blue, icon: "calendar")
                StatCard(title: "Avg. Safe Foods/Day", value: String(format: "%.1f", statsData.averageSafePerDay), color: .green, icon: "checkmark.circle")
                StatCard(title: "Avg. Trigger Foods/Day", value: String(format: "%.1f", statsData.averageBurnedPerDay), color: .red, icon: "exclamationmark.triangle")
            }
            
            HStack(spacing: 25) {
                StatCard(title: "Total Safe Foods", value: "\(statsData.safeCount)", color: .green, icon: "leaf")
                StatCard(title: "Total Trigger Foods", value: "\(statsData.burnedCount)", color: .red, icon: "flame")
                StatCard(title: "Safe/Trigger Ratio", value: ratioText, color: ratioColor, icon: "scale.3d")
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var ratioText: String {
        guard statsData.burnedCount > 0 else { return "∞" }
        let ratio = Double(statsData.safeCount) / Double(statsData.burnedCount)
        return String(format: "%.2f", ratio)
    }
    
    private var ratioColor: Color {
        guard statsData.burnedCount > 0 else { return .green }
        let ratio = Double(statsData.safeCount) / Double(statsData.burnedCount)
        return ratio >= 2 ? .green : ratio >= 1 ? .orange : .red
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Key Insights & Recommendations")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 15) {
                if statsData.burnedCount > statsData.safeCount {
                    HStack(alignment: .top, spacing: 10) {
                        Text("⚠️")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("**Attention Needed**")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                            Text("You're experiencing more trigger foods than safe foods. Consider focusing on your safe food list and gradually reintroducing foods.")
                                .font(.system(size: 12))
                        }
                    }
                } else if statsData.safeCount > 0 {
                    HStack(alignment: .top, spacing: 10) {
                        Text("✅")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("**Positive Progress**")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                            Text("Good balance of safe foods. Continue tracking and consider keeping a food journal for deeper insights.")
                                .font(.system(size: 12))
                        }
                    }
                }
                
                // 🔻 YENİ: Tüm Trigger özet (ilk 5 + “…”)
                    if !statsData.mostBurnedFoods.isEmpty {
                        compactFoodSummary(title: "Trigger foods",
                                           emoji: "🔥",
                                           list: statsData.mostBurnedFoods,
                                           tint: .red,
                                           maxItems: 5)
                    }

                    // 🔻 YENİ: Tüm Safe özet (ilk 5 + “…”)
                    if !statsData.mostSafeFoods.isEmpty {
                        compactFoodSummary(title: "Safe foods",
                                           emoji: "🍃",
                                           list: statsData.mostSafeFoods,
                                           tint: .green,
                                           maxItems: 5)
                    }
                
                if !statsData.symptomFrequency.isEmpty {
                    HStack(spacing: 10) {
                        Text("📊")
                        Text("**Most Common Symptom**: \(statsData.symptomFrequency.first?.0 ?? "N/A")")
                    }
                    .font(.system(size: 12))
                }
            }
            .padding(10)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 15) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Text("FoodLog - Personal Health Tracking Application")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text("This report is generated for personal tracking purposes only. It should not be used for medical diagnosis or treatment.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text("Report ID: \(reportNumber)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                
            Text("Generated by: FoodLog App v\(appVersion)")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
    
    private var reportNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return "FL-\(formatter.string(from: statsData.generatedDate))"
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// 3. SAYFA View: Weekly Trends
struct WeeklyTrendsView: View {
    let statsData: StatsPDFData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Last 7 Days Trends")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            if statsData.weeklyTrends.isEmpty {
                Text("Insufficient data available")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                VStack(spacing: 15) {
                    ForEach(statsData.weeklyTrends, id: \.date) { day in
                        HStack {
                            Text(dayFormatter.string(from: day.date))
                                .font(.system(size: 16))
                                .frame(width: 120, alignment: .leading)
                            
                            HStack(spacing: 10) {
                                Text("🔥 \(day.burned)")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                                Text("🍃 \(day.safe)")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                            
                            Spacer()
                            
                            Text(dayTrendText(burned: day.burned, safe: day.safe))
                                .font(.system(size: 14))
                                .foregroundColor(dayTrendColor(burned: day.burned, safe: day.safe))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(dayTrendColor(burned: day.burned, safe: day.safe).opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
        .padding(30)
        .background(Color.white)
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }
    
    private func dayTrendText(burned: Int, safe: Int) -> String {
        if burned == 0 && safe == 0 { return "No data" }
        if burned == 0 { return "Excellent day" }
        if safe == 0 { return "Challenging day" }
        let ratio = Double(safe) / Double(burned)
        return ratio >= 3 ? "Very good" : ratio >= 2 ? "Good" : ratio >= 1 ? "Moderate" : "Difficult"
    }
    
    private func dayTrendColor(burned: Int, safe: Int) -> Color {
        if burned == 0 && safe == 0 { return .gray }
        if burned == 0 { return .green }
        if safe == 0 { return .red }
        let ratio = Double(safe) / Double(burned)
        return ratio >= 3 ? .green : ratio >= 2 ? .green.opacity(0.7) : ratio >= 1 ? .orange : .red
    }
}

// 4. SAYFA View: Symptom Overview - GÜNCELLENMİŞ
struct SymptomOverviewView: View {
    let statsData: StatsPDFData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Symptom Overview")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            if !statsData.symptomFrequency.isEmpty {
                // All symptoms
                VStack(alignment: .leading, spacing: 15) {
                    Text("Symptom Frequency Distribution")
                        .font(.system(size: 18, weight: .semibold))
                    
                    ForEach(statsData.symptomFrequency, id: \.0) { symptom, count in
                        HStack {
                            Text("⚕️")
                            Text(symptom)
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.purple)
                            Text("(%\(percentage(of: count, total: statsData.symptomFrequency.reduce(0) { $0 + $1.1 })))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(15)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("No symptom data available")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
        .padding(30)
        .background(Color.white)
    }
    
    private func percentage(of value: Int, total: Int) -> String {
        guard total > 0 else { return "0" }
        let percentage = (Double(value) / Double(total)) * 100
        return String(format: "%.1f", percentage)
    }
}

// 5. SAYFA View: Mood Overview - GÜNCELLENMİŞ
struct MoodOverviewView: View {
    let statsData: StatsPDFData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Mood Overview")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            if !statsData.moodFrequency.isEmpty {
                // General mood distribution
                VStack(alignment: .leading, spacing: 15) {
                    Text("Overall Mood Distribution")
                        .font(.system(size: 18, weight: .semibold))
                    
                    ForEach(statsData.moodFrequency, id: \.0) { mood, count in
                        HStack {
                            Text(moodIcon(for: mood))
                            Text(moodDescription(for: mood))
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.orange)
                            Text("(%\(percentage(of: count, total: statsData.moodFrequency.reduce(0) { $0 + $1.1 })))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(15)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Food-related moods (eğer varsa)
                if !statsData.foodMoodCounts.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Moods Associated with '\(statsData.selectedFood.capitalized)'")
                            .font(.system(size: 18, weight: .semibold))
                        
                        ForEach(statsData.foodMoodCounts, id: \.0) { mood, count in
                            HStack {
                                Text(moodIcon(for: mood))
                                Text(moodDescription(for: mood))
                                Spacer()
                                Text("\(count) times")
                                    .foregroundColor(.blue)
                            }
                            .font(.system(size: 14))
                        }
                    }
                    .padding(15)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            } else {
                Text("No mood data available")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
        .padding(30)
        .background(Color.white)
    }
    
    private func percentage(of value: Int, total: Int) -> String {
        guard total > 0 else { return "0" }
        let percentage = (Double(value) / Double(total)) * 100
        return String(format: "%.1f", percentage)
    }
    
    private func moodIcon(for mood: String) -> String {
        switch mood.lowercased() {
        case "sadmood", "sad": return "😢"
        case "normalmood", "normal": return "😐"
        case "happymood", "happy": return "😊"
        default: return "🎭"
        }
    }
    
    private func moodDescription(for mood: String) -> String {
        switch mood.lowercased() {
        case "sadmood": return "Sad"
        case "normalmood": return "Normal"
        case "happymood": return "Happy"
        default: return mood.capitalized
        }
    }
}

// Geri kalan fonksiyonlar ve diğer view'lar aynı kalacak...
// (drawPageFooter, addPageNumbers, DetailedFoodAnalysisView, DetailedSymptomAnalysisView,
// DetailedMoodAnalysisView, StatCard, yardımcı fonksiyonlar vb.)

private func drawPageFooter(context: UIGraphicsPDFRendererContext,
                            pageRect: CGRect) {
    let footerText = "⚕️ For healthcare professionals: This report is intended for clinical evaluation only."
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.italicSystemFont(ofSize: 10),
        .foregroundColor: UIColor.darkGray
    ]
    
    let stringSize = footerText.size(withAttributes: attributes)
    let stringRect = CGRect(
        x: (pageRect.width - stringSize.width) / 2,
        y: pageRect.height - 30,
        width: stringSize.width,
        height: stringSize.height
    )
    footerText.draw(in: stringRect, withAttributes: attributes)
}


private func needsAdditionalPages(for view: UIView, in rect: CGRect) -> Bool {
    let contentHeight = view.systemLayoutSizeFitting(
        CGSize(width: rect.width, height: UIView.layoutFittingCompressedSize.height),
        withHorizontalFittingPriority: .required,
        verticalFittingPriority: .fittingSizeLevel
    ).height
    
    return contentHeight > rect.height * 1.5 // Eşik değeri
}

// Ek sayfaları ekle
private func addAdditionalPages(context: UIGraphicsPDFRendererContext,
                               statsData: StatsPDFData,
                               pageRect: CGRect,
                               currentPage: inout Int) {
    
    // Detaylı istatistikler için ek sayfalar - explicit type annotation
    let detailedSections: [AnyView] = [
        AnyView(DetailedFoodAnalysisView(statsData: statsData)),
        AnyView(DetailedSymptomAnalysisView(statsData: statsData)),
        AnyView(DetailedMoodAnalysisView(statsData: statsData))
    ]
    
    for section in detailedSections {
        // Yeni sayfa başlat
        context.beginPage()
        currentPage += 1
        
        // Extract the title from each view type
        var title = "Detailed Analysis"
        
        if let foodView = section as? AnyView,
           let unwrappedView = Mirror(reflecting: foodView).descendant("storage", "view") as? DetailedFoodAnalysisView {
            title = unwrappedView.title
        } else if let symptomView = section as? AnyView,
                  let unwrappedView = Mirror(reflecting: symptomView).descendant("storage", "view") as? DetailedSymptomAnalysisView {
            title = unwrappedView.title
        } else if let moodView = section as? AnyView,
                  let unwrappedView = Mirror(reflecting: moodView).descendant("storage", "view") as? DetailedMoodAnalysisView {
            title = unwrappedView.title
        }
        
        // Sayfa başlığı
        drawPageHeader(context: context, pageRect: pageRect, title: title, pageNumber: currentPage)
        
        // İçerik görünümü
        let hostingController = UIHostingController(rootView: section)
        hostingController.view.frame = pageRect.insetBy(dx: 30, dy: 60)
        hostingController.view.drawHierarchy(in: pageRect.insetBy(dx: 30, dy: 60), afterScreenUpdates: true)
    }
}

// Sayfa başlığı çiz
private func drawPageHeader(context: UIGraphicsPDFRendererContext,
                           pageRect: CGRect,
                           title: String,
                           pageNumber: Int) {
    
    let headerRect = CGRect(x: 30, y: 30, width: pageRect.width - 60, height: 40)
    
    // Başlık
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 18),
        .foregroundColor: UIColor.black
    ]
    
    title.draw(in: headerRect, withAttributes: titleAttributes)
    
    // Sayfa numarası
    let pageString = "Page \(pageNumber)"
    let pageAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12),
        .foregroundColor: UIColor.gray
    ]
    
    let pageSize = pageString.size(withAttributes: pageAttributes)
    let pageRect = CGRect(x: pageRect.width - pageSize.width - 30,
                         y: 30,
                         width: pageSize.width,
                         height: pageSize.height)
    
    pageString.draw(in: pageRect, withAttributes: pageAttributes)
    
    // Çizgi
    let lineY = headerRect.maxY + 10
    context.cgContext.setStrokeColor(UIColor.gray.cgColor)
    context.cgContext.setLineWidth(0.5)
    context.cgContext.move(to: CGPoint(x: 30, y: lineY))
    context.cgContext.addLine(to: CGPoint(x: pageRect.width - 30, y: lineY))
    context.cgContext.strokePath()
}

// Sayfa numaralarını ekle
private func addPageNumbers(context: UIGraphicsPDFRendererContext,
                           pageRect: CGRect,
                           totalPages: Int) {
    
    let pageSize = pageRect.size
    
    for pageNumber in 1...totalPages {
        // Her sayfaya sayfa numarası ekle
        context.beginPage()
        
        let pageString = "Page \(pageNumber) of \(totalPages)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        
        let stringSize = pageString.size(withAttributes: attributes)
        let stringRect = CGRect(x: (pageSize.width - stringSize.width) / 2,
                               y: pageSize.height - 40,
                               width: stringSize.width,
                               height: stringSize.height)
        
        pageString.draw(in: stringRect, withAttributes: attributes)
    }
}

// Detailed PDF data model
struct StatsPDFData {
    let burnedCount: Int
    let safeCount: Int
    let mostBurnedFoods: [(String, Int)]
    let mostSafeFoods: [(String, Int)]
    let foodSymptomCounts: [(String, Int)]
    let foodMoodCounts: [(String, Int)]
    let selectedFood: String
    let generatedDate: Date
    let weeklyTrends: [(date: Date, burned: Int, safe: Int)]
    let symptomFrequency: [(String, Int)]
    let moodFrequency: [(String, Int)]
    let totalDaysTracked: Int
    let averageSafePerDay: Double
    let averageBurnedPerDay: Double
    let symptomTopFoods: [String: [(String, Int)]]
}

// Detaylı Yemek Analizi Sayfası
struct DetailedFoodAnalysisView: View {
    let statsData: StatsPDFData
    let title = "Detailed Food Analysis"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            // Most triggered foods
            if !statsData.mostBurnedFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Common Trigger Foods")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                    
                    ForEach(statsData.mostBurnedFoods.prefix(10), id: \.0) { food, count in
                        HStack {
                            Text("🔥")
                            Text(food.capitalized)
                                .foregroundColor(.black)
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.red)
                            Text("(%\(percentage(of: count, total: statsData.burnedCount)))")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .font(.system(size: 12))
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Safest foods
            if !statsData.mostSafeFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Safest Foods")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                    
                    ForEach(statsData.mostSafeFoods.prefix(10), id: \.0) { food, count in
                        HStack {
                            Text("🍃")
                            Text(food.capitalized)
                                .foregroundColor(.black)
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.green)
                            Text("(%\(percentage(of: count, total: statsData.safeCount)))")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .font(.system(size: 12))
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(30)
        .background(Color.white)
    }
}

// Detaylı Semptom Analizi Sayfası
struct DetailedSymptomAnalysisView: View {
    let statsData: StatsPDFData
    let title = "Detailed Symptom Analysis"

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)
                .padding(.bottom, 10)

            // Food-related symptoms
            if !statsData.foodSymptomCounts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Symptoms Associated with '\(statsData.selectedFood.capitalized)'")
                        .font(.system(size: 16, weight: .semibold))
                    
                    ForEach(statsData.foodSymptomCounts, id: \.0) { symptom, count in
                        HStack {
                            Text("🔗")
                            Text(symptom)
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.blue)
                        }
                        .font(.system(size: 12))
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(30)
        .background(Color.white)
    }

    // Yiyecek etiket rengi: trigger -> kırmızı, safe -> yeşil, bilinmiyorsa gri
    private func foodTagColor(_ food: String) -> Color {
        let name = food.lowercased()
        let burnedSet = Set(statsData.mostBurnedFoods.map { $0.0.lowercased() })
        let safeSet   = Set(statsData.mostSafeFoods.map   { $0.0.lowercased() })
        if burnedSet.contains(name) { return .red }
        if safeSet.contains(name)   { return .green }
        return .gray
    }
}


// Detaylı Mood Analizi Sayfası
struct DetailedMoodAnalysisView: View {
    let statsData: StatsPDFData
    let title = "Detailed Mood Analysis"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            // General mood distribution
            if !statsData.moodFrequency.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overall Mood Distribution")
                        .font(.system(size: 16, weight: .semibold))
                    
                    ForEach(statsData.moodFrequency, id: \.0) { mood, count in
                        HStack {
                            Text(moodIcon(for: mood))
                            Text(moodDescription(for: mood))
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.orange)
                            Text("(%\(percentage(of: count, total: statsData.moodFrequency.reduce(0) { $0 + $1.1 })))")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .font(.system(size: 12))
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Food-related moods
            if !statsData.foodMoodCounts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Moods Associated with '\(statsData.selectedFood.capitalized)'")
                        .font(.system(size: 16, weight: .semibold))
                    
                    ForEach(statsData.foodMoodCounts, id: \.0) { mood, count in
                        HStack {
                            Text(moodIcon(for: mood))
                            Text(moodDescription(for: mood))
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.blue)
                        }
                        .font(.system(size: 12))
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(30)
        .background(Color.white)
    }
}

// Detailed PDF view in English - SINGLE PAGE VERSION
struct DetailedStatsPDFView: View {
    let statsData: StatsPDFData
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // Header
            headerSection
            
            // Summary Statistics
            summarySection
            
            // Weekly Trends
            weeklyTrendsSection
            
            // Symptoms Overview
            symptomsOverviewSection
            
            // Mood Overview
            moodOverviewSection
            
            // Insights
            insightsSection
            
            Spacer()
            
            // Footer
            footerSection
        }
        .padding(40)
        .background(Color.white)
        .foregroundColor(.black)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("FOODLOG")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    Text("Comprehensive Health Report")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Report Date:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(statsData.generatedDate, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                    Text(statsData.generatedDate, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Summary Statistics")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.green)
            
            HStack(spacing: 25) {
                StatCard(title: "Total Days Tracked", value: "\(statsData.totalDaysTracked)", color: .blue, icon: "calendar")
                StatCard(title: "Avg. Safe Foods/Day", value: String(format: "%.1f", statsData.averageSafePerDay), color: .green, icon: "checkmark.circle")
                StatCard(title: "Avg. Trigger Foods/Day", value: String(format: "%.1f", statsData.averageBurnedPerDay), color: .red, icon: "exclamationmark.triangle")
            }
            
            HStack(spacing: 25) {
                StatCard(title: "Total Safe Foods", value: "\(statsData.safeCount)", color: .green, icon: "leaf")
                StatCard(title: "Total Trigger Foods", value: "\(statsData.burnedCount)", color: .red, icon: "flame")
                StatCard(title: "Safe/Trigger Ratio", value: ratioText, color: ratioColor, icon: "scale.3d")
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var ratioText: String {
        guard statsData.burnedCount > 0 else { return "∞" }
        let ratio = Double(statsData.safeCount) / Double(statsData.burnedCount)
        return String(format: "%.2f", ratio)
    }
    
    private var ratioColor: Color {
        guard statsData.burnedCount > 0 else { return .green }
        let ratio = Double(statsData.safeCount) / Double(statsData.burnedCount)
        return ratio >= 2 ? .green : ratio >= 1 ? .orange : .red
    }
    
    // MARK: - Weekly Trends Section
    private var weeklyTrendsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Last 7 Days Trends")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.green)
            
            if statsData.weeklyTrends.isEmpty {
                Text("Insufficient data available")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                VStack(spacing: 15) {
                    ForEach(statsData.weeklyTrends, id: \.date) { day in
                        HStack {
                            Text(dayFormatter.string(from: day.date))
                                .font(.system(size: 16))
                                .frame(width: 120, alignment: .leading)
                            
                            HStack(spacing: 10) {
                                Text("🔥 \(day.burned)")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                                Text("🍃 \(day.safe)")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                            
                            Spacer()
                            
                            Text(dayTrendText(burned: day.burned, safe: day.safe))
                                .font(.system(size: 14))
                                .foregroundColor(dayTrendColor(burned: day.burned, safe: day.safe))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(dayTrendColor(burned: day.burned, safe: day.safe).opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }
    
    private func dayTrendText(burned: Int, safe: Int) -> String {
        if burned == 0 && safe == 0 { return "No data" }
        if burned == 0 { return "Excellent day" }
        if safe == 0 { return "Challenging day" }
        let ratio = Double(safe) / Double(burned)
        return ratio >= 3 ? "Very good" : ratio >= 2 ? "Good" : ratio >= 1 ? "Moderate" : "Difficult"
    }
    
    private func dayTrendColor(burned: Int, safe: Int) -> Color {
        if burned == 0 && safe == 0 { return .gray }
        if burned == 0 { return .green }
        if safe == 0 { return .red }
        let ratio = Double(safe) / Double(burned)
        return ratio >= 3 ? .green : ratio >= 2 ? .green.opacity(0.7) : ratio >= 1 ? .orange : .red
    }
   
    /*
    // MARK: - Foods Overview Section (Tüm içerik burada)
    private var foodsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Food Analysis")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.green)
            
            // Most triggered foods
            if !statsData.mostBurnedFoods.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Most Common Trigger Foods")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                    
                    ForEach(statsData.mostBurnedFoods.prefix(10), id: \.0) { food, count in
                        HStack {
                            Text("🔥")
                            Text(food.capitalized)
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.red)
                            Text("(%\(percentage(of: count, total: statsData.burnedCount)))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(15)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Safest foods
            if !statsData.mostSafeFoods.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Safest Foods")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                    
                    ForEach(statsData.mostSafeFoods.prefix(10), id: \.0) { food, count in
                        HStack {
                            Text("🍃")
                            Text(food.capitalized)
                            Spacer()
                            Text("\(count) times")
                                .foregroundColor(.green)
                            Text("(%\(percentage(of: count, total: statsData.safeCount)))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(15)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    */
    // MARK: - Symptoms Overview Section
    private var symptomsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Symptom Overview")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.green)
            
            if !statsData.symptomFrequency.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Most Frequent Symptoms")
                        .font(.system(size: 18, weight: .semibold))
                    
                    ForEach(statsData.symptomFrequency.prefix(5), id: \.0) { symptom, count in
                        HStack {
                            Text("⚕️")
                            Text(symptom)
                            Spacer()
                            Text("\(count)×")
                                .foregroundColor(.purple)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(15)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
            
            Text("Complete symptom analysis on page 2 →")
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .italic()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Mood Overview Section
    private var moodOverviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Mood Overview")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.green)
            
            if !statsData.moodFrequency.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Mood Distribution")
                        .font(.system(size: 18, weight: .semibold))
                    
                    ForEach(statsData.moodFrequency, id: \.0) { mood, count in
                        HStack {
                            Text(moodIcon(for: mood))
                            Text(moodDescription(for: mood))
                            Spacer()
                            Text("\(count)×")
                                .foregroundColor(.orange)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(15)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            Text("Detailed mood analysis on page 3 →")
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .italic()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Key Insights & Recommendations")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 15) {
                if statsData.burnedCount > statsData.safeCount {
                    HStack(alignment: .top, spacing: 10) {
                        Text("⚠️")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("**Attention Needed**")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            Text("You're experiencing more trigger foods than safe foods. Consider focusing on your safe food list and gradually reintroducing foods.")
                                .font(.system(size: 14))
                        }
                    }
                } else if statsData.safeCount > 0 {
                    HStack(alignment: .top, spacing: 10) {
                        Text("✅")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("**Positive Progress**")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                            Text("Good balance of safe foods. Continue tracking and consider keeping a food journal for deeper insights.")
                                .font(.system(size: 14))
                        }
                    }
                }
                
                
                    if !statsData.mostBurnedFoods.isEmpty {
                        compactFoodSummary(title: "Trigger foods",
                                           emoji: "🔥",
                                           list: statsData.mostBurnedFoods,
                                           tint: .red,
                                           maxItems: 5)
                    }

                    
                    if !statsData.mostSafeFoods.isEmpty {
                        compactFoodSummary(title: "Safe foods",
                                           emoji: "🍃",
                                           list: statsData.mostSafeFoods,
                                           tint: .green,
                                           maxItems: 5)
                    }
                
                if !statsData.symptomFrequency.isEmpty {
                    HStack(spacing: 10) {
                        Text("📊")
                        Text("**Most Common Symptom**: \(statsData.symptomFrequency.first?.0 ?? "N/A")")
                    }
                    .font(.system(size: 14))
                }
            }
            .padding(20)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 15) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Text("FoodLog - Personal Health Tracking Application")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text("This report is generated for personal tracking purposes only. It should not be used for medical diagnosis or treatment.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text("Report ID: \(reportNumber)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                
            Text("Generated by: FoodLog App v\(appVersion)")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
    
    private var reportNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return "FL-\(formatter.string(from: statsData.generatedDate))"
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // MARK: - Helper Functions
    private func percentage(of value: Int, total: Int) -> String {
        guard total > 0 else { return "0" }
        let percentage = (Double(value) / Double(total)) * 100
        return String(format: "%.1f", percentage)
    }
    
    private func moodIcon(for mood: String) -> String {
        switch mood.lowercased() {
        case "sadmood", "sad": return "😢"
        case "normalmood", "normal": return "😐"
        case "happymood", "happy": return "😊"
        default: return "🎭"
        }
    }
    
    private func moodDescription(for mood: String) -> String {
        switch mood.lowercased() {
        case "sadmood": return "Sad"
        case "normalmood": return "Normal"
        case "happymood": return "Happy"
        default: return mood.capitalized
        }
    }
}

// Stat card component
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(15)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}



// Yardımcı fonksiyonlar
private func percentage(of value: Int, total: Int) -> String {
    guard total > 0 else { return "0" }
    let percentage = (Double(value) / Double(total)) * 100
    return String(format: "%.1f", percentage)
}

private func moodIcon(for mood: String) -> String {
    switch mood.lowercased() {
    case "sadmood", "sad": return "😢"
    case "normalmood", "normal": return "😐"
    case "happymood", "happy": return "😊"
    default: return "🎭"
    }
}

private func moodDescription(for mood: String) -> String {
    switch mood.lowercased() {
    case "sadmood": return "Sad"
    case "normalmood": return "Normal"
    case "happymood": return "Happy"
    default: return mood.capitalized
    }
}

@ViewBuilder
private func compactFoodSummary(title: String,
                                emoji: String,
                                list: [(String, Int)],
                                tint: Color,
                                maxItems: Int = 5) -> some View {
    let top = Array(list.prefix(maxItems))
    // “Elma (4) · Ekmek (3) · …” gibi
    let joined = top.map { "\($0.0.capitalized) (\($0.1))" }.joined(separator: " · ")
    let tail = list.count > maxItems ? " · …" : ""

    HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(emoji)
        VStack(alignment: .leading, spacing: 2) {
            Text("**\(title):**").font(.system(size: 12))
            Text(joined + tail)
                .font(.system(size: 12))
                .foregroundColor(tint)
                .lineLimit(2)                  // taşmayı engelle
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.9)
        }
    }
}
