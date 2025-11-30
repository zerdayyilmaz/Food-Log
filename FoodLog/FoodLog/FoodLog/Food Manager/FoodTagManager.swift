//
//  FoodTagManager.swift
//  FoodLog
//
//  Created by Zerda Yilmaz on 20.05.2025.
//

import FirebaseFirestore
import FirebaseAuth

class FoodTagManager: ObservableObject {
    @Published var tags: [String] = []

    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    private var db: Firestore {
        Firestore.firestore()
    }

    func fetchTags() {
        guard let uid = userId else { return }
        let ref = db.collection("users").document(uid)

        ref.getDocument { snapshot, error in
            if let error = error {
                print("🔥 Error fetching tags: \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data(), let foodTags = data["foodTags"] as? [String] {
                DispatchQueue.main.async {
                    self.tags = foodTags
                    print("✅ Tags fetched: \(self.tags)")
                }
            } else {
                print("⚠️ No tags found in document.")
            }
        }
    }


    func addTagIfNew(_ tag: String) {
        guard let uid = userId else { return }
        let cleaned = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleaned.isEmpty || tags.contains(cleaned) { return }

        tags.append(cleaned)

        db.collection("users").document(uid).updateData([
            "foodTags": tags
        ]) { error in
            if let error = error {
                print("🔥 Failed to update tags: \(error.localizedDescription)")
            }
        }
    }
    
    func addFoodToDate(_ food: String, for date: Date) {
        guard let uid = userId else { return }
        let cleaned = food.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleaned.isEmpty { return }

        let dateKey = formattedDateString(for: date)

        let docRef = db.collection("users").document(uid)
            .collection("dailyLogs").document(dateKey)

        docRef.getDocument { snapshot, error in
            var currentFoods = (snapshot?.data()?["foods"] as? [String]) ?? []

            if currentFoods.contains(cleaned) {
                return // zaten varsa ekleme
            }

            currentFoods.append(cleaned)

            docRef.setData(["foods": currentFoods], merge: true)
        }
    }

    func fetchFoodsForDate(_ date: Date, completion: @escaping ([String]) -> Void) {
        guard let uid = userId else { return }
        let dateKey = formattedDateString(for: date)

        let docRef = db.collection("users").document(uid)
            .collection("dailyLogs").document(dateKey)

        docRef.getDocument { snapshot, error in
            let foods = snapshot?.data()?["foods"] as? [String] ?? []
            DispatchQueue.main.async {
                completion(foods)
            }
        }
    }

    private func formattedDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    
}


