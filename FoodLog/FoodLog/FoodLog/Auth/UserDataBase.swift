//
//  UserDataBase.swift
//  RealTest
//
//  Created by Zerda Yilmaz on 2.09.2024.
//

import Foundation
/*
 UserDataBase.swift (Kullanıcı Bilgileri)
 Kullanıcı modelini (User) tanımlar.
 Kullanıcının ID, adı (fullnamefb) ve e-postasını (emailfb) saklar.
 Kullanıcı adından baş harfleri oluşturma fonksiyonu içerir (initials).
 Mock kullanıcı (MOCK_USER) oluşturmak için örnek bir kullanıcı nesnesi tanımlanmıştır.
 */
struct User: Identifiable,Codable {
    let id: String
    let fullnamefb: String
    let emailfb: String
    
    var profileImageURL: String?
    var isPremium: Bool?
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullnamefb) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        return ""
    }
}

extension User {
    static var MOCK_USER = User(id: NSUUID().uuidString, fullnamefb: "Zerda Yılmaz", emailfb: "test@gmail.com")
}
