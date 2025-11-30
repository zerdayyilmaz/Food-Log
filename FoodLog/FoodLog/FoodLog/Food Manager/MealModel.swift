//
//  MealModel.swift
//  FoodLog
//
//  Created by Zerda Yilmaz on 20.05.2025.
//

import Foundation

struct MealEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mealType: MealType // kahvaltı, öğle, akşam vs.
    var foods: [FoodItem]
    var comment: StomachReaction // midemi yaktı mı
}

enum MealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack
}

enum StomachReaction: String, Codable {
    case burned = "Midemi yaktı"
    case notBurned = "Yakmadı"
}

struct FoodItem: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
}

