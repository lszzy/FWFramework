//
//  FWCoroutine.swift
//  FWFramework
//
//  Created by wuyong on 2019/9/24.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

extension FWCoroutine: FWCoroutineClosureCaller {
    @objc public static func call(withClosure closure: Any, completion: @escaping FWCoroutineCallback) {
        (closure as? FWCoroutineClosure)?(completion)
    }
}
