//
//  LandmarkTestData.swift
//  AppClip
//
//  Created by wuyong on 2020/12/18.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import FWFramework

struct LandmarkTestData: Codable, Hashable, Identifiable {
    var id: Int
    var name: String
    var info: LandmarkTestInfo?
    var infos: [LandmarkTestInfo] = []
    
    init(from decoder: Decoder) throws {
        id = try decoder.fwValue("id")
        name = try decoder.fwValue("name")
        info = try decoder.fwValueIf("info")
        infos = try decoder.fwValue("infos")
    }
}

struct LandmarkTestInfo: Codable, Hashable {
    var id: Int = 0
    var title: String?
    
    init(from decoder: Decoder) throws {
        id = try decoder.fwValue("id")
        title = try decoder.fwValueIf("title") ?? decoder.fwValueIf("name")
    }
}
