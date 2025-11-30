//
//  PrivacyPolicyView.swift
//  FlashDecks
//
//  Created by Zerda Yilmaz on 2.12.2024.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                VStack {
                    VStack {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            
                            HStack {
                                Spacer()
                                
                                Text("Privacy and Policy")
                                
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Last updated: May 2025")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Introduction")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("""
                        FoodLog (“we”, “us”, or “our”) is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and protect your data when you use our mobile application to track your daily meals and digestive symptoms.
                        """)

                        Divider()

                        Text("1. Information We Collect")
                            .font(.headline)

                        Text("""
                        We collect the following types of data:
                        - **Account Information**: Email address and name used during registration.
                        - **Daily Logs**: Meals you track, food tags, symptom selections, and mood notes.
                        - **Device Info**: OS version, app version, and basic device analytics.
                        """)

                        Divider()

                        Text("2. How We Use Your Data")
                            .font(.headline)

                        Text("""
                        We use your data to:
                        - Enable daily tracking and personalized insights.
                        - Store and sync your logs across sessions.
                        - Provide customer support if requested.
                        """)

                        Divider()

                        Text("3. Data Storage & Security")
                            .font(.headline)

                        Text("""
                        FoodLog uses Firebase (Google) to securely store your data. While we take steps to protect your information, no system is 100% secure.
                        """)

                        Divider()

                        Text("4. Third-Party Services")
                            .font(.headline)

                        Text("""
                        We use Firebase services. Their privacy policy is available at:
                        https://firebase.google.com/support/privacy
                        """)

                        Divider()

                        Text("5. Your Rights")
                            .font(.headline)

                        Text("""
                        - Access and export your data
                        - Request deletion of your account
                        - Withdraw consent by deleting your account
                        """)

                        Divider()

                        Text("6. Contact")
                            .font(.headline)

                        Text("""
                        For questions, contact us at:
                        📧 zerdayilmazy@gmail.com
                        """)

                    }
                    .padding()
                }
                .foregroundColor(.white)
            }
                .scrollDismissesKeyboard(.interactively)
        }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    PrivacyPolicyView()
}
