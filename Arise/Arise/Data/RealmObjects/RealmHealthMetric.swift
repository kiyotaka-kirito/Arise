//
//  RealmHealthMetric.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RealmSwift

// MARK: - RealmHealthMetric
final class RealmHealthMetric: Object {
    
    // MARK: - Persisted Properties
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var userId: String = ""
    @Persisted var type: String = ""
    @Persisted var value: Double = 0.0
    @Persisted var secondaryValue: Double = 0.0
    @Persisted var hasSecondaryValue: Bool = false
    @Persisted var recordedAt: Date = Date()
    @Persisted var source: String = ""
    @Persisted var deviceId: String? = nil
    
    // MARK: - Index for fast queries
    nonisolated override class func indexedProperties() -> [String] {
        return ["userId", "type", "recordedAt"]
    }
    
    // MARK: - Convenience Init
    convenience init(from metric: HealthMetric) {
        self.init()
        self.id = metric.id
        self.userId = metric.userId
        self.type = metric.type.rawValue
        self.value = metric.value
        self.hasSecondaryValue = metric.secondaryValue != nil
        self.secondaryValue = metric.secondaryValue ?? 0.0
        self.recordedAt = metric.recordedAt
        self.source = metric.source.rawValue
        self.deviceId = metric.deviceId
    }
    
    // MARK: - Mapper: Realm -> Domain
    func toDomain() -> HealthMetric? {
        guard
            let metricType = MetricType(rawValue: self.type),
            let metricSource = MetricSource(rawValue: self.source)
        else { return nil }
        
        return HealthMetric(
            id: id,
            userId: userId,
            type: metricType,
            value: value,
            secondaryValue: hasSecondaryValue ? secondaryValue : nil,
            recordedAt: recordedAt,
            source: metricSource,
            deviceId: deviceId
        )
    }
}
