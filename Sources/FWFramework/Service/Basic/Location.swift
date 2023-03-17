//
//  Location.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
import CoreLocation

// MARK: - Notification+Location
extension Notification.Name {
    
    /// 定位更新通知
    public static let LocationUpdated = NSNotification.Name("FWLocationUpdatedNotification")
    /// 定位失败通知
    public static let LocationFailed = NSNotification.Name("FWLocationFailedNotification")
    /// 方向改变通知
    public static let HeadingUpdated = NSNotification.Name("FWHeadingUpdatedNotification")
    
}

// MARK: - LocationManager
/// 位置服务
///
/// 注意：Info.plist需要添加NSLocationWhenInUseUsageDescription项。
/// 如果请求Always定位，还需添加NSLocationAlwaysUsageDescription项和NSLocationAlwaysAndWhenInUseUsageDescription项。
/// iOS11可通过showsBackgroundLocationIndicator配置是否显示后台定位指示器
open class LocationManager: NSObject, CLLocationManagerDelegate {
    
    /// 单例模式
    public static let shared = LocationManager()
    
    /// 坐标转"纬度,经度"字符串
    open class func locationString(_ coordinate: CLLocationCoordinate2D) -> String {
        return "\(coordinate.latitude),\(coordinate.longitude)"
    }
    
    /// "纬度,经度"字符串转坐标
    open class func locationCoordinate(_ string: String) -> CLLocationCoordinate2D {
        let degrees = string.components(separatedBy: ",")
        return CLLocationCoordinate2D(latitude: Double(degrees.first ?? "0") ?? 0, longitude: Double(degrees.last ?? "0") ?? 0)
    }
    
    /// 计算两个经纬度间的距离
    open class func locationDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        return CLLocation(latitude: from.latitude, longitude: from.longitude).distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }
    
    /// 是否启用Always定位，默认NO，请求WhenInUse定位
    open var alwaysLocation: Bool = false
    
    /// 是否启用后台定位，默认NO。如果需要后台定位，设为YES即可
    open var backgroundLocation: Bool = false
    
    /// 是否启用方向监听，默认NO。如果设备不支持方向，则不能启用
    open var headingEnabled: Bool = false {
        didSet {
            // 不支持方向时，设置无效
            if headingEnabled && !CLLocationManager.headingAvailable() {
                headingEnabled = false
            }
        }
    }
    
    /// 是否发送通知，默认NO。如果需要通知，设为YES即可
    open var notificationEnabled: Bool = false
    
    /// 定位完成是否立即stop，默认NO。如果为YES，只会回调一次
    open var stopWhenCompleted: Bool = false
    
    /// 位置管理对象
    open lazy var locationManager: CLLocationManager = {
        let result = CLLocationManager()
        result.delegate = self
        result.desiredAccuracy = kCLLocationAccuracyBest
        // result.distanceFilter = 50
        // result.showsBackgroundLocationIndicator = true
        return result
    }()
    
    /// 当前位置，中途定位失败时不会重置
    open private(set) var location: CLLocation?
    
    /// 当前方向，headingEnabled启用后生效
    open private(set) var heading: CLHeading?
    
    /// 当前错误，表示最近一次定位回调状态
    open private(set) var error: Error?
    
    /// 定位改变block方式回调，可通过error判断是否定位成功
    open var locationChanged: ((LocationManager) -> Void)?
    
    private var isCompleted: Bool = false
    
    /// 开始更新位置
    open func startUpdateLocation() {
        if stopWhenCompleted {
            isCompleted = false
        }
        
        if alwaysLocation {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        if backgroundLocation {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        locationManager.startUpdatingLocation()
        if headingEnabled {
            locationManager.startUpdatingHeading()
        }
    }
    
    /// 停止更新位置
    open func stopUpdateLocation() {
        if stopWhenCompleted {
            isCompleted = true
        }
        
        if backgroundLocation {
            locationManager.allowsBackgroundLocationUpdates = false
        }
        
        if headingEnabled {
            locationManager.stopUpdatingHeading()
        }
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if stopWhenCompleted {
            if isCompleted { return }
            isCompleted = true
        }
        
        let oldLocation = location
        let newLocation = locations.last
        location = newLocation
        error = nil
        
        locationChanged?(self)
        if notificationEnabled {
            var userInfo: [AnyHashable: Any] = [:]
            if let oldLocation = oldLocation {
                userInfo[NSKeyValueChangeKey.oldKey] = oldLocation
            }
            if let newLocation = newLocation {
                userInfo[NSKeyValueChangeKey.newKey] = newLocation
            }
            NotificationCenter.default.post(name: .LocationUpdated, object: self, userInfo: userInfo)
        }
        
        if stopWhenCompleted {
            stopUpdateLocation()
        }
    }
    
    open func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if stopWhenCompleted {
            if isCompleted { return }
            isCompleted = true
        }
        
        let oldHeading = heading
        heading = newHeading
        error = nil
        
        locationChanged?(self)
        if notificationEnabled {
            var userInfo: [AnyHashable: Any] = [:]
            if let oldHeading = oldHeading {
                userInfo[NSKeyValueChangeKey.oldKey] = oldHeading
            }
            userInfo[NSKeyValueChangeKey.newKey] = newHeading
            NotificationCenter.default.post(name: .HeadingUpdated, object: self, userInfo: userInfo)
        }
        
        if stopWhenCompleted {
            stopUpdateLocation()
        }
    }
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if stopWhenCompleted {
            if isCompleted { return }
            isCompleted = true
        }
        
        self.error = error
        
        locationChanged?(self)
        if notificationEnabled {
            var userInfo: [AnyHashable: Any] = [:]
            userInfo[NSUnderlyingErrorKey] = error
            NotificationCenter.default.post(name: .LocationFailed, object: self, userInfo: userInfo)
        }
        
        if stopWhenCompleted {
            stopUpdateLocation()
        }
    }
    
}
