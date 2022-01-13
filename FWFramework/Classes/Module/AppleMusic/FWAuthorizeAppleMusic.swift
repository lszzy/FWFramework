//
//  FWAuthorizeAppleMusic.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import MediaPlayer
#if FWFrameworkSPM
import FWFramework
#endif

/// AppleMusic授权
private class FWAuthorizeAppleMusic: NSObject, FWAuthorizeProtocol {
    func authorizeStatus() -> FWAuthorizeStatus {
        let status = MPMediaLibrary.authorizationStatus()
        switch status {
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorized:
            return .authorized
        default:
            return .notDetermined
        }
    }
    
    func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        MPMediaLibrary.requestAuthorization { status in
            if completion != nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    completion?(self.authorizeStatus())
                }
            }
        }
    }
}

@objc extension FWLoader {
    private func loadFWAuthorizeAppleMusic() {
        FWAuthorizeManager.registerAuthorize(.appleMusic) {
            return FWAuthorizeAppleMusic()
        }
    }
}
