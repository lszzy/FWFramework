//
//  Location.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import CoreLocation
import Foundation

// MARK: - Notification+Location
extension Notification.Name {
    /// 定位更新通知
    public static let LocationUpdated = Notification.Name("FWLocationUpdatedNotification")
    /// 定位失败通知
    public static let LocationFailed = Notification.Name("FWLocationFailedNotification")
    /// 方向改变通知
    public static let HeadingUpdated = Notification.Name("FWHeadingUpdatedNotification")
}

// MARK: - LocationManager
/// 位置服务
///
/// 注意：Info.plist需要添加NSLocationWhenInUseUsageDescription项。
/// 如果请求Always定位，还需添加NSLocationAlwaysUsageDescription项和NSLocationAlwaysAndWhenInUseUsageDescription项。
/// 可通过showsBackgroundLocationIndicator配置是否显示后台定位指示器；可调用startMonitoringSignificantLocationChanges开启定位保活。
open class LocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    /// 单例模式
    public static let shared = LocationManager()

    /// 坐标转"纬度,经度"字符串
    open class func locationString(_ coordinate: CLLocationCoordinate2D) -> String {
        "\(coordinate.latitude),\(coordinate.longitude)"
    }

    /// "纬度,经度"字符串转坐标
    open class func locationCoordinate(_ string: String) -> CLLocationCoordinate2D {
        let degrees = string.components(separatedBy: ",")
        return CLLocationCoordinate2D(latitude: Double(degrees.first ?? "0") ?? 0, longitude: Double(degrees.last ?? "0") ?? 0)
    }

    /// 计算两个经纬度间的距离
    open class func locationDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: from.latitude, longitude: from.longitude).distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }

    /// 经纬度反解析为地址
    @discardableResult
    open class func reverseGeocode(_ coordinate: CLLocationCoordinate2D, locale: Locale? = nil, completionHandler: @escaping CLGeocodeCompletionHandler) -> CLGeocoder {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location, preferredLocale: locale, completionHandler: completionHandler)
        return geocoder
    }

    /// 地址解析为经纬度
    @discardableResult
    open class func geocode(_ address: String, region: CLRegion? = nil, locale: Locale? = nil, completionHandler: @escaping CLGeocodeCompletionHandler) -> CLGeocoder {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, in: region, preferredLocale: locale, completionHandler: completionHandler)
        return geocoder
    }

    /// 经纬度是否在国外
    open class func isOutOfChina(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let lon = coordinate.longitude
        let lat = coordinate.latitude
        if lon < 72.004 || lon > 137.8347 { return true }
        if lat < 0.8293 || lat > 55.8271 { return true }
        return false
    }

    /// WGS84国际坐标系转换为GCJ02国内火星坐标系
    open class func wgs84ToGcj02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lon = coordinate.longitude
        let lat = coordinate.latitude
        let a = 6_378_245.0
        let ee = 0.00669342162296594323
        var dLat = transformLat(x: lon - 105.0, y: lat - 35.0)
        var dLon = transformLon(x: lon - 105.0, y: lat - 35.0)
        let radLat = lat / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)
        let mgLat = lat + dLat
        let mgLon = lon + dLon
        return .init(latitude: mgLat, longitude: mgLon)
    }

    /// GCJ02国内火星坐标系转换为WGS84国际坐标系
    open class func gcj02ToWgs84(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lon = coordinate.longitude
        let lat = coordinate.latitude
        let a = 6_378_245.0
        let ee = 0.00669342162296594323
        var dLat = transformLat(x: lon - 105.0, y: lat - 35.0)
        var dLon = transformLon(x: lon - 105.0, y: lat - 35.0)
        let radLat = lat / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)
        let mgLat = lat + dLat
        let mgLon = lon + dLon
        return .init(latitude: lat * 2 - mgLat, longitude: lon * 2 - mgLon)
    }

    private class func transformLat(x: Double, y: Double) -> Double {
        var lat: Double = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y
            + 0.2 * sqrt(fabs(x))
        lat += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        lat += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
        lat += (160.0 * sin(y / 12.0 * .pi) + 320 * sin(y * .pi / 30.0)) * 2.0 / 3.0
        return lat
    }

    private class func transformLon(x: Double, y: Double) -> Double {
        var lon = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1
            * sqrt(fabs(x))
        lon += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        lon += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
        lon += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
        return lon
    }

    /// 是否启用Always定位，默认NO，请求WhenInUse定位
    open var alwaysLocation: Bool = false

    /// 是否启用后台定位，默认NO。如果需要后台定位，设为YES即可
    open var backgroundLocation: Bool = false

    /// 是否启用方向监听，默认NO。如果设备不支持方向，则不能启用
    open var headingEnabled: Bool = false {
        didSet {
            if headingEnabled && !CLLocationManager.headingAvailable() {
                headingEnabled = false
            }
        }
    }

    /// 是否启用重要位置变化监听，默认NO。如果设备不支持，则不能启用
    open var monitoringEnabled: Bool = false {
        didSet {
            if monitoringEnabled && !CLLocationManager.significantLocationChangeMonitoringAvailable() {
                monitoringEnabled = false
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
    open var locationChanged: (@Sendable (LocationManager) -> Void)?

    /// 自定义定位开始处理句柄，可用于额外参数配置等
    open var customStartBlock: (@Sendable (CLLocationManager) -> Void)?

    /// 自定义定位结束处理句柄，可用于额外参数配置等
    open var customStopBlock: (@Sendable (CLLocationManager) -> Void)?

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
        customStartBlock?(locationManager)

        locationManager.startUpdatingLocation()
        if headingEnabled {
            locationManager.startUpdatingHeading()
        }
        if monitoringEnabled {
            locationManager.startMonitoringSignificantLocationChanges()
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
        customStopBlock?(locationManager)

        if monitoringEnabled {
            locationManager.stopMonitoringSignificantLocationChanges()
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
            if let oldLocation {
                userInfo[NSKeyValueChangeKey.oldKey] = oldLocation
            }
            if let newLocation {
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
            if let oldHeading {
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
