//
//  SignInView.swift
//  FlashDecks
//
//  Created by Zerda Yilmaz on 17.11.2024.
//

import SwiftUI
import AuthenticationServices



extension Color {
    static let darkbrown2 = Color(UIColor(red: 27/255.0, green: 25/255.0, blue: 26/255.0, alpha: 1.0))
}
struct SignInView: View {
    @State private var name: String = ""
    @State private var emailfb: String = ""
    @State private var password: String = ""
    @State private var navigateToSignUpView = false
    @State private var navigateToMainMenuView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToForgotPassword = false
    @State private var isSignedIn: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    @AppStorage("email") var email: String = ""
    @AppStorage("firstName") var firstName: String = ""
    @AppStorage("lastName") var lastName: String = ""
    @AppStorage("userId") var userId: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkbrown2
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
                            
                            Text("Sign In")
                            
                            Spacer()
                        }
                    }
                    Spacer()
                    
                    VStack {
                        Image("apple")
                            .resizable()
                            .frame(width: 270,height: 250)
                            .padding(.top,80)
                        Spacer()
                    }
                }
                .padding()
                
                
                VStack(spacing: 15) {
                                      
                    VStack {
                        /*
                         Text("***Yeni*** Bir")
                         .font(.largeTitle)
                         .bold()
                         .foregroundColor(.black)
                         Text("Hesap Oluştur")
                         .font(.largeTitle)
                         .bold()
                         .foregroundColor(.black)
                         */
                        
                    }
                    .padding(.top, 100)
                    
                    
                    VStack {
                        HStack {
                            Image(systemName: "envelope.circle")
                                .font(.system(size: 40))
                            CustomTextField5(placeholder: "Email", text: $emailfb)
                                .autocapitalization(.none)
                        }
                        
                        HStack {
                            Image(systemName: "lock.circle")
                                .font(.system(size: 40))
                            CustomTextField5(placeholder: "Password", text: $password, isSecure: true)
                        }
                    }
                    .padding(.top, 150)
                    
                   /*
                    NavigationLink(destination: SignUpView(), isActive: $navigateToSignUpView) {
                        EmptyView() // Görünmeyen bir bağlantı
                    }
                    Button(action: {
                        navigateToSignUpView = true
                    }) {
                        Text("Already have an account? Sign in here.")
                            .foregroundColor(.white)
                        
                    }
                   */
                    //SIGN IN_LOGIN ACTION HERE
                    NavigationLink(destination: SignUpView(), isActive: $navigateToSignUpView) {
                        EmptyView() // Görünmeyen bir bağlantı
                    }
                    Button(action: {
                        // Sign up action
                        /*
                        Task {
                            try await viewModel.signIn(withEmail: email, password: password)
                        }
                         */
                        
                        Task {
                                            do {
                                                try await viewModel.signIn(withEmail: emailfb, password: password)
                                            } catch let error as SignInError {
                                                alertMessage = error.localizedDescription
                                                showAlert = true
                                            } catch {
                                                alertMessage = error.localizedDescription
                                                showAlert = true
                                            }
                                        }
                    }) {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    /*
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1.0 : 0.5)
                     */
                 
                    
                    NavigationLink(destination: ForgotPasswordView(), isActive: $navigateToForgotPassword) {
                        EmptyView()
                    }
                    Button(action: {
                        navigateToForgotPassword = true
                    }) {
                        Spacer()
                        Text("Forgot password?")
                            .padding()
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(10)
                     
               /*
                    NavigationLink("Sign Up", destination: SignUpView())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
*/
                    
                    

                     
                    NavigationLink(destination: MainMenuView(), isActive: $isSignedIn) {
                        EmptyView()
                    }
/*
                    NavigationLink(destination: ForgotPasswordView(), isActive: $navigateToForgotPassword) {
                        EmptyView()
                    }
                    Button(action: {
                        navigateToForgotPassword = true
                    }) {
                        Spacer()
                        Text("Forgot password?")
                        Spacer()
                    }
*/
                    /*
                    NavigationLink(destination: MainMenuView(), isActive: $navigateToMainMenuView) {
                        EmptyView() // Görünmeyen bir bağlantı
                    }
                    Button(action: {
                        //Action
                        navigateToMainMenuView = true
                    }) {
                        HStack {
                            Text("Continue without registering")
                            
                            
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top, -20)
                    */
                    

                }
                .padding()
                
                .alert(isPresented: $showAlert) {
                            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                    
            
        }
            
            .background(Color.darkbrown)
            .foregroundColor(.white)
        }
        .navigationBarHidden(true)
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

struct CustomTextField2: View {
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
/*
extension SignInView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !emailfb.isEmpty
        && emailfb.contains("@")
        && !password.isEmpty
        && password.count > 5
    }
    
}
 */
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AuthViewModel())
    }
}
