//
//  ProfileView.swift
//  FoodLog
//
//  Created by Zerda Yilmaz on 22.05.2025.
//

import Kingfisher
import Firebase
import FirebaseStorage
import SwiftUI

struct ProfileView: View {
    //navigations
    @State private var showUpdateProfile = false
    @State private var navigateToSettingsView = false
    
    //image
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: URL? = nil
    @State private var isImagePickerPresented = false
    
    //
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isWorking = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    
    @State private var isPremiumToggle = false
    
    @State private var navigateToPaywall = false
    
    @State private var showEditNameSheet = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var photoButtonLabel: String {
        if selectedImage != nil {
            return "Update Profile Photo"
        } else if let url = authViewModel.currentUser?.profileImageURL, !url.isEmpty {
            return "Update Profile Photo"
        } else {
            return "Add Profile Photo"
        }
    }
    var body: some View {
        ZStack(alignment: .topLeading) {
            ColorPalette.Green5
                .edgesIgnoringSafeArea(.all)
            Image("fruit")
                .resizable()
                .scaledToFit()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                VStack {
                    /*
                     NavigationLink(destination: SettingsView(), isActive: $navigateToSettingsView) {
                     Button {
                     navigateToSettingsView = true
                     } label: {
                     Image(systemName: "gear")
                     .font(.system(size: 20))
                     .foregroundColor(.black)
                     }
                     }
                     */
                    //
                    VStack {
                        
                        //profile picture, name, email
                        VStack {
                            HStack {
                                Spacer()
                                VStack {
                                    if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    } else if let urlString = authViewModel.currentUser?.profileImageURL,
                                              let url = URL(string: urlString) {
                                        KFImage(url)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    } else if let initials = authViewModel.currentUser?.initials {
                                        Circle()
                                            .fill(ColorPalette.Green5)
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                Text(initials)
                                                    .font(.title)
                                                    .foregroundColor(ColorPalette.Green6)
                                            )
                                    }
                                    else  {
                                        Circle()
                                            .fill(ColorPalette.Green5)
                                            .frame(width: 80, height: 80)
                                    }
                                    
                                    Button(action: {
                                        isImagePickerPresented = true
                                    }) {
                                        Text(photoButtonLabel)
                                            .padding(.top)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                .padding(.leading,35)
                                
                                Spacer()
                                
                                VStack {
                                    Menu {
                                        Button {
                                            showLogoutConfirm = true
                                        } label: {
                                            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                                        }
                                        
                                        Button(role: .destructive) {
                                            showDeleteConfirm = true
                                        } label: {
                                            Label("Delete account", systemImage: "trash")
                                        }
                                        
                                        Button {
                                                showEditNameSheet = true
                                            } label: {
                                                Label("Edit Fullname", systemImage: "pencil")
                                            }
                                        
                                    } label: {
                                        // ETİKET: daha büyük ve “dokunması kolay” bir buton görünümü
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 18, weight: .semibold))
                                            .padding(8)
                                            .foregroundColor(ColorPalette.Green5)
                                    }
                                    .sheet(isPresented: $showEditNameSheet) {
                                        EditNameView()
                                            .environmentObject(authViewModel)
                                    }
                                    
                                    
                                    Spacer()
                                }
                                .confirmationDialog("Log out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                                    Button("Log out", role: .destructive) {
                                        isWorking = true
                                        Task {
                                            do {
                                                authViewModel.signOut()
                                            }
                                            isWorking = false
                                        }
                                    }
                                    Button("Cancel", role: .cancel) {}
                                }
                                
                                .confirmationDialog("Delete account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                                    Button("Delete account", role: .destructive) {
                                        isWorking = true
                                        Task {
                                            do {
                                                await authViewModel.deleteAccount()
                                            } catch {
                                                errorMessage = error.localizedDescription
                                                showErrorAlert = true
                                            }
                                            isWorking = false
                                        }
                                    }
                                    Button("Cancel", role: .cancel) {}
                                } message: {
                                    Text("This action can’t be undone. Your data will be permanently removed.")
                                }
                                
                            }
                            .padding(.bottom)
                            
                            
                            HStack {
                                Spacer()
                                VStack() {
                                    Text(authViewModel.currentUser?.fullnamefb ?? "Fullname")
                                        .font(.headline)
                                        .foregroundColor(ColorPalette.Green5)
                                    Text(authViewModel.currentUser?.emailfb ?? "Email")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .frame(height: 250)
                        .background(ColorPalette.Green6.opacity(0.9))
                        .cornerRadius(16)
                        
                    }
                    UpdateProfileView()
                    
                }

                // Premium kartı / Buton
                if !(authViewModel.currentUser?.isPremium ?? false) {
                    Button {
                        navigateToPaywall = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.open.fill")
                            Text("Unlock Full Access")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorPalette.Green6)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                
            }
            .frame(maxHeight: .infinity)
            .padding()
        }
        .sheet(isPresented: $navigateToPaywall) {
            PaywallView(isPremiumToggle: $isPremiumToggle)
                .environmentObject(authViewModel) // Paywall’ın ihtiyaç duyduğu AuthViewModel
        }
        .alert("Error", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage)
        })
        .overlay {
            if isWorking {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Working…")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .opacity(0.9)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            guard newImage != nil else { return }
            isWorking = true
            uploadProfileImage()
        }
    }
    func uploadProfileImage() {
        guard let image = selectedImage,
              let uid = authViewModel.userSession?.uid,
              let imageData = image.jpegData(compressionQuality: 0.4) else { return }

        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload error: \(error)")
                return
            }

            // ✅ Güvenli downloadURL alma
            getDownloadURLWithRetry(ref: storageRef) { url in
                guard let downloadURL = url else { return }

                Firestore.firestore().collection("users").document(uid).updateData([
                    "profileImageURL": downloadURL.absoluteString
                ]) { error in
                    if let error = error {
                        print("Firestore update error: \(error)")
                        return
                    }

                    print("✅ profileImageURL stored: \(downloadURL.absoluteString)")
                    Task {
                        await authViewModel.fetchUser()
                    }
                }
            }
        }
    }
    func getDownloadURLWithRetry(ref: StorageReference, retryCount: Int = 3, delay: TimeInterval = 0.5, completion: @escaping (URL?) -> Void) {
        ref.downloadURL { url, error in
            if let url = url {
                completion(url)
            } else if retryCount > 0 {
                print("Retrying downloadURL in \(delay)s...")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    getDownloadURLWithRetry(ref: ref, retryCount: retryCount - 1, delay: delay * 2, completion: completion)
                }
            } else {
                print("DownloadURL retry failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
}
#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

struct UpdateProfileView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = "********"
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showSuccessMessage = false
    @State private var showAlertMessage = false
    @State private var showPasswordUpdating = false
    @State private var isPasswordEditable: Bool = false
    @State private var showSuccessMessage2 = false
    @State private var showHeartLoading = false
    @State private var showErrorMessage = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss // NavigationStack geri dönüşü için
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
                VStack(alignment: .leading) {
              
                    VStack(alignment: .leading) {
                    // Kullanıcının e-maili
                    Text("E-mail")
                    CustomTextField7(
                        placeholder: "E-mail",
                        text: $email
                    )
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                        
                    Button {
                        Task {
                            do {
                                try await viewModel.updateUserProfile(fullName: name, email: email)
                                showSuccessMessage = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showSuccessMessage = false
                                }
                            } catch {
                                showAlertMessage = true
                                print("DEBUG: Failed to update profile: \(error.localizedDescription)")
                            }
                        }
                    } label: {
                        HStack {
                            Text("Update Mail")
                        }
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ColorPalette.Green5, lineWidth: 1)
                        )
                    }
                        if showSuccessMessage {
                                                    Text("Profile updated successfully!")
                                .foregroundColor(Color.white)
                                                        .bold()
                                                        .padding()
                                                }
                        if showAlertMessage {
                            Text("Please check your informations and try again.")
        .foregroundColor(Color.white)
                                .bold()
                                .padding()
                        }
                        
                        
                        if !showPasswordUpdating {
                            // Kullanıcının şifresi
                            Text("Password")
                            CustomTextField7(
                                placeholder: "Password",
                                text: $password
                            )
                            .disabled(true)
                            

                            Button {
                                showPasswordUpdating = true
                            } label: {
                                HStack {
                                    Text("Update Password")
                                }
                                .padding(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(ColorPalette.Green5, lineWidth: 1)
                                )
                            }
                            
                        }
                        if showPasswordUpdating {
                            // Kullanıcının şifresi
                            CustomTextField(placeholder: "Current Password", text: $currentPassword, isSecure: true)
                                                        

                            CustomTextField(placeholder: "New Password", text: $newPassword, isSecure: true)
                                                        
                            
                            CustomTextField(placeholder: "Confirm New Password", text: $confirmPassword, isSecure: true)
                                                        
                            
                            Button {
                                Task {
                                                                if newPassword == confirmPassword {
                                                                    do {
                                                                        try await viewModel.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
                                                                        showSuccessMessage = true
                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                                            showSuccessMessage2 = false
                                                                        }
                                                                    } catch {
                                                                        showErrorMessage = true
                                                                        errorMessage = error.localizedDescription
                                                                    }
                                                                } else {
                                                                    showErrorMessage = true
                                                                    errorMessage = "New passwords do not match!"
                                                                }
                                                            }
                            } label: {
                                HStack {
                                    Text("Update Password")
                                }
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(ColorPalette.Green5, lineWidth: 1)
                                )
                            }
                            if showSuccessMessage2 {
                                                        Text("Password updated successfully!")
                                                            .foregroundColor(.green)
                                                            .bold()
                                                            .padding()
                                                    }

                                                    if showErrorMessage {
                                                        Text(errorMessage)
                                                            .bold()
                                                            .padding()
                                                    }
                            
                        }
                        
                    }
                    .padding()
                    .foregroundColor(ColorPalette.Green5)
                    .background(ColorPalette.Green6)
                    .cornerRadius(20)
                }
                .onAppear {
                            Task {
                                do {
                                    try await viewModel.fetchUser()
                                    name = viewModel.currentUser?.fullnamefb ?? ""
                                    email = viewModel.currentUser?.emailfb ?? ""
                                } catch {
                                    print("DEBUG: Failed to fetch user data: \(error.localizedDescription)")
                                }
                            }
                        }
    }
}

/*
 //
 //  ProfileView.swift
 //  FoodLog
 //
 //  Created by Zerda Yilmaz on 22.05.2025.
 //

 import Kingfisher
 import Firebase
 import FirebaseStorage
 import SwiftUI

 struct ProfileView: View {
     
     //navigations
     @State private var showUpdateProfile = false
     @State private var navigateToSettingsView = false
     
     //image
     @State private var selectedImage: UIImage? = nil
     @State private var imageURL: URL? = nil
     @State private var isImagePickerPresented = false
     
     
     @EnvironmentObject var authViewModel: AuthViewModel
     
     var photoButtonLabel: String {
         if selectedImage != nil {
             return "Update Profile Photo"
         } else if let url = authViewModel.currentUser?.profileImageURL, !url.isEmpty {
             return "Update Profile Photo"
         } else {
             return "Add Profile Photo"
         }
     }
     
     var body: some View {
         NavigationStack {
         ZStack(alignment: .topLeading) {
             ColorPalette.Green5.opacity(0.8)
                 .edgesIgnoringSafeArea(.all)
             
             VStack {
                 
                 //
                 HStack {
                     HStack(alignment: .center, spacing: 16) {
                         if let selectedImage = selectedImage {
                             Image(uiImage: selectedImage)
                                 .resizable()
                                 .scaledToFill()
                                 .frame(width: 120, height: 120)
                                 .clipShape(Circle())
                         } else if let urlString = authViewModel.currentUser?.profileImageURL,
                                   let url = URL(string: urlString) {
                             KFImage(url)
                                 .resizable()
                                 .scaledToFill()
                                 .frame(width: 120, height: 120)
                                 .clipShape(Circle())
                         } else if let initials = authViewModel.currentUser?.initials {
                             Circle()
                                 .fill(ColorPalette.Green1)
                                 .frame(width: 120, height: 120)
                                 .overlay(
                                     Text(initials)
                                         .font(.title)
                                         .foregroundColor(.white)
                                 )
                         }
                         
                         Button(action: {
                             isImagePickerPresented = true
                         }) {
                             Text(photoButtonLabel)
                                 .padding(.top)
                                 .font(.system(size: 15))
                                 .foregroundColor(ColorPalette.Green1)
                         }
                         
                         VStack(alignment: .leading, spacing: 4) {
                             Text(authViewModel.currentUser?.fullnamefb ?? "")
                                 .font(.headline)
                             Text(authViewModel.currentUser?.emailfb ?? "")
                                 .font(.subheadline)
                                 .foregroundColor(.gray)
                         }
                         
                         Spacer()
                         
                         NavigationLink(destination: SettingsView(), isActive: $navigateToSettingsView) {
                             Button {
                                 navigateToSettingsView = true
                             } label: {
                                 Image(systemName: "gear")
                                     .font(.system(size: 20))
                                     .foregroundColor(.black)
                             }
                         }
                         
                     }
                 }
                 UpdateProfileView()
                 
             }
             .padding()
             
         }
     }
     }
 }

 struct UpdateProfileView: View {
     @State private var name: String = ""
     @State private var email: String = ""
     @State private var password: String = "********"
     @State private var currentPassword: String = ""
     @State private var newPassword: String = ""
     @State private var confirmPassword: String = ""
     @State private var showSuccessMessage = false
     @State private var showAlertMessage = false
     @State private var showPasswordUpdating = false
     @State private var isPasswordEditable: Bool = false
     @State private var showSuccessMessage2 = false
     @State private var showHeartLoading = false
     @State private var showErrorMessage = false
     @State private var errorMessage = ""
     
     @Environment(\.dismiss) private var dismiss // NavigationStack geri dönüşü için
     @EnvironmentObject var viewModel: AuthViewModel
     var body: some View {
                 VStack(alignment: .leading) {
               
                     VStack(alignment: .leading) {
                     Text("Update your profile")
                         .italic()
                         .padding(.bottom)
                     // Kullanıcının e-maili
                     Text("E-mail")
                     CustomTextField4(
                         placeholder: "E-mail",
                         text: $email
                     )
                     .autocorrectionDisabled()
                     .autocapitalization(.none)
                         
                     Button {
                         Task {
                             do {
                                 try await viewModel.updateUserProfile(fullName: name, email: email)
                                 showSuccessMessage = true
                                 DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                     showSuccessMessage = false
                                 }
                             } catch {
                                 showAlertMessage = true
                                 print("DEBUG: Failed to update profile: \(error.localizedDescription)")
                             }
                         }
                     } label: {
                         HStack {
                             Text("Update Mail")
                         }
                         .padding()
                         .foregroundColor(.black)
                         .overlay(
                             RoundedRectangle(cornerRadius: 16)
                                 .stroke(.black, lineWidth: 1)
                         )
                     }
                         if showSuccessMessage {
                                                     Text("Profile updated successfully!")
                                 .foregroundColor(Color.black)
                                                         .bold()
                                                         .padding()
                                                 }
                         if showAlertMessage {
                             Text("Please check your informations and try again.")
         .foregroundColor(Color.black)
                                 .bold()
                                 .padding()
                         }
                         
                         
                         if !showPasswordUpdating {
                             // Kullanıcının şifresi
                             Text("Password")
                             CustomTextField4(
                                 placeholder: "Password",
                                 text: $password
                             )
                             .disabled(true)
                             

                             Button {
                                 showPasswordUpdating = true
                             } label: {
                                 HStack {
                                     Text("Update Password")
                                 }
                                 .padding()
                                 .foregroundColor(.black)
                                 .overlay(
                                     RoundedRectangle(cornerRadius: 16)
                                         .stroke(.black, lineWidth: 1)
                                 )
                             }
                             
                         }
                         if showPasswordUpdating {
                             // Kullanıcının şifresi
                             CustomTextField(placeholder: "Current Password", text: $currentPassword, isSecure: true)
                                                         

                             CustomTextField(placeholder: "New Password", text: $newPassword, isSecure: true)
                                                         
                             
                             CustomTextField(placeholder: "Confirm New Password", text: $confirmPassword, isSecure: true)
                                                         
                             
                             Button {
                                 Task {
                                                                 if newPassword == confirmPassword {
                                                                     do {
                                                                         try await viewModel.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
                                                                         showSuccessMessage = true
                                                                         DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                                             showSuccessMessage2 = false
                                                                         }
                                                                     } catch {
                                                                         showErrorMessage = true
                                                                         errorMessage = error.localizedDescription
                                                                     }
                                                                 } else {
                                                                     showErrorMessage = true
                                                                     errorMessage = "New passwords do not match!"
                                                                 }
                                                             }
                             } label: {
                                 HStack {
                                     Text("Update Password")
                                 }
                                 .padding()
                                 .foregroundColor(.black)
                                 .overlay(
                                     RoundedRectangle(cornerRadius: 16)
                                         .stroke(.black, lineWidth: 1)
                                 )
                             }
                             if showSuccessMessage2 {
                                                         Text("Password updated successfully!")
                                                             .foregroundColor(.green)
                                                             .bold()
                                                             .padding()
                                                     }

                                                     if showErrorMessage {
                                                         Text(errorMessage)
                                                             .foregroundColor(Color.black)
                                                             .bold()
                                                             .padding()
                                                     }
                             
                         }
                         
                     }
                     .padding()
                     .foregroundColor(.black)
                     .background(ColorPalette.Green4.opacity(0.5))
                     .cornerRadius(20)
                 }
                 .onAppear {
                             Task {
                                 do {
                                     try await viewModel.fetchUser()
                                     name = viewModel.currentUser?.fullnamefb ?? ""
                                     email = viewModel.currentUser?.emailfb ?? ""
                                 } catch {
                                     print("DEBUG: Failed to fetch user data: \(error.localizedDescription)")
                                 }
                             }
                         }
     }
 }

 struct SettingsView: View {
     
     @EnvironmentObject var viewModel: AuthViewModel
     @Environment(\.dismiss) private var dismiss
     
     var body: some View {
         NavigationStack {
             ZStack(alignment: .topLeading) {
                 ColorPalette.Green5.opacity(0.8)
                     .edgesIgnoringSafeArea(.all)
             VStack {
                //header
                 HStack {
                     Button {
                       dismiss()
                     } label: {
                       Image(systemName: "chevron.left")
                     }

                     Spacer()
                     
                     Text("Settings")
                         .padding(.trailing)
                     
                     Spacer()
                     
                 }
                 .padding(5)
                 .font(.system(size: 20))
                 .foregroundColor(ColorPalette.Green1)
                 .overlay(RoundedRectangle(cornerRadius: 16).stroke(.black,lineWidth: 2))
                 
                 //view
                 VStack {
                     
                     
                     //
                     HStack {
                         Button(action: {
                             viewModel.signOut()
                         }) {
                             Text("Log out")
                                 .padding()
                                 .font(.title3)
                                 .foregroundColor(.red)
                                 .frame(height: 34)
                                 .background(.red.opacity(0.3))
                                 .cornerRadius(12)
                         }
                         
                         Spacer()
                     }
                     
                     HStack {
                         Button(action: {
                             Task {
                                 await viewModel.deleteAccount()
                             }
                         }) {
                             Text("Delete account")
                                 .padding()
                                 .font(.title3)
                                 .foregroundColor(.red)
                                 .frame(height: 34)
                                 .background(.red.opacity(0.3))
                                 .cornerRadius(12)
                         }
                         Spacer()
                     }
                     .padding(.vertical)
                 }
                 
             }
             .padding()
         }
     }
         .navigationBarBackButtonHidden(true)
     }
 }

 #Preview {
     ProfileView()
         .environmentObject(AuthViewModel())
 }

 #Preview {
     SettingsView()
         .environmentObject(AuthViewModel())
 }

 */

struct SettingsView: View {
    
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                ColorPalette.Green5.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
            VStack {
               //header
                HStack {
                    Button {
                      dismiss()
                    } label: {
                      Image(systemName: "chevron.left")
                    }

                    Spacer()
                    
                    Text("Settings")
                        .padding(.trailing)
                    
                    Spacer()
                    
                }
                .padding(5)
                .font(.system(size: 20))
                .foregroundColor(ColorPalette.Green1)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.black,lineWidth: 2))
                
                //view
                VStack {
                    
                    
                    //
                    HStack {
                        Button(action: {
                            viewModel.signOut()
                        }) {
                            Text("Log out")
                                .padding()
                                .font(.title3)
                                .foregroundColor(.red)
                                .frame(height: 34)
                                .background(.red.opacity(0.3))
                                .cornerRadius(12)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Button(action: {
                            Task {
                                await viewModel.deleteAccount()
                            }
                        }) {
                            Text("Delete account")
                                .padding()
                                .font(.title3)
                                .foregroundColor(.red)
                                .frame(height: 34)
                                .background(.red.opacity(0.3))
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
            }
            .padding()
        }
    }
        .navigationBarBackButtonHidden(true)
    }
}

struct CustomTextField7: View {
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
                .background(ColorPalette.Green5)
                .cornerRadius(10)
                .foregroundColor(.black)
        } else {
            TextField(placeholder, text: $text)
                .onChange(of: text) { newValue in
                    text = newValue.lowercased()
                }
                .padding()
                .background(ColorPalette.Green5)
                .cornerRadius(10)
                .foregroundColor(.black)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditNameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorPalette.Green6
                    .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Enter New Fullname")
                        .foregroundColor(.white)
                    TextField("", text: $newName)
                        .padding()
                        .foregroundColor(.white)
                        .background(.white.opacity(0.5))
                        .cornerRadius(10)
                        .accentColor(.black)
                }
                if let error = errorMessage {
                    Text(error).foregroundColor(.red).font(.footnote)
                }
                
                Button {
                    Task {
                        await saveName()
                    }
                } label: {
                  Text("Save")
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 2))
                }
                
            }
            .padding()
        }
        }
        .onAppear {
            newName = authViewModel.currentUser?.fullnamefb ?? ""
        }
    }
    
    private func saveName() async {
        guard let uid = authViewModel.userSession?.uid else { return }
        isSaving = true
        do {
            try await Firestore.firestore().collection("users").document(uid).updateData([
                "fullnamefb": newName
            ])
            await authViewModel.fetchUser()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

