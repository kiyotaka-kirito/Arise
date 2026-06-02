//
//  LocationServiceProtocol.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - LocationAuthorizationStatus
enum LocationAuthorizationStatus {
    case notDetermined
    case authorized
    case authorizedWhen
    case denied
    case restricted
}

// MARK: - LocationServiceProtocol
protocol LocationServiceProtocol {
    
    // Auhtorization
    var authorizationStatus: Observable<LocationAuthorizationStatus> { get }
    func requestAlwaysAuthorization()
    
    // Tracking
    func startTracking() -> Observable<GPSCoordinate>
    func stopTracking()
    func pauseTracking()
    func resumeTracking()
    
    // One-Shot Location
    func fetchCurrentLocation() -> Single<GPSCoordinate>
    
}
