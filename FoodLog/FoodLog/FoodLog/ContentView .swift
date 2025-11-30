//
//  ContentView.swift
//  YKS TYT AYT Deneme Buddy
//
//  Created by Zerda Yilmaz on 11.10.2024.
//

import SwiftUI
import AuthenticationServices



extension Color {
    static let darkbrown = Color(UIColor(red: 27/255.0, green: 25/255.0, blue: 26/255.0, alpha: 1.0))
}
struct ContentView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var navigateToSignUpView = false
    @State private var navigateToMainMenuView = false
    @State private var selectedButton: String = "Sign In" // Varsayılan olarak seçili buton
    @State private var navigateToSignIn = false
    @State private var navigateToSignUp = false
    @State private var navigateToForgotPassword = false
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        Group {
            if viewModel.userSession != nil {
                MainMenuView()
            } else {
                NavigationStack {
                    ZStack(alignment: .top) {
                            Image("welcome.1")
                                .resizable()
                                .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            VStack(alignment: .leading) {
                                Text("Food**Log**")
                                    .foregroundColor(.white)
                                    .font(.system(size: 55,design: .rounded))
                                    .padding(.top)
                            }
                            .padding()
                            
                            Text("Track, learn, improve.")
                                .padding(.top,-20)
                                .foregroundColor(.white)
                            Spacer()
                            
                            VStack {
                            // Butonlar
                            HStack(spacing: -50) {
                                NavigationLink(destination: SignInView(), isActive: $navigateToSignIn) {
                                    
                                    // Sign In Button
                                    Button(action: {
                                        selectedButton = "Sign In"
                                        navigateToSignIn = true
                                    }) {
                                        Text("Sign In")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(selectedButton == "Sign In" ? Color.white : Color.clear)
                                            .foregroundColor(selectedButton == "Sign In" ? Color.black : Color.white)
                                            .clipShape(Capsule()) // Capsule şekli
                                            .overlay(
                                                Capsule() // Çerçeve de Capsule şeklinde
                                                    .stroke(Color.white, lineWidth: 2)
                                            )                                    }
                                }
                                
                                NavigationLink(destination: SignUpView(), isActive: $navigateToSignUp) {
                                    
                                    // Sign Up Button
                                    Button(action: {
                                        selectedButton = "Sign Up"
                                        navigateToSignUp = true
                                    }) {
                                        Text("Sign Up")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(selectedButton == "Sign Up" ? Color.white : Color.clear)
                                            .foregroundColor(selectedButton == "Sign Up" ? Color.black : Color.white)
                                            .clipShape(Capsule()) // Capsule şekli
                                            .overlay(
                                                Capsule() // Çerçeve de Capsule şeklinde
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .background(Color.clear)
                            .clipShape(Capsule()) // Capsule şekli
                            .overlay(
                                Capsule() // Çerçeve de Capsule şeklinde
                                    .stroke(Color.clear)
                            )
                            .padding(.horizontal, 20)
                            
                            VStack {
                                Text("By continuing, you agree to our")
                                HStack {
                                    NavigationLink(destination: TermsOfServiceView()) {
                                        Text("Terms of Service")
                                            .foregroundColor(.green)
                                    }
                                    Text("and")
                                    NavigationLink(destination: PrivacyPolicyView()) {
                                        Text("Privacy Policy")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .foregroundColor(.gray)
                            .font(.system(size: 15))
                        }
                            .padding(.bottom,20)
                        }
                    }
                    .background(Color.darkbrown)
                }
                .navigationBarHidden(true)
            }
        }
        
        
    }
    private func handleAuthorization(authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Kullanıcı bilgilerini al
            let userID = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            
            // Kullanıcı bilgilerini işleme
            print("User ID: \(userID)")
            print("Email: \(email ?? "No email")")
            print("Full Name: \(fullName?.givenName ?? "No name")")
        }
    }
    // Kullanıcıyı kaydetme fonksiyonu
    private func registerUser() {
        // Girilen bilgilerin boş olup olmadığını kontrol et
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            print("Lütfen tüm alanları doldurun")
            return
        }

        // Kullanıcı bilgilerini UserDefaults'a kaydet
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(email, forKey: "email")
        
        
        print("Kayıt başarılı! Kullanıcı bilgileri kaydedildi.")
        
        // Ana menüye yönlendir
        navigateToSignUpView = true
    }

    
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .onChange(of: text) { newValue in
                    text = newValue.lowercased()
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(10)
                .foregroundColor(.white)
        } else {
            TextField(placeholder, text: $text)
                .onChange(of: text) { newValue in
                    text = newValue.lowercased()
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(10)
                .foregroundColor(.white)
        }
    }
}

struct CustomTextField5: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .onChange(of: text) { newValue in
                    text = newValue.lowercased()
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(10)
                .foregroundColor(.black)
        } else {
            TextField(placeholder, text: $text)
                .onChange(of: text) { newValue in
                    text = newValue.lowercased()
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(10)
                .foregroundColor(.black)
        }
    }
}

struct CustomTextField4: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .onChange(of: text) { newValue in
                    text = newValue.lowercased()
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(10)
                .foregroundColor(.black)
        } else {
            TextField(placeholder, text: $text)
                .onChange(of: text) { newValue in
                    text = newValue.lowercased()
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(10)
                .foregroundColor(.black)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
