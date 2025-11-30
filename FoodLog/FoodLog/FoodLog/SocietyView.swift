//
//  SocietyView.swift
//  FoodLog
//
//  Created by Zerda Yılmaz on 26.08.2025.
//
import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI
import Kingfisher
import UIKit

struct SocietyView: View {
    
    @StateObject private var viewModel = SocietyViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            ColorPalette.Green5
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                // Posts List
                if viewModel.isLoading {
                    ProgressView("Loading posts...")
                        .padding()
                } else if viewModel.posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(ColorPalette.Green6.opacity(0.5))
                        Text("No posts yet")
                            .font(.headline)
                            .foregroundColor(ColorPalette.Green6.opacity(0.7))
                        Text("Be the first to share something with the community!")
                            .font(.subheadline)
                            .foregroundColor(ColorPalette.Green6.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                PostCardView(post: post, userOverride: viewModel.userLookup[post.userId])
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showNewPostSheet) {
            NewPostView(viewModel: viewModel)
        }
        .refreshable {
                    await viewModel.fetchPosts()
                    await viewModel.fetchPostingUsers()   // ✅ refresh’te de güncelle
                }
                .onReceive(NotificationCenter.default.publisher(for: .showNewPostSheet).receive(on: RunLoop.main)) { _ in
                    viewModel.showNewPostSheet = true
                }
                .onAppear {
                    Task { await viewModel.fetchPostingUsers() }   // ✅ ekran açılınca çek
                }
                .onChange(of: Set(viewModel.posts.map(\.userId))) { _ in
                    Task { await viewModel.fetchPostingUsers() }
                }
                .environmentObject(viewModel)


    }
}

struct PostCardView: View {
    let post: Post
    let userOverride: User?
    
    @State private var isLiked = false
    @State private var likeCount: Int
    
    @State private var showPostView = false
    @State private var commentCount: Int
    
    @State private var showShareSheet = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    init(post: Post, userOverride: User? = nil) {
            self.post = post
            self.userOverride = userOverride
            _commentCount = State(initialValue: post.comments)
            _likeCount    = State(initialValue: post.likes)
        }
    
    var body: some View {
        let displayName = userOverride?.fullnamefb ?? post.userFullName
        let displayImageURL = userOverride?.profileImageURL ?? post.userProfileImageURL
        VStack(alignment: .leading, spacing: 12) {
            // User info and timestamp
            HStack(alignment: .center, spacing: 12) {
                if let urlStr = displayImageURL, !urlStr.isEmpty, let url = URL(string: urlStr) {
                                    KFImage(url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(ColorPalette.Green6)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Text(initials(from: displayName))
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                        )
                                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                                            .font(.headline)
                                            .foregroundColor(ColorPalette.Green6)
                                        Text(post.relativeDate)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Post content
            Text(post.content)
                .font(.body)
                .foregroundColor(ColorPalette.Green6)
                .multilineTextAlignment(.leading)
            
            // Like and comment buttons
            HStack(spacing: 16) {
                
                Button(action: { showPostView = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("\(commentCount)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                
                Button(action: { toggleLike() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isLiked ? "heart.fill" : "heart")
                                        Text("\(likeCount)")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(isLiked ? .pink : .gray) // isteğe göre palette
                                }
                
                Spacer()
                
                Button(action: {
                    // Share action
                    showShareSheet = true
                }) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(ColorPalette.Green6.opacity(0.1))
        .cornerRadius(12)
        .onAppear { loadIsLiked() }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.Green6.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showPostView) {
            PostView(post: post) { delta in
                commentCount = max(0, commentCount + delta)
            }
            .environmentObject(authViewModel)
        }
        .onTapGesture {
            showPostView = true
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems())
        }
    }
    private func loadIsLiked() {
        guard let uid = authViewModel.currentUser?.id else { return }
        let likeRef = Firestore.firestore()
            .collection("posts").document(post.id)
            .collection("likes").document(uid)

        likeRef.getDocument { snap, _ in
            isLiked = snap?.exists ?? false
        }

        // (opsiyonel) canlı like sayacı dinlemek için:
        // Firestore.firestore().collection("posts").document(post.id)
        //   .addSnapshotListener { doc, _ in
        //       likeCount = (doc?.data()?["likes"] as? Int) ?? likeCount
        //   }
    }

    private func initials(from fullName: String) -> String {
        let parts = fullName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
    
    private func toggleLike() {
        guard let uid = authViewModel.currentUser?.id else { return }

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(post.id)
        let likeRef = postRef.collection("likes").document(uid)

        // Transaction ile atomik sayaç + like/unlike
        db.runTransaction({ (transaction, errPtr) -> Any? in
            do {
                let postSnap = try transaction.getDocument(postRef)
                let current = (postSnap.data()?["likes"] as? Int) ?? 0

                if isLiked {
                    // UNLIKE
                    transaction.updateData(["likes": max(0, current - 1)], forDocument: postRef)
                    transaction.deleteDocument(likeRef)
                } else {
                    // LIKE
                    transaction.updateData(["likes": current + 1], forDocument: postRef)
                    transaction.setData([
                        "userId": uid,
                        "createdAt": FieldValue.serverTimestamp()
                    ], forDocument: likeRef)
                }
            } catch let e as NSError {
                errPtr?.pointee = e
                return nil
            }
            return nil
        }, completion: { _, error in
            if error == nil {
                // Optimistic UI
                if isLiked {
                    isLiked = false
                    likeCount = max(0, likeCount - 1)
                } else {
                    isLiked = true
                    likeCount += 1
                }
            } else {
                print("Like toggle failed: \(error!.localizedDescription)")
            }
        })
    }

    private func shareItems() -> [Any] {
        let name = userOverride?.fullnamefb ?? post.userFullName  // displayName'i burada yeniden çöz
        let date = post.formattedDate
        let text = """
        \(name) shared on FoodLog:
        “\(post.content)”
        \(date)
        """
        return [text]
    }

    
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PostView: View {
    let post: Post
    let onCommentAdded: (() -> Void)? = nil
    let onCommentCountChange: ((Int) -> Void)?
    
    @EnvironmentObject var feedVM: SocietyViewModel
    @State private var showDeletePostDialog = false

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var commentsVM: CommentsViewModel

    @State private var isPostLiked = false
    @State private var postLikeCount: Int
    
    init(post: Post, onCommentCountChange: ((Int) -> Void)? = nil) {
            self.post = post
            self.onCommentCountChange = onCommentCountChange
            _commentsVM = StateObject(wrappedValue: CommentsViewModel(postId: post.id))
            _postLikeCount = State(initialValue: post.likes)
        }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ColorPalette.Green5.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(ColorPalette.Green6)
                    }
                    Spacer()
                    Text("Post")
                        .font(.headline)
                        .foregroundColor(ColorPalette.Green6)
                    Spacer()

                    // ✅ SADECE SAHİBİNE GÖRÜNSÜN
                    if authViewModel.currentUser?.id == post.userId {
                        Button {
                            showDeletePostDialog = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    } else {
                        Image(systemName: "chevron.left").opacity(0) // denge için placeholder
                    }
                }
                .confirmationDialog("Delete this post?",
                    isPresented: $showDeletePostDialog,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        Task { await deletePostCascade() }
                    }
                    Button("Cancel", role: .cancel) {}
                }

                
                // İçerik
                VStack(alignment: .leading, spacing: 8) {
                    // Kullanıcı ve tarih
                    HStack(spacing: 12) {
                        if let urlStr = post.userProfileImageURL, let url = URL(string: urlStr) {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(ColorPalette.Green6.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(post.userFullName.prefix(2).uppercased())
                                        .font(.subheadline)
                                        .foregroundColor(ColorPalette.Green6)
                                )
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.userFullName)
                                .font(.headline)
                                .foregroundColor(ColorPalette.Green6)
                            Text(post.formattedDate) // veya post.relativeDate
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                    }
                    
                    Text(post.content)
                        .font(.body)
                        .foregroundColor(ColorPalette.Green6)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Spacer()
                        Button(action: { togglePostLike() }) {
                            HStack(spacing: 4) {
                                Image(systemName: isPostLiked ? "heart.fill" : "heart")
                                Text("\(postLikeCount)")
                            }
                            .font(.subheadline)
                            .foregroundColor(isPostLiked ? .pink : .gray)
                        }
                    }
                    
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ColorPalette.Green6.opacity(0.1))
                .cornerRadius(12)
                
                // MARK: - Comments Section
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Comments")
                                            .font(.headline)
                                            .foregroundColor(ColorPalette.Green6)
                                        Spacer()
                                        if !commentsVM.comments.isEmpty {
                                            Text("\(commentsVM.comments.count)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    if commentsVM.isLoading {
                                        ProgressView("Loading comments…")
                                            .foregroundColor(.gray)
                                    } else if commentsVM.comments.isEmpty {
                                        Text("No comments yet.")
                                            .foregroundColor(ColorPalette.Green6.opacity(0.7))
                                            .padding(.vertical, 6)
                                    } else {
                                        ScrollView {
                                            LazyVStack(alignment: .leading, spacing: 12) {
                                                ForEach(commentsVM.comments) { c in
                                                    CommentRow(comment: c, onDeleted: {
                                                        onCommentCountChange?(-1)
                                                    })
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        .frame(maxHeight: 300)
                                    }

                                    // Add comment input
                                    HStack(alignment: .bottom, spacing: 8) {
                                        TextField("Add a comment…", text: $commentsVM.newComment, axis: .vertical)
                                            .lineLimit(1...4)
                                            .padding(10)
                                            .background(ColorPalette.Green6.opacity(0.1))
                                            .cornerRadius(10)

                                        Button {
                                            Task {
                                                    if let user = authViewModel.currentUser {
                                                        try? await commentsVM.addComment(user: user)
                                                        onCommentCountChange?(1)  // +1
                                                    }
                                                }
                                        } label: {
                                            Image(systemName: "paperplane.fill")
                                                .padding(10)
                                                .background(ColorPalette.Green6)
                                                .foregroundColor(.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        .disabled(commentsVM.newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ColorPalette.Green6.opacity(0.1))
                                .cornerRadius(12)
            }
            .padding()
        }
        .onAppear { loadPostIsLiked() }
        .onDisappear { commentsVM.detach() }

        .onDisappear {
                commentsVM.detach()
            }
    }
    
    private func deletePostCascade() async {
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(post.id)

        // 1) comments ve comment likes temizle
        do {
            let commentsSnap = try await postRef.collection("comments").getDocuments()
            for cDoc in commentsSnap.documents {
                // yorum likes alt koleksiyonu
                let likesSnap = try await cDoc.reference.collection("likes").getDocuments()
                // çok sayıda ise küçük batch’lere bölebilirsiniz; burada direkt döngü
                for like in likesSnap.documents {
                    try await like.reference.delete()
                }
                try await cDoc.reference.delete()
            }
        } catch {
            print("Failed to delete comments: \(error.localizedDescription)")
        }

        // 2) post likes temizle
        do {
            let likesSnap = try await postRef.collection("likes").getDocuments()
            for doc in likesSnap.documents {
                try await doc.reference.delete()
            }
        } catch {
            print("Failed to delete post likes: \(error.localizedDescription)")
        }

        // 3) post dokümanını sil
        do {
            try await postRef.delete()
            await MainActor.run {
                // feed’ten de düş
                feedVM.removePostFromFeed(postId: post.id)
                dismiss()
            }
        } catch {
            print("Failed to delete post: \(error.localizedDescription)")
        }
    }
    
    private func loadPostIsLiked() {
        guard let uid = authViewModel.currentUser?.id else { return }
        let likeRef = Firestore.firestore()
            .collection("posts").document(post.id)
            .collection("likes").document(uid)

        likeRef.getDocument { snap, _ in
            isPostLiked = snap?.exists ?? false
        }
    }

    private func togglePostLike() {
        guard let uid = authViewModel.currentUser?.id else { return }

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(post.id)
        let likeRef = postRef.collection("likes").document(uid)

        db.runTransaction({ (txn, errPtr) -> Any? in
            do {
                let snap = try txn.getDocument(postRef)
                let current = (snap.data()?["likes"] as? Int) ?? 0
                if isPostLiked {
                    txn.updateData(["likes": max(0, current - 1)], forDocument: postRef)
                    txn.deleteDocument(likeRef)
                } else {
                    txn.updateData(["likes": current + 1], forDocument: postRef)
                    txn.setData(["userId": uid,
                                 "createdAt": FieldValue.serverTimestamp()],
                                forDocument: likeRef)
                }
            } catch let e as NSError {
                errPtr?.pointee = e
                return nil
            }
            return nil
        }, completion: { _, error in
            if error == nil {
                if isPostLiked {
                    isPostLiked = false
                    postLikeCount = max(0, postLikeCount - 1)
                } else {
                    isPostLiked = true
                    postLikeCount += 1
                }
            } else {
                print("Post like toggle failed: \(error!.localizedDescription)")
            }
        })
    }

}

// Tekil yorum satırı
struct CommentRow: View {
    let comment: Comment
        
        @EnvironmentObject var authViewModel: AuthViewModel
        @State private var isLiked = false
        @State private var likeCount: Int

        @State private var showDeleteConfirm = false
        var onDeleted: (() -> Void)? = nil

        init(comment: Comment, onDeleted: (() -> Void)? = nil) {
            self.comment = comment
            self.onDeleted = onDeleted
            _likeCount = State(initialValue: comment.likes)
        }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let urlStr = comment.profileImageURL, let url = URL(string: urlStr) {
                KFImage(url)
                    .resizable().scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(ColorPalette.Green6.opacity(0.25))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text(comment.username.prefix(1).uppercased())
                            .font(.caption)
                            .foregroundColor(ColorPalette.Green6)
                    )
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(comment.username).font(.subheadline).bold()
                    Spacer()
                    Text(comment.relativeDate).font(.caption).foregroundColor(.gray)

                    if authViewModel.currentUser?.id == comment.userId {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .confirmationDialog("Delete this comment?",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        Task { await deleteOwnComment() }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                
                Text(comment.text)
                    .font(.body)
                    .foregroundColor(ColorPalette.Green6)
                
                HStack {
                                    Button(action: { toggleCommentLike() }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                            Text("\(likeCount)")
                                        }
                                        .font(.caption)
                                        .foregroundColor(isLiked ? .pink : .gray)
                                    }
                                    Spacer()
                                }
                                .padding(.top, 2)
            }
        }
        .padding(8)
        .background(ColorPalette.Green6.opacity(0.07))
        .cornerRadius(10)
        .onAppear { loadIsLiked() }
    }
    
    // MARK: - Helpers
    
    private func deleteOwnComment() async {
        guard let uid = authViewModel.currentUser?.id,
              uid == comment.userId else { return }

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(comment.postId)
        let commentRef = postRef.collection("comments").document(comment.id)

        do {
            // 1) yorum likes temizle
            let likesSnap = try await commentRef.collection("likes").getDocuments()
            for doc in likesSnap.documents {
                try await doc.reference.delete()
            }

            // 2) post.comments sayacını azalt + yorum dokümanını sil (batch)
            let batch = db.batch()
            batch.updateData(["comments": FieldValue.increment(Int64(-1))], forDocument: postRef)
            batch.deleteDocument(commentRef)
            try await batch.commit()

            await MainActor.run {
                onDeleted?()   // ✅ PostView → PostCard sayacını −1
            }
        } catch {
            print("Failed to delete comment: \(error.localizedDescription)")
        }
    }

    
        private func loadIsLiked() {
            guard let uid = authViewModel.currentUser?.id else { return }
            let likeRef = Firestore.firestore()
                .collection("posts").document(comment.postId)
                .collection("comments").document(comment.id)
                .collection("likes").document(uid)

            likeRef.getDocument { snap, _ in
                isLiked = snap?.exists ?? false
            }
        }

        private func toggleCommentLike() {
            guard let uid = authViewModel.currentUser?.id else { return }

            let db = Firestore.firestore()
            let cRef = db.collection("posts").document(comment.postId)
                .collection("comments").document(comment.id)
            let likeRef = cRef.collection("likes").document(uid)

            db.runTransaction({ (txn, errPtr) -> Any? in
                do {
                    let snap = try txn.getDocument(cRef)
                    let current = (snap.data()?["likes"] as? Int) ?? 0
                    if isLiked {
                        txn.updateData(["likes": max(0, current - 1)], forDocument: cRef)
                        txn.deleteDocument(likeRef)
                    } else {
                        txn.updateData(["likes": current + 1], forDocument: cRef)
                        txn.setData(["userId": uid,
                                     "createdAt": FieldValue.serverTimestamp()],
                                    forDocument: likeRef)
                    }
                } catch let e as NSError {
                    errPtr?.pointee = e
                    return nil
                }
                return nil
            }, completion: { _, error in
                if error == nil {
                    if isLiked {
                        isLiked = false
                        likeCount = max(0, likeCount - 1)
                    } else {
                        isLiked = true
                        likeCount += 1
                    }
                } else {
                    print("Comment like toggle failed: \(error!.localizedDescription)")
                }
            })
        }
    
}

struct NewPostView: View {
    @ObservedObject var viewModel: SocietyViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $viewModel.newPostContent)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollContentBackground(.hidden)
                    .background(ColorPalette.Green6.opacity(0.1))
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .padding()
                    .accentColor(.black)
                    .frame(height: 350)
                Spacer()
            }
            .navigationTitle("New Post")
            .foregroundColor(.white)
            .navigationBarTitleDisplayMode(.inline)
            .background(ColorPalette.Green5)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            if let user = authViewModel.currentUser {
                                try? await viewModel.createPost(user: user, content: viewModel.newPostContent)
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    SocietyView()
        .environmentObject(AuthViewModel())
}

// SocietyViewModel.swift
// Add to UserDataBase.swift or create a new file for Post model
struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let userFullName: String
    let userProfileImageURL: String?
    let content: String
    let timestamp: Date
    var likes: Int
    var comments: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: timestamp)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

extension Post {
    static var MOCK_POSTS = [
        Post(
            id: "1",
            userId: "user1",
            userFullName: "Zerda Yılmaz",
            userProfileImageURL: nil,
            content: "Just discovered this amazing new recipe! The flavors were incredible and it was so easy to make. Highly recommend trying this at home!",
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            likes: 12,
            comments: 3
        ),
        Post(
            id: "2",
            userId: "user2",
            userFullName: "Alex Johnson",
            userProfileImageURL: "https://example.com/profile.jpg",
            content: "My food journey continues with this beautiful Mediterranean dish. So fresh and healthy!",
            timestamp: Date().addingTimeInterval(-86400), // 1 day ago
            likes: 24,
            comments: 5
        )
    ]
}

@MainActor
class SocietyViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var newPostContent = ""
    @Published var showNewPostSheet = false
    
    @Published var userLookup: [String: User] = [:]
    @Published var isLoadingUsers = false
    
    private let db = Firestore.firestore()
    
    init() {
        Task {
            await fetchPosts()
        }
    }
    
    func fetchPostingUsers() async {
            let ids = Set(posts.map { $0.userId })
            guard !ids.isEmpty else {
                self.userLookup = [:]
                return
            }
            isLoadingUsers = true
            do {
                var result: [String: User] = [:]
                let all = Array(ids)
                let chunk = 10 // Firestore “in” sorgusu en fazla 10 id
                var i = 0
                while i < all.count {
                    let batch = Array(all[i..<min(i+chunk, all.count)])
                    let snap = try await db.collection("users")
                        .whereField(FieldPath.documentID(), in: batch)
                        .getDocuments()

                    for d in snap.documents {
                        if let u = try? d.data(as: User.self) {
                            result[u.id] = u
                        }
                    }
                    i += chunk
                }
                self.userLookup = result
            } catch {
                print("fetchPostingUsers error: \(error.localizedDescription)")
            }
            isLoadingUsers = false
        }
    
    func fetchPosts() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("posts")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            var fetchedPosts: [Post] = []
            for document in snapshot.documents {
                if let post = try? document.data(as: Post.self) {
                    fetchedPosts.append(post)
                }
            }
            
            self.posts = fetchedPosts
        } catch {
            print("Error fetching posts: \(error.localizedDescription)")
            // For demo purposes, use mock data
            self.posts = Post.MOCK_POSTS
        }
        isLoading = false
    }
    
    func createPost(user: User, content: String) async throws {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "SocietyView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Post content cannot be empty"])
        }
        
        let post = Post(
            id: UUID().uuidString,
            userId: user.id,
            userFullName: user.fullnamefb,
            userProfileImageURL: user.profileImageURL,
            content: content,
            timestamp: Date(),
            likes: 0,
            comments: 0
        )
        
        try db.collection("posts").document(post.id).setData(from: post)
        posts.insert(post, at: 0) // Add to beginning of list
        newPostContent = ""
        showNewPostSheet = false
    }
    
    func likePost(postId: String) async {
        // Implement like functionality
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].likes += 1
            // Update in Firestore as well
        }
    }
    
    func removePostFromFeed(postId: String) {
        posts.removeAll { $0.id == postId }
    }
    
}

// MARK: - Comment Model
struct Comment: Identifiable, Codable {
    let id: String
    let postId: String
    let userId: String
    let username: String
    let profileImageURL: String?
    let text: String
    let timestamp: Date?
    var likes: Int
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.postId = data["postId"] as? String ?? ""
        self.userId = data["userId"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.profileImageURL = data["profileImageURL"] as? String
        self.text = data["text"] as? String ?? ""
        if let ts = data["timestamp"] as? Timestamp {
            self.timestamp = ts.dateValue()
        } else {
            self.timestamp = nil
        }
        self.likes = data["likes"] as? Int ?? 0
    }

    var relativeDate: String {
        guard let ts = timestamp else { return "just now" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: ts, relativeTo: Date())
    }
}

// MARK: - Comments ViewModel
@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var newComment: String = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    let postId: String

    init(postId: String) {
        self.postId = postId
        attach()
    }

    func attach() {
        detach()
        isLoading = true
        listener = db.collection("posts").document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self else { return }
                self.isLoading = false
                guard let docs = snap?.documents else {
                    self.comments = []
                    return
                }
                self.comments = docs.map { Comment(id: $0.documentID, data: $0.data()) }
            }
    }

    func detach() {
        listener?.remove()
        listener = nil
    }

    func addComment(user: User) async throws {
        let trimmed = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let postRef = db.collection("posts").document(postId)
        let commentRef = postRef.collection("comments").document()

        // serverTimestamp kullanıyoruz
        let data: [String: Any] = [
            "postId": postId,
            "userId": user.id,
            "username": user.fullnamefb,
            "profileImageURL": user.profileImageURL as Any,
            "text": trimmed,
            "timestamp": FieldValue.serverTimestamp(),
            "likes": 0,
        ]

        let batch = db.batch()
        batch.setData(data, forDocument: commentRef)
        batch.updateData(["comments": FieldValue.increment(Int64(1))], forDocument: postRef)
        try await batch.commit()

        await MainActor.run { self.newComment = "" }
    }
}
