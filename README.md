# Food-Log
**FoodLog** is a holistic health tracking application that helps users monitor their nutrition intake alongside their emotional well-being. Unlike standard calorie counters, FoodLog correlates what you eat with how you feel.

# FoodLog - Nutrition & Mood Tracker 🍎

[![Download on the App Store](https://img.shields.io/badge/Download-on_the_App_Store-black?logo=apple&style=for-the-badge)](https://apps.apple.com/tr/app/meal-symptom-foodlog/id6746221002)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?style=flat&logo=swift)
![iOS](https://img.shields.io/badge/iOS-16.0+-lightgrey?style=flat&logo=apple)
![Firebase](https://img.shields.io/badge/Firebase-Auth-yellow?style=flat&logo=firebase)

## Overview

The app features a robust **reporting system** that visualizes weekly data and generates downloadable **PDF health reports** for users to share with their dietitians or doctors.

<p align="center">
  <img src="Images/Calendar.mp4" width="200" alt="Home">
  <img src="Images/FoodAdding.mp4" width="200" alt="Statistics">
  <img src="Images/Stats.png" width="200" alt="Premium">
  <img src="Images/Stats2.png" width="200" alt="Premium">
  <img src="Images/PDF1.png" width="200" alt="PDF Report">
  <img src="Images/PDF2.png" width="200" alt="PDF Report">
  <img src="Images/Paywall.png" width="200" alt="Premium">
</p>

## Key Features

* **Advanced Data Visualization:** Interactive charts to track calories, protein, carbs, and fat intake over time.
* **PDF Report Generation:** Users can export their weekly nutrition and mood summaries as professional PDF documents (Powered by `PDFKit`).
* **Mood Tracking:** Logs daily mood states to find patterns between diet and mental health.
* **Secure Authentication:** Firebase Auth integration for secure user login and data syncing.
* **Premium Model:** Integrated StoreKit for subscription management and premium features.

## Tech Stack & Architecture

* **Language:** Swift 5
* **UI Framework:** SwiftUI
* **Architecture:** MVVM (Model-View-ViewModel)
* **Core Frameworks:**
    * `PDFKit` (For generating dynamic health reports)
    * `Charts` / `SwiftCharts` (For statistical data visualization)
    * `StoreKit 2` (In-App Purchases)
    * `CoreData` (Local persistence for offline capability)
* **Backend:** Firebase (Authentication & Analytics)

## Highlight: PDF Generation

One of the core technical challenges in this project was creating dynamic PDF reports from SwiftUI views.

Installation
To run this project locally:

Clone the repository.

Add your own GoogleService-Info.plist to the root folder (Required for Firebase).

Build and run on Xcode 15+.

Author
Zerda Yılmaz Junior iOS Developer

Note: This project is live on the App Store. Some proprietary assets have been removed from this open-source version.

```swift
// Sample approach for PDF generation logic found in PDFHelper.swift
func createPDF(from data: WeeklyData) -> Data {
    let pdfMetaData = [
        kCGPDFContextCreator: "FoodLog App",
        kCGPDFContextAuthor: "User"
    ]
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String: Any]
    
    // Rendering logic...
}
