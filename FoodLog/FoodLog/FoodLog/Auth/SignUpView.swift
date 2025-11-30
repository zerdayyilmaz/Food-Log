//
//  SignUpView.swift
//  YKS TYT AYT Deneme Buddy
//
//  Created by Zerda Yilmaz on 15.10.2024.
//

import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var fullNamefb: String = ""
    @State private var emailfb: String = ""
    @State private var password: String = ""
    @State private var confirmPassword = ""
    @State private var navigateToContentView = false
    @State private var navigateToForgotPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var doNotShowAgain = false
    @State private var errorMessage: String = ""
    @State private var navigateToSignInView = false
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        NavigationStack {
            /*
            if showOnboarding {
                OnboardingView(doNotShowAgain: $doNotShowAgain, showOnboarding: $showOnboarding)
                    .onDisappear {
                        // Onboarding tamamlandığında UserDefaults'a kaydet
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    }
            } else {
             */
            ZStack {
                    Color.darkbrown
                        .edgesIgnoringSafeArea(.all)
                    
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                       
                        HStack {
                            Spacer()
                            
                            Text("Sign Up")
                            
                            Spacer()
                        }
                    }
                    Spacer()
                    
                }
                .padding()
                
                    
                    VStack(alignment: .leading, spacing: 8) {
                        
                        VStack(alignment: .leading) {
                            Text("Let's")
                            Text("get")
                            Text("started")
                            
                        }
                        .font(.system(size: 50))
                            .bold()
                            .foregroundColor(.white)
                        
                        VStack {
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 40))
                                
                                CustomTextFieldSignUpView(placeholder: "Username", text: $fullNamefb)
                                    .autocapitalization(.none)
                            }
                            
                            HStack {
                                Image(systemName: "envelope.circle")
                                    .font(.system(size: 40))
                                
                                CustomTextFieldSignUpView(placeholder: "Email", text: $emailfb)
                                    .autocapitalization(.none)
                            }
                            
                            HStack {
                                Image(systemName: "lock.circle")
                                    .font(.system(size: 40))
                                CustomTextFieldSignUpView(placeholder: "Password", text: $password)
                                    .autocapitalization(.none)
                            }
                            
                            HStack {
                                Image(systemName: "lock.circle")
                                    .font(.system(size: 40))
                                ZStack(alignment: .trailing) {
                                    CustomTextFieldSignUpView(placeholder: "Confirm Password", text: $confirmPassword)
                                        .autocapitalization(.none)
                                    
                                    if !password.isEmpty && !confirmPassword.isEmpty {
                                        if password == confirmPassword {
                                            Image(systemName: "checkmark.circle.fill")
                                                .padding()
                                                .imageScale(.large)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color(.systemGreen))
                                        } else {
                                            Image(systemName: "xmark.circle.fill")
                                                .padding()
                                                .imageScale(.large)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color(.systemRed))
                                        }
                                    }
                                }
                            }
                        }
                        VStack {
                            // Eğer hata varsa mesajı göster
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                            }
                            
                            // Şifre validasyon mesajı
                               if !password.isEmpty && !confirmPassword.isEmpty && !formIsValid {
                                   Text("Password should be 6 characters or long")
                                       .foregroundColor(.red)
                               }
                        }
                        NavigationLink(destination: ContentView(), isActive: $navigateToContentView) {
                            EmptyView()
                        }
                        
                        Button(action: {
                            Task {
                                    do {
                                        try await viewModel.createUser(withEmail: emailfb, password: password, fullName: fullNamefb)
                                    } catch {
                                        // Hatayı sakla
                                        errorMessage = error.localizedDescription
                                    }
                                }
                        }) {
                            Text("Sign Up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        .disabled(!formIsValid)
                        .opacity(formIsValid ? 1.0 : 0.5)

                        /*
                        HStack {
                            Divider()
                                .frame(maxWidth: .infinity, maxHeight: 1)
                                .background(Color.white)
                                .padding(.horizontal)
                            
                            Text("or")
                            
                            Divider()
                                .frame(maxWidth: .infinity, maxHeight: 1)
                                .background(Color.white)
                                .padding(.horizontal)
                        }

                     
                        NavigationLink(destination: SignInView(), isActive: $navigateToSignInView) {
                            EmptyView() // Görünmeyen bir bağlantı
                        }
                        Button(action: {
                            navigateToSignInView = true
                        }) {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        */
                    }
                    .padding()
                    .padding(.top, 30)
                    
                    
                }
                
                
                .foregroundColor(.white)
                .background(Color.darkbrown)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            
        }
        .navigationBarHidden(true)
    }
    
    
    
    
    
}

struct CustomTextFieldSignUpView: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        
        Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    } else {
                        TextField(placeholder, text: $text)
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                }
    }
}

// MARK: -- AuthenticationFormProtocol
extension SignUpView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !emailfb.isEmpty
        && emailfb.contains("@")
        && !password.isEmpty
        && password.count > 5
        && confirmPassword == password
        && !fullNamefb.isEmpty
    }
    
}
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
