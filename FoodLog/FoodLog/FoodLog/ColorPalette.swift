//
//  ColorPalette.swift
//  FoodLog
//
//  Created by Zerda Yilmaz on 20.05.2025.
//

import SwiftUI

struct ColorPalette {
    static let Green1     = Color(red: 39/255, green: 73/255, blue: 23/255)
    static let Green2   = Color(red: 76/255, green: 122/255, blue: 33/255)
    static let Green3    = Color(red: 111/255, green: 158/255, blue: 37/255)
    static let Green4     = Color(red: 119/255, green: 221/255, blue: 119/255)
    static let Green5    = Color(red: 214/255, green: 242/255, blue: 160/255)
    static let Yellow = Color(red: 255/255, green: 230/255, blue: 150/255)
    static let PastelLilac     = Color(red: 200/255, green: 162/255, blue: 200/255) // #C8A2C8
    static let PastelPeach     = Color(red: 255/255, green: 218/255, blue: 185/255) // #FFDAB9

    static let Green6     = Color(.sRGB, red: 0.055, green: 0.231, blue: 0.180)
    static let Green7   = Color(.sRGB, red: 0.078, green: 0.420, blue: 0.227)
    static let Green8    = Color(.sRGB, red: 0.851, green: 0.969, blue: 0.898)
    
    // MARK: - Reds (yeşille kontrast)
        static let Red1  = Color(.sRGB, red: 0.235, green: 0.039, blue: 0.039) // oxblood (koyu başlık/ikon)
        static let Red2  = Color(.sRGB, red: 0.561, green: 0.114, blue: 0.114) // brick
        static let Red3  = Color(.sRGB, red: 0.918, green: 0.416, blue: 0.353) // warm coral (CTA/rozet)
        static let Red4  = Color(.sRGB, red: 0.957, green: 0.792, blue: 0.792) // rose tint (arka plan)

        // MARK: - Light Greens (Lime/Mint) – badge, success, highlight
        static let Lime1 = Color(.sRGB, red: 0.184, green: 0.435, blue: 0.000) // deep lime (outline)
        static let Lime2 = Color(.sRGB, red: 0.424, green: 0.796, blue: 0.180) // bright lime (vurgu)
        static let Lime3 = Color(.sRGB, red: 0.682, green: 0.922, blue: 0.431) // soft lime (badge bg)
        static let Lime4 = Color(.sRGB, red: 0.914, green: 1.000, blue: 0.820) // lime mist (yüzey)

        static let Mint2 = Color(.sRGB, red: 0.545, green: 0.914, blue: 0.765) // mint vurgu
        static let Mint3 = Color(.sRGB, red: 0.812, green: 0.969, blue: 0.910) // mint yüzey
    
    static let all: [Color] = [
        Green1,
        Green2,
        Green3,
        Green4,
        Green5,
        Green6,
        Green7,
        Green8,
        
        Red1,
        Red2,
        Red3,
        Red4,
        
        Lime1,
        Lime2,
        Lime3,
        Lime4,
        
        Mint2,
        Mint3
    ]
}

struct ColorPaletteView: View {

    // İsim + Renk listesi
    private let namedColors: [(String, Color)] = [
        // Greens
        ("Green1", ColorPalette.Green1),
        ("Green2", ColorPalette.Green2),
        ("Green3", ColorPalette.Green3),
        ("Green4", ColorPalette.Green4),
        ("Green5", ColorPalette.Green5),
        ("Green6", ColorPalette.Green6),
        ("Green7", ColorPalette.Green7),
        ("Green8", ColorPalette.Green8),
        ("Yellow", ColorPalette.Yellow),
        ("PastelLilac", ColorPalette.PastelLilac),
        ("PastelPeach", ColorPalette.PastelPeach),
        // Reds
        ("Red1",  ColorPalette.Red1),
        ("Red2",  ColorPalette.Red2),
        ("Red3",  ColorPalette.Red3),
        ("Red4",  ColorPalette.Red4),

        // Limes
        ("Lime1", ColorPalette.Lime1),
        ("Lime2", ColorPalette.Lime2),
        ("Lime3", ColorPalette.Lime3),
        ("Lime4", ColorPalette.Lime4),

        // Mints
        ("Mint2", ColorPalette.Mint2),
        ("Mint3", ColorPalette.Mint3)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(namedColors, id: \.0) { (name, color) in
                    ColorSwatch(name: name, color: color)
                }
            }
            .padding()
        }
        .navigationTitle("Color Palette")
    }
}

private struct ColorSwatch: View {
    let name: String
    let color: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )

            // Etiket (isim)
            Text(name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
                .padding(8)
        }
    }
}

#Preview {
    ColorPaletteView()
}
