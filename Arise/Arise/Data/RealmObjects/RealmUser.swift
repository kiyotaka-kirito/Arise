//
//  RealmUser.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RealmSwift

// MARK: - RealmUser
final class RealmUser: Object {
    
    // MARK: - Persisted Properties
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var fullName: String = ""
    @Persisted var email: String = ""
    @Persisted var dateOfBirth: Date = Date()
    @Persisted var gender: String = ""
    @Persisted var heightInCm: Double = 0.0
    @Persisted var weightInKg: Double = 0.0
    @Persisted var profileImageURL: String? = nil
    
    // MARK: - Convenience Init
    convenience init(from user: User) {
        self.init()
        self.id = user.id
        self.fullName = user.fullName
        self.email = user.email
        self.dateOfBirth = user.dateOfBirth
        self.gender = user.gender.rawValue
        self.heightInCm = user.heightInCm
        self.weightInKg = user.weightInKg
        self.profileImageURL = user.profileImageURL
    }
    
    // MARK: - Mapper: Realm -> Domain
    func toDomain() -> User? {
        guard let gender = Gender(rawValue: self.gender) else { return nil }
        return User(
            id: id,
            fullName: fullName,
            email: email,
            dateOfBirth: dateOfBirth,
            gender: gender,
            heightInCm: heightInCm,
            weightInKg: weightInKg,
            profileImageURL: profileImageURL
        )
    }
}
