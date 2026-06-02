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
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    
    private let authStatusSubject = BehaviorSubject<LocationAuthorizationStatus>(value: .notDetermined)
    private let coordinateSubject = PublishSubject<GPSCoordinate>()
    private var isTracking = false
    
    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Protocol Implementation
    var authorizationStatus: Observable<LocationAuthorizationStatus> {
        authStatusSubject.asObservable()
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() -> Observable<GPSCoordinate> {
        isTracking = true
        locationManager.startUpdatingLocation()
        return coordinateSubject.asObservable()
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
    }
    
    func pauseTracking() {
        locationManager.stopUpdatingLocation()
    }
    
    func resumeTracking() {
        guard isTracking else { return }
        locationManager.startUpdatingLocation()
    }
    
    func fetchCurrentLocation() -> Single<GPSCoordinate> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(WorkoutError.locationPermissionDenied))
                return Disposables.create()
            }

            let subscription = self.coordinateSubject
                .take(1)
                .asSingle()
                .subscribe(
                    onSuccess: { single(.success($0)) },
                    onFailure: { single(.failure($0)) }
                )

            self.locationManager.requestLocation()

            return Disposables.create { subscription.dispose() }
        }
    }
    
}

// MARK: - CoreLocationManagerDelegate
extension CoreLocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let coordinate = GPSCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp,
            speed: max(location.speed, 0),
            accuracy: location.horizontalAccuracy
        )
        
        coordinateSubject.onNext(coordinate)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: LocationAuthorizationStatus
        
        switch manager.authorizationStatus {
        case .notDetermined:            status = .notDetermined
        case .authorizedAlways:         status = .authorized
        case .authorizedWhenInUse:      status = .authorizedWhen
        case .denied:                   status = .restricted
        case .restricted:               status = .denied
        @unknown default:               status = .notDetermined
        }
        
        authStatusSubject.onNext(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print("⚠️ Location error: \(error.localizedDescription)")
    }
    
}
