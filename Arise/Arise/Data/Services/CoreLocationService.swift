//
//  CoreLocationService.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import CoreLocation
import RxSwift

final class CoreLocationService: NSObject, LocationServiceProtocol {
    
    private let authStatusSubject = BehaviorSubject<LocationAuthorizationStatus>(value: .notDetermined)
    
    var authorizationStatus: Observable<LocationAuthorizationStatus> {
        authStatusSubject.asObservable()
    }
    
    func requestAlwaysAuthorization() {}
    
    func startTracking() -> Observable<GPSCoordinate> {.empty()}
    
    func stopTracking() {}
    
    func pauseTracking() {}
    
    func resumeTracking() {}
    
    func fetchCurrentLocation() -> Single<GPSCoordinate> {
        .error(WorkoutError.locationPermissionDenied)
    }
    
}
