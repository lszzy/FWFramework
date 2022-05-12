//
//  FWAuthorizeMicrophone.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import AVFoundation
#if FWFrameworkSPM
import FWFramework
import FWFrameworkCompatible
#endif

/// 麦克风授权
@objcMembers public class FWAuthorizeMicrophone: NSObject, FWAuthorizeProtocol, FWAutoloadProtocol {
    public static func autoload() {
        FWAuthorizeManager.registerAuthorize(.microphone) {
            return FWAuthorizeMicrophone()
        }
    }
    
    public func authorizeStatus() -> FWAuthorizeStatus {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .denied:
            return .denied
        case .granted:
            return .authorized
        default:
            return .notDetermined
        }
    }
    
    public func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            let status: FWAuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
    }
}
