//
//  WorkoutSession.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation

// MARK: - WorkoutType
enum WorkType: String, Codable, CaseIterable {
    case running        = "running"
    case cycling        = "cycling"
    case swimming       = "swimming"
    case weightLifting  = "weight_lifting"
    case yoga           = "yoga"
    case hiit           = "hiit"
    case walking        = "walking"
    case hiking         = "hiking"
    
    // MARK: - DisplayHelpers
    var displayName: String {
        switch self {
        case .running:          return "Running"
        case .cycling:          return "Cycling"
        case .swimming:         return "Swimming"
        case .weightLifting:    return "Weight Lifting"
        case .yoga:             return "Yoga"
        case .hiit:             return "HIIT"
        case .walking:          return "Walking"
        case .hiking:           return "Hiking"
        }
    }
    
    var iconName: String {
        switch self {
        case .running:          return "figure.run"
        case .cycling:          return "figure.outdoor.cycle"
        case .swimming:         return "figure.pool.swim"
        case .weightLifting:    return "figure.strengthtraining.traditional"
        case .yoga:             return "figure.mind.and.body"
        case .hiit:             return "figure.highintensity.intervaltraining"
        case .walking:          return "figure.walk"
        case .hiking:           return "figure.hiking"
        }
    }
    
    var requiresGPSTracking: Bool {
        switch self {
        case .running, .cycling, .swimming, .walking, .hiking: return true
        default:                                                return false
        }
    }
}

// MARK: - WorkoutStatus
enum WorkoutStatus: String, Codable {
    case idle       = "idle"
    case active     = "active"
    case paused     = "paused"
    case completed  = "completed"
    case cancelled  = "cancelled"
}

// MARK: - GPSCoordinator
struct GPSCoordinator: Equatable, Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
    let speed: Double
    let accuracy: Double
}

// MARK: - LapSplit
struct LapSplit: Equatable, Codable, Identifiable {
    let id: String
    let lapNumber: Int
    let startTime: Date
    let endTime: Date
    let distanceMeters: Double
    let averageHeartRate: Double?
    
    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
    
    var paceSecondsPerKm: Double {
        guard distanceMeters > 0 else { return 0 }
        let distanceKm = distanceMeters / 1000
        return duration / distanceKm
    }
    
    var formattedPace: String {
        let pace = paceSecondsPerKm
        let mintues = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", mintues, seconds)
    }
    
    init(
        id: String = UUID().uuidString,
        lapNumber: Int,
        startTime: Date,
        endTime: Date,
        distanceMeters: Double,
        averageHeartRate: Double? = nil
    ) {
        self.id = id
        self.lapNumber = lapNumber
        self.startTime = startTime
        self.endTime = endTime
        self.distanceMeters = distanceMeters
        self.averageHeartRate = averageHeartRate
    }
}

// MARK: - WorkoutSession Entity
struct WorkoutSession: Equatable, Codable, Identifiable {
    
    // MARK: - Identity
    let id: String
    let userId: String
    
    // MARK: - Workout Info
    let type: WorkType
    var status: WorkoutStatus
    
    // MARK: - Timing
    let startTime: Date
    let endTime: Date?
    
    // MARK: - Performance Metrics
    var totalDistanceMeters: Double
    var totalCaloriesBurned: Double
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var averageSpeedMps: Double
    
    // MARK: - Nested Data
    var gpsRoute: [GPSCoordinator]
    var heartRateSamples: [HealthMetric]
    var lapSplits: [LapSplit]
    
    // MARK: - Metadata
    var notes: String?
    var weatherCondition: String?
    var deviceId: String?
    
    // MARK: - Computed Properties
    var duration: TimeInterval {
        guard let end = endTime else { return Date().timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours     = totalSeconds / 3600
        let minutes   = (totalSeconds % 3600) / 60
        let seconds   = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedDistance: String {
        if totalDistanceMeters >= 1000 {
            return "\((totalDistanceMeters / 1000).rounded(toPlaces: 2)) km"
        } else {
            return "\(Int(totalDistanceMeters)) m"
        }
    }
    
    var formattedAveragePace: String? {
        guard type.requiresGPSTracking,
              totalDistanceMeters > 0 else { return nil }
        let distanceKm  = totalDistanceMeters / 1000
        let paceSeconds = duration / distanceKm
        let minutes     = Int(paceSeconds) / 60
        let seconds     = Int(paceSeconds) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    var isActive: Bool { status == .active }
    
    var isValid: Bool { duration >= 60 && totalDistanceMeters >= 0 }
    
    // MARK: - Initializer
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: WorkType,
        status: WorkoutStatus = .idle,
        startTime: Date = Date(),
        endTime: Date? = nil,
        totalDistanceMeters: Double = 0,
        totalCaloriesBurned: Double = 0,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        averageSpeedMps: Double = 0,
        gpsRoute: [GPSCoordinator] = [],
        heartRateSamples: [HealthMetric] = [],
        lapSplits: [LapSplit] = [],
        notes: String? = nil,
        weatherCondition: String? = nil,
        deviceId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.totalDistanceMeters = totalDistanceMeters
        self.totalCaloriesBurned = totalCaloriesBurned
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.averageSpeedMps = averageSpeedMps
        self.gpsRoute = gpsRoute
        self.heartRateSamples = heartRateSamples
        self.lapSplits = lapSplits
        self.notes = notes
        self.weatherCondition = weatherCondition
        self.deviceId = deviceId
    }
}
