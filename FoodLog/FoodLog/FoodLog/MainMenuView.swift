//
//  MainMenuView.swift
//  WordNest-Build Your Own Flashcards!
//
//  Created by Zerda Yilmaz on 21.10.2024.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

enum TabType {
    case main
    case society
    case stats
    case profile
}

enum TopTabSection: String {
    case main,society
}

enum TabSection: String {
    case main, court, players, profile
}

struct MainMenuView: View {
    @AppStorage("selectedDateString") private var selectedDateString: String = ""
    
    @State private var selectedDate: Date? = nil
    @State private var isHeaderExpanded = false
    @State private var isCalendarCollapsed = false
    
    @State private var selectedBottomTab: TabSection = .main
    @State private var selectedTopTab: TopTabSection = .main
    
    @StateObject private var statsVM = StatsViewModel()
    @EnvironmentObject var viewModel: AuthViewModel
    
    @State private var isAddSymptomPopupVisible = false
    
    @State private var showWeeklyReport = false
    
    @State private var showPaywall = false
    @State private var isPremiumToggle = false
    
    @State private var isKeyboardVisible = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ColorPalette.Green5
                .edgesIgnoringSafeArea(.top)
            ColorPalette.Green5
                .edgesIgnoringSafeArea(.bottom)
            VStack {
                VStack {
                    
                    ZStack {
                        ScrollView {
                            VStack {
                                Group {
                                    switch selectedBottomTab {
                                    case .main:
                                        CalendarView(selectedDate: $selectedDate,isCalendarCollapsed: $isCalendarCollapsed)
                                            .shadow(radius: 10, x: 5, y: 0)
                                            .padding(.top,-110)
                                        
                                        SelectedDayView(selectedDate: $selectedDate,showingAddSymptom: $isAddSymptomPopupVisible)
                                            .environmentObject(viewModel)
                                            .shadow(radius: 5)
                                            .padding(.top, isCalendarCollapsed ? 160 : 20)
                                    case .court:
                                        SocietyView()
                                            .padding(.top,70)
                                    case .players:
                                        StatsView().environmentObject(statsVM)
                                            .padding(.top,70)
                                    case .profile:
                                            ProfileView()
                                                .padding(.top,70)
                                        
                                    }
                                }
                                
                                
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .scrollDisabled(isAddSymptomPopupVisible)
                    }
                    .zIndex(0)
                }
            }
            .padding(.top,3)
            .onAppear {
                if let date = ISO8601DateFormatter().date(from: selectedDateString) {
                    selectedDate = date
                } else {
                    let today = Date()
                    selectedDate = today
                    selectedDateString = ISO8601DateFormatter().string(from: today)
                }
            }
            
            .onChange(of: selectedDate) { newValue in
                if let date = newValue {
                    selectedDateString = ISO8601DateFormatter().string(from: date)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .jumpToDate)) { note in
                if let date = note.userInfo?["date"] as? Date {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedDate = date                // gün değişsin
                        selectedBottomTab = .main          // Home tab’a geç
                        isCalendarCollapsed = false        // takvim açık olsun (isteğe bağlı)
                    }
                    selectedDateString = ISO8601DateFormatter().string(from: date) // AppStorage senkron
                }
            }

            //header
            MainMenuHeaderView(
                isExpanded: $isHeaderExpanded,
                selectedTopTab: $selectedTopTab,
                selectedBottomTab: $selectedBottomTab
            ).environmentObject(statsVM)
            .zIndex(10)
        }
        .safeAreaInset(edge: .bottom) {
                TabBarView(selectedBottomTab: $selectedBottomTab)
                    .padding(.vertical,1)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                    .background(ColorPalette.Green5)
                    .allowsHitTesting(!isAddSymptomPopupVisible)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .showWeeklyReport)) { _ in
                    showWeeklyReport = true
                }
        .sheet(isPresented: $showWeeklyReport) {
                    WeeklyHealthReportView()
                        .environmentObject(statsVM)
                }
        .onAppear {
            Task { await statsVM.buildWeeklyReport() }
        }
    }

}

struct MainMenuHeaderView: View {
    @Binding var isExpanded: Bool
    @Binding var selectedTopTab: TopTabSection
    @Binding var selectedBottomTab: TabSection
    
    @State private var fileTabExpanded = false
    @State private var headerHeight: CGFloat = 75
    @State private var dragOffset: CGFloat = 0

    private let collapsedHeight: CGFloat = 75
    private let expandTrigger: CGFloat = 56
    private let maxExpandedHeight: CGFloat = .infinity // Expanded mod için maksimum yükseklik

    @State private var showPaywall = false
    
    @State private var showPaywall2 = false
    
    @State private var isPremiumToggle = false
    
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var statsViewModel: AuthViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // COLLAPSED MOD
            VStack(spacing: 0) {
                topBar(closeButton: false)
            }
            .frame(height: collapsedHeight)
            .background(ColorPalette.Green5)
            .cornerRadius(0, corners: [.bottomLeft, .bottomRight])
            .offset(y: -10)
            .zIndex(1)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Sadece aşağı doğru sürükleme
                        if value.translation.height > 0 {
                            let candidate = collapsedHeight + value.translation.height
                            headerHeight = min(candidate, maxExpandedHeight)
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if headerHeight >= collapsedHeight + expandTrigger {
                                isExpanded = true
                                headerHeight = maxExpandedHeight
                            } else {
                                headerHeight = collapsedHeight
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: headerHeight)
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPremiumToggle: $isPremiumToggle)
                .environmentObject(authViewModel) // Paywall’ın ihtiyaç duyduğu AuthViewModel
        }
        .sheet(isPresented: $showPaywall2) {
            Paywall2View(isPremiumToggle: $isPremiumToggle)
                .environmentObject(authViewModel) // Paywall’ın ihtiyaç duyduğu AuthViewModel
        }
        .onChange(of: isPremiumToggle) { becamePremium in
            if becamePremium {
                Task { await authViewModel.fetchUser() }
            }
        }
    }

    // MARK: - Subviews
    
    private var file: some View {
        let baseHeight: CGFloat = 30
        let expandedHeight: CGFloat = 33
        let currentHeight = fileTabExpanded ? expandedHeight : baseHeight
        let extraShift = fileTabExpanded ? (expandedHeight - baseHeight)/2 : 0
        
        return
        ZStack {
            Rectangle()
                
                .fill(ColorPalette.Green7)
                .frame(maxWidth: .infinity)
                .frame(height: currentHeight)
                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                .offset(y: 60)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        fileTabExpanded.toggle()
                        // Kulakçığa tıklandığında da expanded moda geçebilir
                        if fileTabExpanded {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isExpanded = true
                                headerHeight = maxExpandedHeight
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                let candidate = collapsedHeight + value.translation.height
                                headerHeight = min(candidate, maxExpandedHeight)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                if headerHeight >= collapsedHeight + expandTrigger {
                                    isExpanded = true
                                    headerHeight = maxExpandedHeight
                                } else {
                                    headerHeight = collapsedHeight
                                }
                            }
                        }
                )
            
            ZStack {
            Rectangle()
                    .fill(ColorPalette.Green7)
                
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .padding()
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
            .zIndex(-999)
            .frame(width: 120, height: currentHeight)
            .cornerRadius(6, corners: [.bottomLeft, .bottomRight])
            .offset(x: 100, y: 90)
            
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    fileTabExpanded.toggle()
                    // Kulakçığa tıklandığında da expanded moda geçebilir
                    if fileTabExpanded {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isExpanded = true
                            headerHeight = maxExpandedHeight
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            let candidate = collapsedHeight + value.translation.height
                            headerHeight = min(candidate, maxExpandedHeight)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if headerHeight >= collapsedHeight + expandTrigger {
                                isExpanded = true
                                headerHeight = maxExpandedHeight
                            } else {
                                headerHeight = collapsedHeight
                            }
                        }
                    }
            )
            
    }
        .padding(.horizontal)
        .shadow(radius: 3)
    }

    private func topBar(closeButton: Bool) -> some View {
        HStack {
            Button {selectedTopTab = .main } label: {
                Text("FoodLog").bold()
                    .foregroundColor(.black)
            }

            Spacer()

            if selectedBottomTab == .court {
                Button(action: {
                    // Society sekmesine geç
                    selectedBottomTab = .court
                    // SocietyView’a "yeni post sheet" sinyali gönder
                    NotificationCenter.default.post(name: .showNewPostSheet, object: nil)
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundColor(ColorPalette.Green6)
                }
            }
            
            if selectedBottomTab == .players {
                Button {
                 //   if (authViewModel.currentUser?.isPremium ?? false) {
                        statsVM.fetchStats()
                        statsVM.fetchMostBurnedFoods()
                        statsVM.fetchMostSafeFoods()
                        statsVM.fetchAllBurnedFoods()
                        statsVM.fetchWeeklyTrends()              // EKLENDİ
                        statsVM.fetchAllSymptomsFrequency()      // EKLENDİ
                        statsVM.fetchAllMoodsFrequency()         // EKLENDİ
                        
                        if !statsVM.selectedFoodForSymptomStats.isEmpty {
                            statsVM.fetchSymptomsLinkedTo(foodName: statsVM.selectedFoodForSymptomStats)
                            statsVM.fetchMoodsLinkedTo(foodName: statsVM.selectedFoodForSymptomStats)
                        }
                        
                        // Basit çözüm: kısa gecikme sonrası paylaş (daha sağlamı aşağıda)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            statsVM.sharePDF()
                        }
               //     } else {
                      //  showPaywall2 = true
                 //   }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(ColorPalette.Green6)
                }
            }

            //Health report
            if selectedBottomTab == .main {
                Button {
                //    if (authViewModel.currentUser?.isPremium ?? false) {
                                NotificationCenter.default.post(name: .showWeeklyReport, object: nil)
                     /*       } else {
                                showPaywall = true
                            } */
                } label: {
                    //if weekly report is not ready questionmark.text.page.fill
                    Image(systemName: statsVM.weeklyReport == nil
                                  ? "questionmark.text.page.fill"
                                  : "ecg.text.page.fill")
                                .font(.system(size: 30))
                                .foregroundColor(ColorPalette.Green6)
                }
            }
            
            if closeButton {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isExpanded = false
                        headerHeight = collapsedHeight
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .padding(.leading, 6)
                }
            }
        }
        .foregroundColor(.black)
        .padding(.horizontal)
        .font(.system(size: 30))
        .padding(.vertical, 12)
    }
}

extension Notification.Name {
    static let showNewPostSheet = Notification.Name("showNewPostSheet")
}

extension Notification.Name {
    static let statsFilterDateChanged = Notification.Name("statsFilterDateChanged")
}

extension Notification.Name {
    static let jumpToDate = Notification.Name("jumpToDate")
}

extension Notification.Name {
    static let showWeeklyReport = Notification.Name("showWeeklyReport")
}

// Expanded Header İçin Ayrı View (Dosya benzeri görünüm)
struct ExpandedHeaderContentView: View {
    @Binding var isExpanded: Bool
    var onClose: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    @State private var fileTabExpanded = false
    @State private var headerHeight: CGFloat = 75

    @State private var activities: [Activity] = []
    @State private var listener: ListenerRegistration?
    
    private let collapsedHeight: CGFloat = 75
    private let expandTrigger: CGFloat = 56
    private let maxExpandedHeight: CGFloat = .infinity // Expanded mod için maksimum yükseklik
    
    var body: some View {
        ZStack {
        VStack(spacing: 0) {
            // Top bar - Handle for dragging
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                Spacer()
            }
            .padding(.bottom, 8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // For upward dragging
                        if value.translation.height < 0 {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        // Close if dragged up enough
                        if value.translation.height < -100 {
                            onClose()
                        }
                        // Reset drag
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = .zero
                        }
                    }
            )
            
            // Header title
            HStack {
                Text("Quick Access")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Quick access buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                QuickAccessButton(icon: "clock.fill", title: "History", color: .orange, action: {})
                QuickAccessButton(icon: "questionmark.circle.fill", title: "Help", color: .red, action: {})
                QuickAccessButton(icon: "questionmark.circle.fill", title: "Feedback", color: .red, action: {})
              /*  QuickAccessButton(icon: "bell.fill", title: "Notifications", color: .pink, action: {}) */
            }
            .padding(.horizontal)
            
            // Recent activities section
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activities")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                ScrollView {
                                        VStack(spacing: 10) {
                                            if activities.isEmpty {
                                                Text("No activity yet.")
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .padding(.horizontal)
                                            } else {
                                                ForEach(activities) { act in
                                                    ActivityRow(icon: act.icon,
                                                                       title: act.title,
                                                                       timeText: act.createdAt?.timeAgoString() ?? "")
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .frame(maxHeight: 460)
            }
            .padding(.top, 20)
           
            Spacer()
            // Bottom info
            if let firstDate = activities.first?.createdAt {
                HStack(spacing: 1) {
                Text("Last updated")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    
                
                    Text(" \(firstDate.timeAgoString())")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            .padding(.bottom, 8)
            }
        }
        .padding(.vertical, 16)
        .background(ColorPalette.Green7)
        .cornerRadius(16)
        .shadow(radius: 3)
        .zIndex(1)
        .offset(y: dragOffset.height) // Apply drag offset
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Detect only upward dragging (negative values)
                    if value.translation.height < 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    // Close if dragged up enough
                    if value.translation.height < -100 {
                        onClose()
                    }
                    // Reset drag (with animation)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
        )
    }
        .onAppear { attachActivitiesListener() }
                .onDisappear { listener?.remove(); listener = nil }
    }
    
    private func attachActivitiesListener() {
            guard listener == nil, let uid = Auth.auth().currentUser?.uid else { return }
            let query = Firestore.firestore()
                .collection("users").document(uid)
                .collection("activities")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)

            listener = query.addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                let items = docs.map { Activity(id: $0.documentID, data: $0.data()) }
                self.activities = items
            }
        }
    
    private var fileEar: some View {
        let baseHeight: CGFloat = 30
        let expandedHeight: CGFloat = 33
        let currentHeight = fileTabExpanded ? expandedHeight : baseHeight
        let extraShift = fileTabExpanded ? (expandedHeight - baseHeight)/2 : 0

        return Rectangle()
            .fill(ColorPalette.Green1)
            .frame(width: 60, height: currentHeight)
            .cornerRadius(6, corners: [.bottomLeft, .bottomRight])
            .offset(x: 120, y: 95)
            .shadow(radius: 3, y: 2)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    fileTabExpanded.toggle()
                    // Kulakçığa tıklandığında da expanded moda geçebilir
                    if fileTabExpanded {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isExpanded = true
                            headerHeight = maxExpandedHeight
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            let candidate = collapsedHeight + value.translation.height
                            headerHeight = min(candidate, maxExpandedHeight)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if headerHeight >= collapsedHeight + expandTrigger {
                                isExpanded = true
                                headerHeight = maxExpandedHeight
                            } else {
                                headerHeight = collapsedHeight
                            }
                        }
                    }
            )
    }
}

// Activity Row for Recent Activities
struct ActivityRow: View {
    let icon: String
    let title: String
    let timeText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(timeText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}


// Yardımcı View'lar
struct QuickAccessButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Rectangle()
                        .fill(color)
                        .frame(width: 50, height: 50)
                        .cornerRadius(16)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}


struct CalendarView: View {
    @Binding var selectedDate: Date?
    @Binding var isCalendarCollapsed: Bool
    
    @State private var currentMonthOffset = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    @State private var fileTabExpanded = false
    @State private var headerHeight: CGFloat = 75

    private let collapsedHeight: CGFloat = 75
    private let expandTrigger: CGFloat = 56
    private let maxExpandedHeight: CGFloat = .infinity // Expanded mod için maksimum yükseklik
    
    var body: some View {
        ZStack {
            if !isCalendarCollapsed {
                ZStack {
                VStack {
                    Spacer()
                    headerView
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                        ForEach(weekdays, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        ForEach(datesInMonth(), id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                            }) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .fontWeight(.medium)
                                    .foregroundColor(textColor(for: date))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(
                                        Calendar.current.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast)
                                        ? ColorPalette.Green3
                                        : Color.clear
                                    )
                                    .cornerRadius(20)
                                    .overlay(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 8,height: 8)
                                            .padding(.top, 32)
                                            .opacity(Calendar.current.isDateInToday(date) ? 1 : 0)
                                    )
                            }
                            .disabled(!Calendar.current.isDate(date, equalTo: dateInCurrentMonth(), toGranularity: .month))
                            .opacity(Calendar.current.isDate(date, equalTo: dateInCurrentMonth(), toGranularity: .month) ? 1 : 0.3)
                        }
                        
                    }
                    .padding(.horizontal)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    withAnimation { currentMonthOffset += 1 }
                                } else if value.translation.width > 50 {
                                    withAnimation { currentMonthOffset -= 1 }
                                }
                            }
                    )
                }
                .padding(.bottom,30)
                .frame(height: 550)
                .background(ColorPalette.Green6) // açık yeşil
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
                .zIndex(1)
                    
                    fileEar
                        .zIndex(0)
            }
        } else {
            let baseY: CGFloat = 160
            let baseHeight: CGFloat = 70
            let expandedHeight: CGFloat = 73
            let currentHeight = fileTabExpanded ? expandedHeight : baseHeight
            let extraShift = fileTabExpanded ? (expandedHeight - baseHeight)/2 : 0

            ZStack {
                // Arka dikdörtgen
                Rectangle()
                    .fill(ColorPalette.Green6)
                    .frame(maxWidth: .infinity)
                    .frame(height: currentHeight)
                    .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                    .offset(y: baseY)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    let candidate = collapsedHeight + value.translation.height
                                    headerHeight = min(candidate, maxExpandedHeight)
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    if headerHeight >= collapsedHeight + expandTrigger {
                                        isCalendarCollapsed = false   // << genişlet
                                        headerHeight = maxExpandedHeight
                                    } else {
                                        headerHeight = collapsedHeight
                                    }
                                }
                            }
                    )
                
                ZStack(alignment: .bottom) {
                    Rectangle().fill(ColorPalette.Green6)
                    HStack {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }
                    .padding(.bottom,5)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                }
                .frame(width: 120, height: currentHeight)
                .cornerRadius(6, corners: [.bottomLeft, .bottomRight])
                // Dikdörtgenin tepesine hizala
                .offset(x: -100, y: 190)
                .shadow(radius: 3, y: 2)
                .zIndex(-999) // << -999 yerine pozitif zIndex

                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isCalendarCollapsed = false    // << genişlet
                        headerHeight = maxExpandedHeight
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                let candidate = collapsedHeight + value.translation.height
                                headerHeight = min(candidate, maxExpandedHeight)
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                if headerHeight >= collapsedHeight + expandTrigger {
                                    isCalendarCollapsed = false    // << genişlet
                                    headerHeight = maxExpandedHeight
                                } else {
                                    headerHeight = collapsedHeight
                                }
                            }
                        }
                )
            }
            .padding(.horizontal)
            .shadow(radius: 3)

        }
            
    }
    }
    
    // MARK: - Header with month/year and navigation
    private var headerView: some View {
        HStack {
            Button(action: { currentMonthOffset -= 1 }) {
                Image(systemName: "chevron.left.circle")
                    .font(.system(size: 25))
            }
            
            Spacer()
            
            Text(monthYearString(for: dateInCurrentMonth()))
                .font(.headline)
            
            Spacer()
            
            Button(action: { currentMonthOffset += 1 }) {
                Image(systemName: "chevron.right.circle")
                    .font(.system(size: 25))
            }
        }
        .padding(.horizontal)
        .foregroundColor(.white)
    }
    
    private var weekdays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.shortWeekdaySymbols
    }
    
    private func dateInCurrentMonth() -> Date {
        Calendar.current.date(byAdding: .month, value: currentMonthOffset, to: firstDayOfMonth(for: Date()))!
    }
    
    private func firstDayOfMonth(for date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: components)!
    }
    
    private func datesInMonth() -> [Date] {
        let calendar = Calendar.current
        let firstOfMonth = dateInCurrentMonth()
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        
        var days: [Date] = []
        
        let weekdayOffset = calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday
        let prefix = weekdayOffset < 0 ? 7 + weekdayOffset : weekdayOffset
        
        for dayOffset in -prefix..<range.count {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func backgroundColor(for date: Date) -> Color {
        if let selected = selectedDate {
            return Calendar.current.isDate(date, inSameDayAs: selected) ? .green : .clear
        }
        return .clear
    }
    
    private func textColor(for date: Date) -> Color {
        if let selected = selectedDate {
            return Calendar.current.isDate(date, inSameDayAs: selected) ? .white : .white.opacity(0.8)
        }
        return .white
    }
    
    private var fileEar: some View {
        let baseHeight: CGFloat = 35
        let expandedHeight: CGFloat = 38
        let currentHeight = fileTabExpanded ? expandedHeight : baseHeight
        let extraShift = fileTabExpanded ? (expandedHeight - baseHeight)/2 : 0

        return ZStack(alignment: .bottom) {
            Rectangle()
                    .fill(ColorPalette.Green6)
               
            HStack {
                Image(systemName: "calendar")
                Text("Calendar")
            }
            .padding()
            .font(.system(size: 15))
            .foregroundColor(.white)
        }
            .zIndex(-999)
            .frame(width: 130, height: currentHeight)
            .cornerRadius(6, corners: [.bottomLeft, .bottomRight])
            .offset(x: -90, y: 290)
            
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    fileTabExpanded.toggle()
                    // Kulakçığa tıklandığında da expanded moda geçebilir
                    if fileTabExpanded {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isCalendarCollapsed = true
                            headerHeight = maxExpandedHeight
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            let candidate = collapsedHeight + value.translation.height
                            headerHeight = min(candidate, maxExpandedHeight)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if headerHeight >= collapsedHeight + expandTrigger {
                                isCalendarCollapsed = true
                                headerHeight = maxExpandedHeight
                            } else {
                                headerHeight = collapsedHeight
                            }
                        }
                    }
            )
    }
}
enum DropTarget {
    case burned
    case notBurned
    case breakfast
    case snack
    case dinner
    case additional
}

struct SelectedDayView: View {
    @Binding var selectedDate: Date?
    @Binding var showingAddSymptom: Bool
    
    @StateObject var foodTagManager = FoodTagManager()
    @FocusState private var isTagFieldFocused: Bool
    
    @State private var newTagText = ""
    @State private var selectedDayComment = ""
    @State private var savedFoods: [String] = []
    @State private var isEditMode = false
    
    @State private var burnedFoods: [String] = []
    @State private var notBurnedFoods: [String] = []
    
    @State private var breakfastFoods: [String] = []
    @State private var snackFoods: [String] = []
    @State private var dinnerFoods: [String] = []
    @State private var additionalFoods: [String] = []
    
    @State private var areMealsExpanded = false
    @State private var isBreakfastExpanded = false
    @State private var isSnackExpanded = false
    @State private var isDinnerExpanded = false
    @State private var isAdditionalExpanded = false

    @State private var selectedMood: String? = nil

    @State private var burnedFoodsByDate: [String: [String]] = [:]
    @State private var notBurnedFoodsByDate: [String: [String]] = [:]

    @State private var selectedSymptoms: [String] = []

    @State private var customSymptoms: [String] = []
    @State private var newSymptomName = ""

    @State private var deleteCandidateSymptom: String? = nil

    @State private var showPaywall = false
    
    @State private var isPremiumToggle = false
    
    @FocusState private var popupFieldFocused: Bool

    @EnvironmentObject var authViewModel: AuthViewModel
    
    let allSymptoms = [
        "Bloating",
        "Nausea",
        "Stomach Pain",
        "Acid Reflux",
        "Indigestion",
        "Lactose Intolerance",
        "Gas",
        "Loss of Appetite",
        "Burping"
    ]

    let symptomEmojiMap: [String: String] = [
        "Bloating": "🎈",
        "Nausea": "🤢",
        "Stomach Pain": "🤕",
        "Acid Reflux": "🔥",
        "Indigestion": "😩",
        "Lactose Intolerance": "🥛",
        "Gas": "💨",
        "Loss of Appetite": "🥄",
        "Burping": "😮‍💨"
    ]

    
    var body: some View {
        if let selected = selectedDate {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(formattedDate(selected))")
                    .padding(.top, 8)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(messageFor(selected))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                VStack {
                    
                    //eklenen günlük yemek tagleri
                    if let selected = selectedDate {
                        if !savedFoods.isEmpty {
                            SavedFoodTagsView(
                                savedFoods: savedFoods,
                                isEditMode: $isEditMode,
                                selectedDate: $selectedDate,
                                onDelete: removeFood
                            )
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("No foods logged yet.")
                                    Text("Start typing below to add one!")
                                }
                                Spacer()
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                        }
                    }

                    
                    AddFoodInputView(
                        newTagText: $newTagText,
                        selectedDate: $selectedDate,
                        isTagFieldFocused: $isTagFieldFocused,
                        savedFoods: $savedFoods,
                        foodTagManager: foodTagManager
                    )
                    
                    
                    // Autocomplete: Önerilen etiketler
                    autocompleteSection
                }
                .onAppear {
                    foodTagManager.fetchTags()
                }
                
             
                
                //Meals
                if let selected = selectedDate, !savedFoods.isEmpty {
                    SelectedDayMeals(
                        handleDrop: handleDrop,
                        breakfast: breakfastFoods,
                        snack: snackFoods,
                        dinner: dinnerFoods,
                        additional: additionalFoods,
                        isEditMode: $isEditMode,
                        isBreakfastExpanded: $isBreakfastExpanded,
                        isSnackExpanded: $isSnackExpanded,
                        isDinnerExpanded: $isDinnerExpanded,
                        isAdditionalExpanded: $isAdditionalExpanded
                    )
                    
                }
               
                //
                let key = dateKey(for: selected)
                let burnedForDay = burnedFoodsByDate[key] ?? []
                let safeForDay = notBurnedFoodsByDate[key] ?? []
                
                BurnedOrNotView(
                    burnedFoods: .constant(burnedForDay),
                    notBurnedFoods: .constant(safeForDay),
                    isEditMode: $isEditMode,
                    selectedDate: $selectedDate,
                    handleDrop: handleDrop,
                    onDeleteFood: removeBurnedOrSafeTag
                )
                
                //Daily Comment
                dailyComment
                
                //symptoms here
                symptomSection
                
                //Daily Moods
                dailyMoods
            
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(ColorPalette.Green6)
            .cornerRadius(12)
            .padding(.horizontal)
            .sheet(isPresented: $showPaywall) {
                PaywallView(isPremiumToggle: $isPremiumToggle)
                    .environmentObject(authViewModel) // Paywall’ın ihtiyaç duyduğu AuthViewModel
            }
            .onChange(of: isPremiumToggle) { becamePremium in
                if becamePremium {
                    Task { await authViewModel.fetchUser() }
                }
            }
            .onAppear {
                foodTagManager.fetchTags()
                print("🔍 Tags loaded:", foodTagManager.tags)

                if let date = selectedDate {
                    foodTagManager.fetchFoodsForDate(date) { self.savedFoods = $0 }
                    fetchBurnedAndSafeFoods(for: date)
                    fetchMeals(for: date)
                    fetchCommentAndMood(for: date)
                    fetchSymptoms(for: date)
                    fetchCustomSymptoms()
                }
            }
            .onChange(of: selectedDate) { newDate in
                guard let date = newDate else {
                    self.savedFoods = []
                    return
                }

                foodTagManager.fetchFoodsForDate(date) { self.savedFoods = $0 }
                fetchBurnedAndSafeFoods(for: date)
                fetchMeals(for: date)
                fetchCommentAndMood(for: date)
                fetchSymptoms(for: date)
            }
            .onChange(of: selectedDate) { newDate in
                guard let date = newDate else { return }

                let key = dateKey(for: date)
                burnedFoods = burnedFoodsByDate[key] ?? []
                notBurnedFoods = notBurnedFoodsByDate[key] ?? []
                deleteCandidateSymptom = nil
            }
            .overlay(alignment: .center) {
                if showingAddSymptom {
                    ZStack {
                        // karanlık arkaplan
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture { /* swallow taps, do nothing */ }

                        // kart
                        VStack(spacing: 12) {
                            Text("Add a custom symptom")
                                .font(.headline)
                                .foregroundColor(ColorPalette.Green1)

                            TextField("e.g. Headache", text: $newSymptomName)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .focused($popupFieldFocused)
                                .submitLabel(.done)
                                .onSubmit { addCustomSymptom() }
                                .padding()
                                .background(ColorPalette.Green6.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(ColorPalette.Green1)
                                .accentColor(.black)
                            
                            HStack {
                                Button("Cancel") {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showingAddSymptom = false
                                        newSymptomName = ""
                                    }
                                }
                                .foregroundColor(ColorPalette.Green1)
                                Spacer()
                                Button("Save") {
                                    addCustomSymptom()
                                }
                                .disabled(newSymptomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .foregroundColor(ColorPalette.Green1)
                            }
                            .font(.headline)
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .frame(maxWidth: 340)
                        .background(ColorPalette.Green5.opacity(5))
                        .cornerRadius(16)
                        .shadow(radius: 20)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear { DispatchQueue.main.async { popupFieldFocused = true } }
                        .zIndex(2)
                    }
                    .zIndex(2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingAddSymptom)
                    //CANCEL VE SAVE BUTONLARI ÇALIŞMIYOR
                }
            }


            
        }
    }
    
    @ViewBuilder
    private var dailyComment: some View {
        Divider()
            .background(ColorPalette.Green1)
        Text("Add any notes about your mood or symptoms...")
            .foregroundColor(.white)
        TextEditor(text: $selectedDayComment)
            .padding()
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 100)
            .frame(maxWidth: .infinity)
            .foregroundColor(.black)
            .background(ColorPalette.Green5)
            .clipShape(Rectangle())
            .cornerRadius(16)
            .accentColor(.black)
            .onChange(of: selectedDayComment) { newValue in
                guard let uid = Auth.auth().currentUser?.uid,
                      let date = selectedDate else { return }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateKey = formatter.string(from: date)
                
                Firestore.firestore()
                    .collection("users").document(uid)
                    .collection("dailyLogs").document(dateKey)
                    .setData(["comment": newValue], merge: true)
            }
    }
    
    @ViewBuilder
    private var symptomSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Symptoms")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {

                    // ✅ Varsayılan + Kullanıcıya özel symptom’ları birleştir
                    let combinedSymptoms = Array(Set(allSymptoms + customSymptoms)).sorted()

                    ForEach(combinedSymptoms, id: \.self) { symptom in
                        let isCustom = customSymptoms.contains(symptom)
                        HStack(spacing: 4) {
                            // Varsayılanlara emoji, custom’lara küçük bir simge
                            if let emo = symptomEmojiMap[symptom] {
                                Text(emo).font(.system(size: 18))
                            } else {
                                Image(systemName: "stethoscope")
                                    .font(.system(size: 14))
                            }

                            Text(symptom)

                            if selectedSymptoms.contains(symptom) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            
                            if deleteCandidateSymptom == symptom && isCustom {
                                        Button {
                                            removeCustomSymptom(symptom)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 14))
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .transition(.opacity.combined(with: .scale))
                                    }
                        }
                        .padding(8)
                        .foregroundColor(ColorPalette.Green1)
                        .background(
                            selectedSymptoms.contains(symptom)
                            ? ColorPalette.Green5
                            : Color.white.opacity(0.5)
                        )
                        .clipShape(Capsule())
                        .onTapGesture {
                                if deleteCandidateSymptom == symptom && isCustom {
                                    withAnimation(.easeInOut(duration: 0.15)) { deleteCandidateSymptom = nil }
                                } else {
                                    toggleSymptom(symptom)
                                    let action = selectedSymptoms.contains(symptom) ? "added" : "removed"
                                    logActivity(type: "symptom_toggle", title: "Symptom \(action): \(symptom)", icon: "cross.case")
                                }
                            }

                            // 👇 Uzun basışla (sadece custom olanlarda) çöp kutusunu göster
                            .onLongPressGesture(minimumDuration: 0.5) {
                                if isCustom {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                        deleteCandidateSymptom = symptom
                                    }
                                }
                            }
                    }

                    // ✅ En sonda Add butonu
                    Button {
                        if (authViewModel.currentUser?.isPremium ?? false) {
                            showingAddSymptom = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle")
                            Text("Add")
                        }
                        .padding(8)
                        .foregroundColor(.white)
                        .background(ColorPalette.Green3)
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
    }




    
    @ViewBuilder
    private var dailyMoods: some View {
        if let selected = selectedDate {
        HStack {
            Spacer()
            VStack {
                Divider()
                    .background(ColorPalette.Green1)
                
                Text(moodMessageFor(selected))
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                HStack(spacing: 24) {
                    ForEach(["sadmood", "normalmood", "happymood"], id: \.self) { mood in
                        Image(mood)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: selectedMood == mood ? 80 : 60) // 🔁 büyüme
                            .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedMood)
                            .onTapGesture {
                                selectedMood = mood

                                logActivity(type: "mood_set", title: "Mood set: \(mood)", icon: "face.smiling")

                                // Firestore'a kaydet
                                guard let uid = Auth.auth().currentUser?.uid,
                                      let date = selectedDate else { return }

                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                let dateKey = formatter.string(from: date)

                                Firestore.firestore()
                                    .collection("users").document(uid)
                                    .collection("dailyLogs").document(dateKey)
                                    .setData(["mood": mood], merge: true)
                            }

                    }
                    .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 0, y: 0)
                }
                
                
            }
            Spacer()
        }
    }
    }
    
    @ViewBuilder
    private var autocompleteSection: some View {
        let filteredTags = foodTagManager.tags.filter {
            $0.contains(newTagText.lowercased())
        }
        
        if !filteredTags.isEmpty {
            HStack {
                Text("Related Tags")
                    .foregroundColor(.white)
                Spacer()
            }
        }
        if !newTagText.isEmpty && !filteredTags.isEmpty {
            ScrollView {
                ForEach(foodTagManager.tags.filter {
                    $0.contains(newTagText.lowercased())
                }, id: \.self) { suggestion in
                    VStack {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.white)
                            Button(action: {
                                /*
                                newTagText = suggestion
                                DispatchQueue.main.async {
                                    isTagFieldFocused = false
                                    newTagText = suggestion
                                }
                                */
                                if let date = selectedDate {
                                        let cleaned = suggestion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                        
                                        // Firebase'e gönder
                                        foodTagManager.addFoodToDate(cleaned, for: date)
                                        foodTagManager.addTagIfNew(cleaned)
                                        
                                        // local olarak ekle
                                        if !savedFoods.contains(cleaned) {
                                            savedFoods.append(cleaned)
                                        }

                                    logActivity(type: "food_add", title: "Added: \(cleaned)", icon: "fork.knife")
                                    
                                        // temizle ve klavyeyi kapat
                                        newTagText = ""
                                        isTagFieldFocused = false
                                    }
                            }) {
                                Text(suggestion)
                                    .padding(5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .foregroundColor(.white)
                        }
                        .padding(5)
                        .background(ColorPalette.Green3.opacity(0.4))
                        .cornerRadius(12)
                        
                    }
                }
            }
            .padding()
            .frame(height: 180)
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private func fetchCustomSymptoms() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .getDocument { snap, _ in
                let arr = (snap?.data()?["customSymptoms"] as? [String]) ?? []
                DispatchQueue.main.async {
                    // Duplicates’ı engelle, alfabetik sırala
                    self.customSymptoms = Array(Set(arr)).sorted()
                }
            }
    }

    private func addCustomSymptom() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let raw = newSymptomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }

        // Tutarlı görünüm için Capitalized saklayalım
        let symptom = raw.capitalized

        Firestore.firestore()
            .collection("users").document(uid)
            .setData(["customSymptoms": FieldValue.arrayUnion([symptom])], merge: true) { _ in
                DispatchQueue.main.async {
                    if !self.customSymptoms.contains(symptom) {
                        self.customSymptoms.append(symptom)
                        self.customSymptoms.sort()
                    }
                    // İstersen yeni ekleneni o güne otomatik seçili yap:
                    // if !self.selectedSymptoms.contains(symptom) {
                    //     self.selectedSymptoms.append(symptom)
                    //     toggleSymptom(symptom) // günlük kayda da işler
                    // }

                    self.newSymptomName = ""
                    self.showingAddSymptom = false
                    logActivity(type: "symptom_custom_add", title: "Custom symptom added: \(symptom)", icon: "stethoscope")
                }
            }
    }
    
    private func removeCustomSymptom(_ symptom: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .setData(["customSymptoms": FieldValue.arrayRemove([symptom])], merge: true) { _ in
                DispatchQueue.main.async {
                    // Kullanıcıya özel listeden çıkar
                    self.customSymptoms.removeAll { $0 == symptom }
                    // O gün seçiliyse günlük kayıttan da çıkar
                    if self.selectedSymptoms.contains(symptom) {
                        self.selectedSymptoms.removeAll { $0 == symptom }
                        if let date = self.selectedDate {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let dateKey = formatter.string(from: date)

                            Firestore.firestore()
                                .collection("users").document(uid)
                                .collection("dailyLogs").document(dateKey)
                                .setData(["symptoms": self.selectedSymptoms], merge: true)
                        }
                    }
                    self.deleteCandidateSymptom = nil
                    logActivity(type: "symptom_custom_delete",
                                title: "Custom symptom deleted: \(symptom)",
                                icon: "trash")
                }
            }
    }
    
    func fetchCommentAndMood(for date: Date) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs").document(dateKey)
            .getDocument { snapshot, _ in
                let data = snapshot?.data()

                DispatchQueue.main.async {
                    selectedDayComment = data?["comment"] as? String ?? ""
                    selectedMood = data?["mood"] as? String
                }
            }
    }


    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func messageFor(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return NSLocalizedString("what_today", comment: "")
        } else if date < Date() {
            return NSLocalizedString("what_that_day", comment: "")
        } else {
            return NSLocalizedString("what_future", comment: "")
        }
    }

    
    private func moodMessageFor(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "How are you feeling today?"
        } else if date < Date() {
            return "How did you feel that day?"
        } else {
            return "How did you feel that day?"
        }
    }
    
    private func removeFood(_ food: String, for date: Date) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let dateKey = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }()
        
        let docRef = Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs").document(dateKey)
        
        docRef.getDocument { snapshot, error in
            guard var currentFoods = snapshot?.data()?["foods"] as? [String] else { return }
            
            currentFoods.removeAll { $0 == food }
            
            docRef.setData(["foods": currentFoods], merge: true)
            
            // Update local view
            DispatchQueue.main.async {
                withAnimation {
                    savedFoods = currentFoods
                }
            }
        }
    }
    
    func handleDrop(_ providers: [NSItemProvider], _ target: DropTarget) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSString.self) {
                _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                    if let food = object as? String {
                        DispatchQueue.main.async {
                            guard let date = selectedDate,
                                  let uid = Auth.auth().currentUser?.uid else { return }

                            let dateKey = self.dateKey(for: date)
                            let docRef = Firestore.firestore()
                                .collection("users").document(uid)
                                .collection("dailyLogs").document(dateKey)

                            switch target {
                            case .burned:
                                var list = burnedFoodsByDate[dateKey] ?? []
                                if !list.contains(food) {
                                    list.append(food)
                                    burnedFoodsByDate[dateKey] = list
                                    docRef.setData(["burnedFoods": list], merge: true)
                                    burnedFoods = list
                                }

                            case .notBurned:
                                var list = notBurnedFoodsByDate[dateKey] ?? []
                                if !list.contains(food) {
                                    list.append(food)
                                    notBurnedFoodsByDate[dateKey] = list
                                    docRef.setData(["safeFoods": list], merge: true)
                                    notBurnedFoods = list
                                }

                            case .breakfast, .snack, .dinner, .additional:
                                var key = ""
                                switch target {
                                    case .breakfast: key = "breakfast"
                                    case .snack:     key = "snack"
                                    case .dinner:    key = "dinner"
                                    case .additional:key = "additional"
                                    default: break
                                }

                                docRef.getDocument { snapshot, _ in
                                    var current = (snapshot?.data()?["meals"] as? [String: [String]]) ?? [:]
                                    var items = current[key] ?? []

                                    if !items.contains(food) {
                                        items.append(food)
                                        current[key] = items
                                        docRef.setData(["meals": current], merge: true)

                                        DispatchQueue.main.async {
                                            withAnimation {
                                                switch target {
                                                    case .breakfast:
                                                        if !breakfastFoods.contains(food) {
                                                            breakfastFoods.append(food)
                                                        }
                                                    case .snack:
                                                        if !snackFoods.contains(food) {
                                                            snackFoods.append(food)
                                                        }
                                                    case .dinner:
                                                        if !dinnerFoods.contains(food) {
                                                            dinnerFoods.append(food)
                                                        }
                                                    case .additional:
                                                        if !additionalFoods.contains(food) {
                                                            additionalFoods.append(food)
                                                        }
                                                    default: break
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    
    func fetchBurnedAndSafeFoods(for date: Date) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let key = dateKey(for: date)

        let docRef = Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs").document(key)

        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }

            DispatchQueue.main.async {
                burnedFoodsByDate[key] = data["burnedFoods"] as? [String] ?? []
                notBurnedFoodsByDate[key] = data["safeFoods"] as? [String] ?? []

                // Güncel güne ait görünüm de değişsin
                if selectedDate == date {
                    burnedFoods = burnedFoodsByDate[key] ?? []
                    notBurnedFoods = notBurnedFoodsByDate[key] ?? []
                }
            }
        }
    }

    
    func fetchMeals(for date: Date) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)
        
        let docRef = Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs").document(dateKey)
        
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let meals = data["meals"] as? [String: [String]] else {
                // reset all if nothing
                DispatchQueue.main.async {
                    breakfastFoods = []
                    snackFoods = []
                    dinnerFoods = []
                    additionalFoods = []
                }
                return
            }
            
            DispatchQueue.main.async {
                breakfastFoods  = meals["breakfast"]  ?? []
                snackFoods      = meals["snack"]      ?? []
                dinnerFoods     = meals["dinner"]     ?? []
                additionalFoods = meals["additional"] ?? []
            }
        }
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func removeBurnedOrSafeTag(_ food: String, _ target: DropTarget, _ date: Date) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let dateKey = dateKey(for: date)
        let docRef = Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs").document(dateKey)

        docRef.getDocument { snapshot, error in
            guard var data = snapshot?.data() else { return }

            if target == .burned {
                var list = (data["burnedFoods"] as? [String]) ?? []
                list.removeAll { $0 == food }
                docRef.setData(["burnedFoods": list], merge: true)
                DispatchQueue.main.async {
                    burnedFoodsByDate[dateKey] = list
                    burnedFoods = list
                }
            } else if target == .notBurned {
                var list = (data["safeFoods"] as? [String]) ?? []
                list.removeAll { $0 == food }
                docRef.setData(["safeFoods": list], merge: true)
                DispatchQueue.main.async {
                    notBurnedFoodsByDate[dateKey] = list
                    notBurnedFoods = list
                }
            }
        }
    }

    func fetchSymptoms(for date: Date) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs").document(dateKey)
            .getDocument { snapshot, _ in
                let data = snapshot?.data()
                DispatchQueue.main.async {
                    self.selectedSymptoms = data?["symptoms"] as? [String] ?? []
                }
            }
    }

    func toggleSymptom(_ symptom: String) {
        guard let date = selectedDate,
              let uid = Auth.auth().currentUser?.uid else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)

        if selectedSymptoms.contains(symptom) {
            selectedSymptoms.removeAll { $0 == symptom }
        } else {
            selectedSymptoms.append(symptom)
        }

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("dailyLogs").document(dateKey)
            .setData(["symptoms": selectedSymptoms], merge: true)
    }

    
}

struct SavedFoodTagsView: View {
    var savedFoods: [String]
    @Binding var isEditMode: Bool
    @Binding var selectedDate: Date?
    var onDelete: (String, Date) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                // Edit Mode Button
                Button {
                    isEditMode.toggle()
                } label: {
                    Image(systemName: isEditMode ? "xmark.bin.circle.fill" : "xmark.bin.circle")
                        .font(.system(size: 25))
                        .foregroundColor(.white)
                }
                
                ForEach(savedFoods, id: \.self) { food in
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(ColorPalette.Green6)
                        Text(food.capitalized)
                            .foregroundColor(.primary)
                        
                        if isEditMode {
                            Button {
                                if let date = selectedDate {
                                    onDelete(food, date)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(5)
                    .font(.body)
                    .padding(.horizontal,2)
                    .padding(.vertical,2)
                    .background(ColorPalette.Green5)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onDrag {
                        NSItemProvider(object: NSString(string: food))
                    }
                }
            }
            .padding(5)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct AddFoodInputView: View {
    @Binding var newTagText: String
    @Binding var selectedDate: Date?
    @FocusState.Binding var isTagFieldFocused: Bool
    @Binding var savedFoods: [String]
    
    var foodTagManager: FoodTagManager
    
    var body: some View {
        HStack {
            TextField("Enter food name", text: $newTagText)
                .padding()
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isTagFieldFocused)
                .frame(maxWidth: .infinity)
                .foregroundColor(ColorPalette.Green1)
                .background(ColorPalette.Green5)
                .clipShape(Rectangle())
                .cornerRadius(16)
                .accentColor(.black)
            
            if !newTagText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button {
                    if let date = selectedDate {
                        let cleaned = newTagText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        
                        // Firebase'e gönder
                        foodTagManager.addFoodToDate(cleaned, for: date)
                        foodTagManager.addTagIfNew(cleaned)
                        
                        // local olarak ekle
                        if !savedFoods.contains(cleaned) {
                            savedFoods.append(cleaned)
                        }
                        logActivity(type: "food_add", title: "Added: \(cleaned)", icon: "fork.knife")
                        
                        // temizle
                        newTagText = ""
                        isTagFieldFocused = false
                    }
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20))
                        .padding()
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white).opacity(0.4))
                }
            }
        }
    }
}


struct BurnedOrNotView: View {
    @Binding var burnedFoods: [String]
    @Binding var notBurnedFoods: [String]
    @Binding var isEditMode: Bool
    @Binding var selectedDate: Date?
    
    var handleDrop: (_ providers: [NSItemProvider], _ target: DropTarget) -> Bool
    var onDeleteFood: (_ food: String, _ target: DropTarget, _ date: Date) -> Void
    var body: some View {
        HStack {
            // Not Burned Drop Zone
            VStack {
                HStack {
                    Text("🍃")
                    Text("**Safe** Foods")
                }
                .padding(.top,5)
                .foregroundColor(.white)
                
                ScrollView {
                    if !notBurnedFoods.isEmpty {
                        ForEach(notBurnedFoods, id: \.self) { food in
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundColor(ColorPalette.Green6)
                                Text("\(food.capitalized)")
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .layoutPriority(1)
                                
                                // Silme butonu
                                if isEditMode {
                                    Button {
                                        if let date = selectedDate {
                                                    onDeleteFood(food, .notBurned, date)
                                                }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(5)
                            .font(.body)
                            .background(ColorPalette.Green5)
                            .cornerRadius(12)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .background(ColorPalette.Lime3.opacity(0.5))
            .cornerRadius(12)
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleDrop(providers, .notBurned)
            }
            
            // Burned Drop Zone
            VStack {
                HStack {
                    Text("🔥")
                    Text("**Trigger** Foods")
                }
                .padding(.top,5)
                .foregroundColor(.white)
                
                ScrollView {
                    if !burnedFoods.isEmpty {
                        ForEach(burnedFoods, id: \.self) { food in
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundColor(ColorPalette.Green6)
                                Text("\(food.capitalized)")
                                    .foregroundColor(.black)
                                    .lineLimit(1) // ❗️tek satırda tut
                                    .layoutPriority(1) // ❗️gerekirse daha fazla alan al
                                
                                // Silme butonu
                                if isEditMode {
                                    Button {
                                        if let date = selectedDate {
                                                    onDeleteFood(food, .burned, date)
                                                }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(5)
                            .font(.body)
                            .background(ColorPalette.Green5)
                            .cornerRadius(12)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .background(ColorPalette.Red3.opacity(0.5))
            .cornerRadius(12)
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleDrop(providers, .burned)
            }
        }
        
    }
}

struct SelectedDayMeals: View {
    
    var handleDrop: (_ providers: [NSItemProvider], _ target: DropTarget) -> Bool
    var breakfast: [String]
    var snack: [String]
    var dinner: [String]
    var additional: [String]
    
    @Binding var isEditMode: Bool
    @Binding var isBreakfastExpanded: Bool
    @Binding var isSnackExpanded: Bool
    @Binding var isDinnerExpanded: Bool
    @Binding var isAdditionalExpanded: Bool
    
    private let mealIcons = ["sunrise", "leaf", "moon", "ellipsis"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 25) {
                Spacer()
                ForEach(mealIcons, id: \.self) { icon in
                    Button {
                        switch icon {
                        case "sunrise":   isBreakfastExpanded.toggle()
                        case "leaf":      isSnackExpanded.toggle()
                        case "moon":      isDinnerExpanded.toggle()
                        case "ellipsis":  isAdditionalExpanded.toggle()
                        default: break
                        }
                    } label: {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(ColorPalette.Green5)
                    }
                }
                Spacer()
            }
            .padding()
            if isBreakfastExpanded {
                MealDropZone(title: "Breakfast", icon: "sunrise", color: .yellow.opacity(0.3), dropTarget: .breakfast, handleDrop: handleDrop, meals: breakfast,isEditMode: $isEditMode,
                             isExpanded: $isBreakfastExpanded)
            }
            if isSnackExpanded {
                MealDropZone(title: "Snack", icon: "leaf", color: .green.opacity(0.3), dropTarget: .snack, handleDrop: handleDrop, meals: snack,isEditMode: $isEditMode,
                             isExpanded: $isSnackExpanded)
            }
            if isDinnerExpanded {
                MealDropZone(title: "Dinner", icon: "moon", color: .blue.opacity(0.3), dropTarget: .dinner, handleDrop: handleDrop, meals: dinner,isEditMode: $isEditMode,
                             isExpanded: $isDinnerExpanded)
            }
            if isAdditionalExpanded {
                MealDropZone(title: "Additional", icon: "ellipsis", color: .gray.opacity(0.3), dropTarget: .additional, handleDrop: handleDrop, meals: additional,isEditMode: $isEditMode,
                             isExpanded: $isAdditionalExpanded)
            }
        }
    }
}

struct MealDropZone: View {
    var title: String
    var icon: String
    var color: Color
    var dropTarget: DropTarget
    var handleDrop: (_ providers: [NSItemProvider], _ target: DropTarget) -> Bool

    var meals: [String]

    @Binding var isEditMode: Bool
    @Binding var isExpanded: Bool

    // ✅ Adaptif grid: Ekran genişliğine göre otomatik sütun
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 8, alignment: .top)
    ]

    var body: some View {
        VStack {
            HStack {
                Label(title, systemImage: icon)
                    .padding()
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            // ⬇️ Burayı LazyVGrid'e çevirdik
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(meals, id: \.self) { meal in
                        HStack(spacing: 6) {
                            Image(systemName: "tag")
                                .foregroundColor(ColorPalette.Green4)
                            Text(meal.capitalized)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            if isEditMode {
                                Button {
                                    // İstersen buraya silme aksiyonunu ekleyebilirsin
                                    // (mevcut yapıda onDelete yok; eklemek istersen
                                    // dışarıdan closure geçecek şekilde güncelleyebiliriz)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(8)
                        .background(ColorPalette.Green5)
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(height: isExpanded ? 180 : 60)
        .animation(.easeInOut, value: isExpanded)
        .padding(5)
        .background(color)
        .cornerRadius(10)
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers, dropTarget)
        }
    }
}


struct SymptomTagsView: View {
    var selectedSymptoms: [String]
    @Binding var selectedDate: Date?
    var onToggle: (String, Date) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(selectedSymptoms, id: \.self) { symptom in
                    HStack {
                        Text(symptom)
                            .foregroundColor(ColorPalette.Green1)

                        Button {
                            if let date = selectedDate {
                                onToggle(symptom, date)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(5)
                    .font(.body)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(5)
        }
    }
}


private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}


struct CustomTextField3: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        Group {
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.white.opacity(0.5))
                .foregroundColor(ColorPalette.Green1)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black).opacity(0.4))
        }
    }
}

struct RoundedCorner: InsettableShape {
    var radius: CGFloat = 12
    var corners: UIRectCorner = .allCorners
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> RoundedCorner {
        var c = self
        c.insetAmount += amount
        return c
    }

    func path(in rect: CGRect) -> Path {
        let r = max(0, radius - insetAmount)
        let bez = UIBezierPath(
            roundedRect: rect.insetBy(dx: insetAmount, dy: insetAmount),
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: r, height: r)
        )
        return Path(bez.cgPath)
    }
}

extension View {
    /// Sadece istediğin köşelere radius uygular
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct Activity: Identifiable {
    let id: String
    let type: String
    let title: String
    let icon: String
    let createdAt: Date?
    let meta: [String: Any]

    init(id: String, data: [String: Any]) {
        self.id = id
        self.type = data["type"] as? String ?? "unknown"
        self.title = data["title"] as? String ?? ""
        self.icon = data["icon"] as? String ?? "bolt.circle"
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        self.meta = data["meta"] as? [String: Any] ?? [:]
    }
}

extension Date {
    func timeAgoString() -> String {
        let seconds = Int(Date().timeIntervalSince(self))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }
}

func logActivity(type: String, title: String, icon: String = "bolt.circle", meta: [String: Any] = [:]) {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let ref = Firestore.firestore()
        .collection("users").document(uid)
        .collection("activities")
        .document()

    let data: [String: Any] = [
        "type": type,
        "title": title,
        "icon": icon,
        "createdAt": FieldValue.serverTimestamp(),
        "meta": meta
    ]
    ref.setData(data, merge: false)
}

struct TabBarIcons: Identifiable {
    var id: UUID = .init()
    var title: String
    var icon: String
    var image: String
}
var iconsList: [TabBarIcons] = [
    TabBarIcons(title: "Markets", icon: "",image: "chart.line.uptrend.xyaxis"),
    TabBarIcons(title: "Leaders", icon: "",image: "crown"),
    TabBarIcons(title: "Portfolio", icon: "",image: "briefcase"),
    TabBarIcons(title: "Profile", icon: "",image: "person")
]

struct TabBarView: View {
    @Binding var selectedBottomTab: TabSection
    
    var body: some View {
        HStack(spacing: 20) {
            tabButton(title: "Home", icon: "house", tab: .main)
            tabButton(title: "Society", icon: "person.wave.2", tab: .court)
            tabButton(title: "Staticts", icon: "chart.bar", tab: .players)
            tabButton(title: "Profile", icon: "person.fill", tab: .profile)
        }
        .padding(5)
        .frame(maxWidth: .infinity)
    }
    
    func tabButton(title: String, icon: String, tab: TabSection) -> some View {
        Button {
            selectedBottomTab = tab
        } label: {
            if selectedBottomTab == tab {
                HStack {
                    
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                    
                }
                .padding(.vertical)
                .padding(.horizontal)
                .foregroundColor(selectedBottomTab == tab ? Color.white : ColorPalette.Green1)
                .background(selectedBottomTab == tab ? ColorPalette.Green6 : .clear)
                .cornerRadius(16)
            } else {
                HStack {
                    
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                    
                }
                .padding(.vertical)
                .padding(.horizontal)
                .foregroundColor(selectedBottomTab == tab ? Color.white : ColorPalette.Green6)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ColorPalette.Green6,lineWidth: 3))
                .cornerRadius(16)
            }
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(AuthViewModel())
}
