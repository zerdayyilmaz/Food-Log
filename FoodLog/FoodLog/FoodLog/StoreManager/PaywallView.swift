//
//  PaywallView.swift
//  FoodLog
//
//  Created by Zerda Yılmaz on 29.08.2025.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var storeViewModel = StoreViewModel()
    
    @Binding var isPremiumToggle: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            ColorPalette.Green6
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Text("Unlock")
                        .foregroundColor(.white)
                    Text("Premium")
                        .foregroundColor(ColorPalette.Green5)
                }
                .padding(.top)
                .font(.system(size: 30,design: .rounded))
                
                Text("**Make sense** of your gut with **smarter** insights")
                    .padding(.top,5)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 15))
                    .padding(.horizontal)
                
                Spacer()
                //
                ZStack(alignment: .bottom) {
                        
                        //premium
                    ZStack(alignment: .center) {
                        
                            LinearGradient(
                                gradient: Gradient(colors: [.green, ColorPalette.Green5]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            VStack {
                                HStack {
                                    Text("Premium")
                                    Spacer()
                                }
                                featureRow(icon: "stethoscope",
                                           title: "Custom Symptoms",
                                           subtitle: "Create & track your own.")
                                featureRow(icon: "ecg.text.page.fill",
                                           title: "Weekly Health Report",
                                           subtitle: "Health Score, trends, insights.")
                                featureRow(icon: "doc.text.fill.viewfinder",
                                           title: "Export PDF",
                                           subtitle: "Doctor-ready summaries.")
                                VStack {
                                    HStack {
                                        Text("Starter")
                                        Spacer()
                                    }
                                    featureRow2(icon: "checkmark.circle", title: "Daily Food Logging")
                                    featureRow2(icon: "checkmark.circle", title: "Community Access")
                                    featureRow2(icon: "checkmark.circle", title: "Basic Statistics")
                                    featureRow2(icon: "checkmark.circle", title: "Daily Mood & Symptom Tracking")
                                }
                                .padding(.top)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(width: 360,height: 460)
                        .cornerRadius(20)
                        .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 0)
                }
                .padding(.bottom,50)
                
                if let product = storeViewModel.products.first {
                    Text("Cancel Anytime")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                // Satın alma butonu
                Button {
                storeViewModel.purchase {
                // ✅ Satın alma başarılı olduğunda
                isPremiumToggle = true
                savePersonInfo()
                dismiss()
                }
                } label: {
                Text("Subscribe Monthly – \(product.displayPrice)")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorPalette.Green5)
                .foregroundColor(ColorPalette.Green6)
                .cornerRadius(12)
                }
                
                // Restore butonu
                Button {
                storeViewModel.restorePurchases {
                isPremiumToggle = true
                savePersonInfo()
                dismiss()
                }
                } label: {
                Text("Restore Purchases")
                        .padding(.top)
                        .foregroundColor(.gray)
                }
                } else {
                ProgressView("Loading products…")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .onAppear {
        storeViewModel.fetchProducts()
        }
    }
    @ViewBuilder
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            
            Text("Premium")
                .font(.system(size: 16, weight: .semibold))
            Image(systemName: "lock.open")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 15)
        }
        .padding(8)
        .foregroundColor(ColorPalette.Green6)
        .background(.white.opacity(0.5))
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private func featureRow2(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
            }
            Spacer(minLength: 0)
            Text("Stays On")
                .font(.system(size: 15, weight: .semibold))
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 15)
        }
        .padding(8)
        .foregroundColor(ColorPalette.Green6)
    }
    
    private func savePersonInfo() {
        guard let uid = authViewModel.userSession?.uid else { return }
        let data: [String: Any] = ["isPremium": isPremiumToggle]
        Firestore.firestore()
            .collection("users").document(uid)
            .setData(data, merge: true)
    }
}

struct LEDFrame: View {
    var cornerRadius: CGFloat = 20
    var colors: [Color] = [ColorPalette.Green5, .green, .white, .green, ColorPalette.Green5]
    var lineWidth: CGFloat = 3
    var dash: [CGFloat] = [8, 14]
    
    @State private var spin: Double = 0
    @State private var phase: CGFloat = 0
    
    private var angular: AngularGradient {
        AngularGradient(gradient: Gradient(colors: colors), center: .center)
    }
    
    var body: some View {
        ZStack {
            // 1) Sürekli parlak halka – RENKLER dönüyor, çerçeve sabit
            angular
                .rotationEffect(.degrees(spin))            // ✅ sadece gradient döner
                .mask(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(style: StrokeStyle(lineWidth: lineWidth))
                )
                .blur(radius: 0.6)
            
            // 2) LED noktaları (dash’li) – yine gradient döner, çerçeve sabit
            angular
                .rotationEffect(.degrees(spin))            // ✅ sadece gradient döner
                .mask(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: lineWidth + 4,
                                               lineCap: .round,
                                               lineJoin: .round,
                                               dash: dash,
                                               dashPhase: phase)
                        )
                )
                .blur(radius: 0.6)
            
            // 3) İnce cam benzeri highlight (sabit)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.35), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .opacity(0.9)
        }
        .blendMode(.screen)
        .compositingGroup()
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                spin = 360                 // ↻ renk akışı
            }
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                phase = dash.reduce(0,+)   // ↯ LED dash akışı
            }
        }
    }
}



#Preview {
    PaywallView(isPremiumToggle: .constant(false))
        .environmentObject(AuthViewModel())
}
