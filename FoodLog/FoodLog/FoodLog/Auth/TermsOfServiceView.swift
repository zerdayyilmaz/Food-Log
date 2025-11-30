//
//  TermsOfServiceView.swift
//  FlashDecks
//
//  Created by Zerda Yilmaz on 2.12.2024.
//

import SwiftUI

struct TermsOfServiceView: View {
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
                                
                                Text("Terms Of Service")
                                
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Terms of Service")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Last updated: May 2025")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Welcome to FoodLog!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("""
                        By using the FoodLog app, you agree to these terms. If you do not agree, please do not use the application.
                        """)

                        Divider()

                        Text("1. Usage Requirements")
                            .font(.headline)

                        Text("""
                        You must be 13 years or older to use FoodLog. The app is for personal use only and designed to help log meals and digestive symptoms.
                        """)

                        Divider()

                        Text("2. Account Responsibility")
                            .font(.headline)

                        Text("""
                        You are responsible for maintaining the confidentiality of your login credentials and all activity under your account.
                        """)

                        Divider()

                        Text("3. Data Usage & Deletion")
                            .font(.headline)

                        Text("""
                        You have full control over your data. You can delete your daily logs or your entire account at any time via the Profile screen.
                        """)

                        Divider()

                        Text("4. Limitations")
                            .font(.headline)

                        Text("""
                        FoodLog is not a medical app. It does not provide medical advice and should not be used as a diagnostic tool.
                        """)

                        Divider()

                        Text("5. Changes to Terms")
                            .font(.headline)

                        Text("""
                        We may update these terms. Continuing to use the app after changes means you accept the new terms.
                        """)

                        Divider()

                        Text("6. Contact")
                            .font(.headline)

                        Text("""
                        For legal concerns or questions:
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
    }}

#Preview {
    TermsOfServiceView()
}
