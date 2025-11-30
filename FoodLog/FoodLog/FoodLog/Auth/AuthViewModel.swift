//
//  AuthViewModel.swift
//  FlashDecks
//
//  Created by Zerda Yilmaz on 18.11.2024.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
    
}
enum SignInError: LocalizedError {
    case userNotFound
    case wrongPassword
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "This account does not exist. Please sign up or try a different email."
        case .wrongPassword:
            return "The password is incorrect. Please try again."
        case .unknown(let message):
            return message
        }
    }
}


@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isPremiumUser: Bool = false // Kullanıcının premium durumu

    init() {
        self.userSession = Auth.auth().currentUser
        
        Task {
            await fetchUser()
        }
    }
    
    /*
     func signIn(withEmail email: String, password: String) async throws {
     print("Sign in..")
     do {
     let result = try await Auth.auth().signIn(withEmail: email, password: password)
     self.userSession = result.user
     await fetchUser()
     } catch {
     print("DEBUG: Failed to log in with error \(error.localizedDescription)")
     }
     }
     */
    
    func signIn(withEmail email: String, password: String) async throws {
        print("Sign in..")
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch let error as NSError {
            // Hata durumunu kontrol et
            switch AuthErrorCode(rawValue: error.code) {
            case .userNotFound:
                throw SignInError.userNotFound
            case .wrongPassword:
                throw SignInError.wrongPassword
            default:
                throw SignInError.unknown(error.localizedDescription)
            }
        }
    }
    /* func createUser(withEmail email: String, password: String, fullName: String) async throws {
     print("Create user..")
     
     do {
     let result = try await Auth.auth().createUser(withEmail: email, password: password)
     self.userSession = result.user
     let user = User(id: result.user.uid, fullname: fullName, email: email)
     let encodedUser = try Firestore.Encoder().encode(user)
     try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
     await fetchUser()
     } catch {
     print("DEBUG: Failed to create user with error \(error.localizedDescription)")
     }
     }
     */
    func createUser(withEmail email: String, password: String, fullName: String) async throws {
        print("Create user..")
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let user = User(id: result.user.uid, fullnamefb: fullName, emailfb: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch let error {
            // Hata mesajını UI'ye aktar
            throw error
        }
    }
    
    func signOut() {
        print("Signig Out..")
        
        do {
            try Auth.auth().signOut() // signs out user on backend
            self.userSession = nil // wipes out user session and takes us to login screen
            self.currentUser = nil // wipes out current user data model
        } catch {
            print("DEBUG: Failed to sign out with error \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async {
        print("Deleting Account...")
        guard let user = Auth.auth().currentUser else {
            print("DEBUG: No user found")
            return
        }
        
        do {
            // Firestore'daki kullanıcı verilerini sil
            await deleteFirestoreUserData(userId: user.uid)
            
            // Kullanıcıyı Authentication'dan sil
            try await user.delete()
            print("DEBUG: User account deleted successfully")
            
            // Kullanıcı oturum bilgilerini sıfırla
            self.userSession = nil
            self.currentUser = nil
        } catch let error as NSError {
            print("DEBUG: Error deleting account: \(error.localizedDescription)")
            
            // Eğer kullanıcı oturum açma gereksinimi yüzünden silinemiyorsa
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                print("DEBUG: Requires recent login. Reauthenticate user.")
            }
        }
    }
    func deleteFirestoreUserData(userId: String) async {
        do {
            try await Firestore.firestore().collection("users").document(userId).delete()
            print("DEBUG: User Firestore data deleted successfully")
        } catch {
            print("DEBUG: Failed to delete user Firestore data with error \(error.localizedDescription)")
        }
    }
    
    func fetchUser() async {
        print("Fetching Users...")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
        self.currentUser = try? snapshot.data(as: User.self)
        
        print("DEBUG: Current user is \(self.currentUser)")
    }
    
    func updateUserProfile(fullName: String, email: String) async throws {
        guard let userId = userSession?.uid else { return }
        
        // Firebase Authentication e-posta güncelleme
        if email != userSession?.email {
            try await userSession?.updateEmail(to: email)
        }
        
        // Firestore'daki kullanıcı verilerini güncelle
        let updatedUser = User(id: userId, fullnamefb: fullName, emailfb: email)
        let encodedUser = try Firestore.Encoder().encode(updatedUser)
        try await Firestore.firestore().collection("users").document(userId).updateData(encodedUser)
        
        // Local currentUser güncellemesi
        DispatchQueue.main.async {
            self.currentUser = updatedUser
        }
        print("DEBUG: User profile updated successfully!")
    }
    
    /// Kullanıcıya yeni e-posta için doğrulama e-postası gönderir.
    func sendVerificationEmail(to newEmail: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw SignInError.userNotFound
        }
        try await currentUser.updateEmail(to: newEmail)
        try await currentUser.sendEmailVerification()
        print("Verification email sent to \(newEmail)")
    }
    
    /// Kullanıcının doğrulama durumunu kontrol eder.
    func reloadUserAndCheckEmailVerification() async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            throw SignInError.userNotFound
        }
        try await currentUser.reload()
        return currentUser.isEmailVerified
    }
   
    func signInAnonymously() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            self.userSession = result.user
            self.currentUser = User(id: result.user.uid, fullnamefb: "Guest", emailfb: "guest@anon.com")
            print("✅ Signed in anonymously with UID:", result.user.uid)
        } catch {
            print("🔥 Failed to sign in anonymously:", error.localizedDescription)
        }
    }

    
}

extension AuthViewModel {
    func reauthenticateUser(currentPassword: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw SignInError.userNotFound
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        try await user.reauthenticate(with: credential)
        print("DEBUG: User reauthenticated successfully!")
    }

    func updatePassword(currentPassword: String, newPassword: String) async throws {
        do {
            // Kullanıcıyı mevcut şifre ile yeniden doğrula
            try await reauthenticateUser(currentPassword: currentPassword)
            
            // Kullanıcıyı yeniden doğruladıktan sonra yeni şifreyi güncelle
            guard let user = Auth.auth().currentUser else {
                throw SignInError.userNotFound
            }
            try await user.updatePassword(to: newPassword)
            print("DEBUG: Password updated successfully!")
        } catch let error as NSError {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                throw SignInError.unknown("This operation is sensitive and requires recent authentication. Please log in again.")
            } else if error.code == AuthErrorCode.wrongPassword.rawValue {
                throw SignInError.unknown("The current password you entered is incorrect. Please try again.")
            } else {
                throw SignInError.unknown(error.localizedDescription)
            }
        }
    }
}
