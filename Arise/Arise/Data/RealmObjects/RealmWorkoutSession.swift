//
//  RealmWorkoutSession.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RealmSwift

// MARK: - RealmGPSCoordinate (Embedded Object)
final class RealmGPSCoordinate: EmbeddedObject {
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var altitude: Double = 0.0
    @Persisted var timestamp: Date = Date()
    @Persisted var speed: Double = 0.0
    @Persisted var accuracy: Double = 0.0
    
    convenience init(from coordinate: GPSCoordinate) {
        self.init()
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = coordinate.altitude
        self.timestamp = coordinate.timestamp
        self.speed = coordinate.speed
        self.accuracy = coordinate.accuracy
    }
    
    func toDomain() -> GPSCoordinate {
        GPSCoordinate(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            timestamp: timestamp,
            speed: speed,
            accuracy: accuracy
        )
    }
}

// MARK: - RealmLapSplit (Embedded Object)
final class RealmLapSplit: EmbeddedObject {
    @Persisted var id: String = ""
    @Persisted var lapNumber: Int = 0
    @Persisted var startTime: Date = Date()
    @Persisted var endTime: Date = Date()
    @Persisted var distanceMeters: Double = 0.0
    @Persisted var averageHeartRate: Double = 0.0
    @Persisted var hasHeartRate: Bool = false
    
    convenience init(from lap: LapSplit) {
        self.init()
        self.id = lap.id
        self.lapNumber = lap.lapNumber
        self.startTime = lap.startTime
        self.endTime = lap.endTime
        self.distanceMeters = lap.distanceMeters
        self.averageHeartRate = lap.averageHeartRate ?? 0.0
        self.hasHeartRate = lap.averageHeartRate != nil
    }
    
    func toDomain() -> LapSplit {
        LapSplit(
            id: id,
            lapNumber: lapNumber,
            startTime: startTime,
            endTime: endTime,
            distanceMeters: distanceMeters,
            averageHeartRate: hasHeartRate ? averageHeartRate : nil
        )
    }
}

// MARK: - RealmWorkoutSession
final class RealmWorkoutSession: Object {
    
    // MARK: - Persisted Properties
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var userId: String = ""
    @Persisted var type: String = ""
    @Persisted var status: String = ""
    @Persisted var startTime: Date = Date()
    @Persisted var endTime: Date? = nil
    @Persisted var totalDistanceMeters: Double = 0.0
    @Persisted var totalCaloriesBurned: Double = 0.0
    @Persisted var averageHeartRate: Double = 0.0
    @Persisted var hasAverageHeartRate: Bool = false
    @Persisted var maxHeartRate: Double = 0.0
    @Persisted var hasMaxHeartRate: Bool = false
    @Persisted var averageSpeedMps: Double = 0.0
    @Persisted var notes: String? = nil
    @Persisted var weatherCondition: String? = nil
    @Persisted var deviceId: String? = nil
    
    // MARK: - Array of embedded objects
    @Persisted var gpsRoute: List<RealmGPSCoordinate>
    @Persisted var lapSplits: List<RealmLapSplit>
    
    // MARK: - Index for fast queries
    nonisolated override class func indexedProperties() -> [String] {
        return ["userId", "startTime", "status"]
    }
    
    // MARK: - Convenience Init
    convenience init(from session: WorkoutSession) {
        self.init()
        self.id = session.id
        self.userId = session.userId
        self.type = session.type.rawValue
        self.status = session.status.rawValue
        self.startTime = session.startTime
        self.endTime = session.endTime
        self.totalDistanceMeters = session.totalDistanceMeters
        self.totalCaloriesBurned = session.totalCaloriesBurned
        self.hasAverageHeartRate = session.averageHeartRate != nil
        self.averageHeartRate = session.averageHeartRate ?? 0.0
        self.hasMaxHeartRate = session.maxHeartRate != nil
        self.maxHeartRate = session.maxHeartRate ?? 0.0
        self.averageSpeedMps = session.averageSpeedMps
        self.notes = session.notes
        self.weatherCondition = session.weatherCondition
        self.deviceId = session.deviceId
        
        // Map GPS route array
        let realmCoords = session.gpsRoute.map { RealmGPSCoordinate(from: $0) }
        self.gpsRoute.append(objectsIn: realmCoords)
        
        // Map lap splits array
        let realmLaps = session.lapSplits.map { RealmLapSplit(from: $0) }
        self.lapSplits.append(objectsIn: realmLaps)
    }
    
    // MARK: - Mapper: Realm -> Domain
    func toDomain() -> WorkoutSession? {
        guard
            let workoutType = WorkoutType(rawValue: self.type),
            let workoutStatus = WorkoutStatus(rawValue: self.status)
        else { return nil }
        
        return WorkoutSession(
            id: id,
            userId: userId,
            type: workoutType,
            status: workoutStatus,
            startTime: startTime,
            endTime: endTime,
            totalDistanceMeters: totalDistanceMeters,
            totalCaloriesBurned: totalCaloriesBurned,
            averageHeartRate: hasAverageHeartRate ? averageHeartRate : nil,
            maxHeartRate: hasMaxHeartRate ? maxHeartRate : nil,
            averageSpeedMps: averageSpeedMps,
            gpsRoute: gpsRoute.compactMap { $0.toDomain() },
            heartRateSamples: [],
            lapSplits: lapSplits.compactMap { $0.toDomain() },
            notes: notes,
            weatherCondition: weatherCondition,
            deviceId: deviceId,
        )
    }
}
