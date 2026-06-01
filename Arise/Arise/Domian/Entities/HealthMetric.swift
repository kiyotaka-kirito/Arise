//
//  HealthMetric.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation

// MARK: - MetricType
enum MetricType: String, Codable {
    case heartRate        = "heart_rate"
    case bloodOxygen      = "blood_oxygen"
    case steps            = "steps"
    case caloriesBurned   = "calories_burned"
    case distanceTraveled = "distance_traveled"
    case sleepDuration    = "sleep_duration"
    case hydration        = "hydration"
    case bloodPressure    = "blood_pressure"
    
    // MARK: - DisplayHelpers
    var displayName: String {
        switch self {
        case .heartRate:        return "Heart Rate"
        case .bloodOxygen:      return "Blood Oxygen"
        case .steps:            return "Steps"
        case .caloriesBurned:   return "Calories Burned"
        case .distanceTraveled: return "Distance"
        case .sleepDuration:    return "Sleep"
        case .hydration:        return "Hydration"
        case .bloodPressure:    return "Blood Pressure"
        }
    }
    
    var unit: String {
        switch self {
        case .heartRate:        return "bpm"
        case .bloodOxygen:      return "%"
        case .steps:            return "steps"
        case .caloriesBurned:   return "cal"
        case .distanceTraveled: return "m"
        case .sleepDuration:    return "min"
        case .hydration:        return "ml"
        case .bloodPressure:    return "mmHg"
        }
    }
    
    var iconName: String {
        switch self {
        case .heartRate:        return "heart.fill"
        case .bloodOxygen:      return "lungs.fill"
        case .steps:            return "figure.walk"
        case .caloriesBurned:   return "flame.fill"
        case .distanceTraveled: return "map.fill"
        case .sleepDuration:    return "moon.fill"
        case .hydration:        return "drop.fill"
        case .bloodPressure:    return "waveform.path.ecg"
        }
    }
}

// MARK: - MetricSource
enum MetricSource: String, Codable {
    case appleWatch      = "apple_watch"
    case bluetoothDevice = "bluetooth"
    case manual          = "manual"
    case calculated      = "calculated"
}

// MARK: - HealthMetric Entity
struct HealthMetric: Equatable, Codable, Identifiable {
    // MARK: - Core Properties
    let id: String
    let userId: String
    let type: MetricType
    let value: Double
    let secondaryValue: Double?
    let recordedAt: Date
    let source: MetricSource
    let deviceId: String?
    
    // MARK: - Computed Properties
    var formattedValue: String {
        if type == .bloodPressure, let diastolic = secondaryValue {
            return "\(Int(value))/\(Int(diastolic)) \(type.unit)"
        }
        
        switch type {
        case .steps, .caloriesBurned:
            return "\(Int(value)) \(type.unit)"
        default:
            return "\(value.rounded(toPlaces: 1)) \(type.unit)"
        }
    }
    
    var isWithinHealthyRange: Bool {
        switch type {
        case .heartRate:        return (60...100).contains(value)
        case .bloodOxygen:      return value >= 95
        case .steps:            return value >= 8000
        case .sleepDuration:    return (420...540).contains(value)
        default:                return true
        }
    }
    
    // MARK: - Initializer
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: MetricType,
        value: Double,
        secondaryValue: Double? = nil,
        recordedAt: Date = Date(),
        source: MetricSource,
        deviceId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.value = value
        self.secondaryValue = secondaryValue
        self.recordedAt = recordedAt
        self.source = source
        self.deviceId = deviceId
    }
}

// MARK: - HealthMetricCollection
struct HealthMetricCollection {
    
    let metrics: [HealthMetric]
    let type: MetricType
    
    private var values: [Double] { metrics.filter { $0.type == type }.map(\.value) }
    
    var latest: HealthMetric? {
        metrics.filter { $0.type == type }
            .sorted { $0.recordedAt > $1.recordedAt }
            .first
    }
    
    var average: Double {
        guard !values.isEmpty else { return 0 }
        return (values.reduce(0, +) / Double(values.count)).rounded(toPlaces: 1)
    }
    
    var maximum: Double { values.max() ?? 0 }
    
    var minimum: Double { values.min() ?? 0 }
}
