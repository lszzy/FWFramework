//
//  LandmarkTestData.swift
//  AppClip
//
//  Created by wuyong on 2020/12/18.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import FWFramework

struct LandmarkTestData: Codable {
    var id: Int = 0
    var name: String = ""
    var info: LandmarkTestInfo = LandmarkTestInfo()
    var infos: [LandmarkTestInfo] = []
}

struct LandmarkTestInfo: Codable {
    var id: Int = 0
    var title: String = ""
}
