//
//  Color+Ext.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI

extension Color {
    
    // MARK: - Brand Colors
    static let ariseBackground      = Color("ariseBackground")
    static let ariseCard            = Color("ariseCard")
    static let arisePrimary         = Color("arisePrimary")
    static let ariseSecondary       = Color("ariseSecondary")
    static let ariseAccent          = Color("ariseAccent")
    
    // MARK: - Health Metric Color
    static let heartRateColor       = Color("heartRateColor")
    static let bloodOxygenColor     = Color("bloodOxygenColor")
    static let stepsColor           = Color("stepsColor")
    static let caloriesColor        = Color("caloriesColor")
    static let hydrationColor       = Color("hydrationColor")
    static let sleepColor           = Color("sleepColor")
    
    // MARK: - Inline fallbacks
    static let arisePrimaryFallback = Color(red: 0.38, green: 0.36, blue: 0.96)
    static let ariseCardFallback    = Color(UIColor.secondarySystemBackground)
    static let ariseBackgroundFallback = Color(UIColor.systemBackground)
    
}
