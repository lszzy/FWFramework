//
//  FWIterator.swift
//  FWFramework
//
//  Created by wuyong on 2019/9/24.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

extension FWIterator: FWAsyncClosureCaller {
    @objc public static func call(withClosure closure: Any, completion: @escaping FWAsyncCallback) {
        (closure as? FWAsyncClosure)?(completion)
    }
}
