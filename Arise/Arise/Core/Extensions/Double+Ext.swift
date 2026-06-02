//
//  Double+Ext.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation

extension Double {
    
    /// Round a Double to a specified number of decimal places
    /// Usage: (3.14159).rounded(toPlaces: 2) -> 3.14
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
