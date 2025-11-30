//
//  ForgotPasswordView.swift
//  YKS TYT AYT Deneme Buddy
//
//  Created by Zerda Yilmaz on 15.10.2024.
//

import SwiftUI
import FirebaseAuth


struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var navigateToSignUpView = false
    @State private var navigateToContentView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                Color(red: 193/255, green: 163/255, blue: 143/255)
                .edgesIgnoringSafeArea(.all)
                
                
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                        }
                       
                        HStack {
                            Spacer()
                            
                            Text("Sign In")
                                .foregroundColor(.black)
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .padding()
                
                VStack(alignment: .leading) {
                    VStack {
                        HStack {
                            CustomTextField(placeholder: "Email", text: $email)
                        }
                        
                       
                        Button(action: {
                            if email.isEmpty {
                                // Eğer e-posta adresi boşsa uyarı göster
                                print("Please enter an email address")
                                return
                            }

                            // Şifre sıfırlama e-postası gönder
                            sendPasswordResetEmail(to: email) { result in
                                switch result {
                                case .success:
                                    print("Password reset email sent successfully!")
                                    alertMessage = "Password reset email sent to \(email)"
                                    showAlert = true
                                case .failure(let error):
                                    print("Error sending password reset email: \(error.localizedDescription)")
                                    alertMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
                        }){
                            Text("Send")
                                .padding()
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.black, lineWidth: 1)
                                )
                        }
                        .padding(.top, 10)
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                        
                        
                        NavigationLink(destination: SignInView(), isActive: $navigateToSignUpView) {
                            EmptyView() // Görünmeyen bir bağlantı
                        }
                        Button(action: {
                            //
                            navigateToSignUpView = true
                        }) {
                            Text("Remember your password? Log in now.")
                                .foregroundColor(.black)
                                
                        }
                        .padding(.top, 20)
                        
                    }
                    .padding(.top, 100)
                    
                }
                .foregroundColor(.black)
                .padding()
                .padding(.top, 150)
                
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func sendPasswordResetEmail(to email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error)) // Eğer hata varsa
            } else {
                completion(.success(())) // Başarılı olduysa
            }
        }
    }

}

struct CustomTextFieldForgotPasswordView: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.white.opacity(0.5))
            .cornerRadius(10)
            .foregroundColor(.black)
    }
}


#Preview {
    ForgotPasswordView()
}
