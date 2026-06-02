//
//  User.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation

// MARK: - Gender Enum
enum Gender: String, Codable {
    case male   = "male"
    case female = "female"
    case other  = "other"
}

// MARK: - User Entity
struct User: Equatable, Codable {
    // MARK: - Core Properties
    let id: String
    var fullName: String
    var email: String
    var dateOfBirth: Date
    var gender: Gender
    var heightInCm: Double
    var weightInKg: Double
    var profileImageURL: String?
    
    // MARK: - Computed Properties
    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
    
    var bmi: Double {
        let heightInMeters = heightInCm / 100
        guard heightInMeters > 0 else { return 0 }
        return (weightInKg / (heightInMeters * heightInMeters)).rounded(toPlaces: 2)
    }
    
    var bmiCategory: BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<24.9: return .normal
        case 25..<29.9: return .overweight
        default: return .obese
        }
    }
    
    // MARK: - Initializer
    init(
        id: String = UUID().uuidString,
        fullName: String,
        email: String,
        dateOfBirth: Date,
        gender: Gender,
        heightInCm: Double,
        weightInKg: Double,
        profileImageURL: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.heightInCm = heightInCm
        self.weightInKg = weightInKg
        self.profileImageURL = profileImageURL
    }
}

// MARK: - BMI Category
enum BMICategory: String {
    case underweight    = "Underweight"
    case normal         = "Normal"
    case overweight     = "Overweight"
    case obese          = "Obese"
    
    var colorName: String {
        switch self {
        case .underweight: return "bmiBlue"
        case .normal:      return "bmiGreen"
        case .overweight:  return "bmiYellow"
        case .obese:       return "bmiRed"
        }
    }
}
