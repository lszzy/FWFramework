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
    
    init() {}
    
    init(from decoder: Decoder) throws {
        id = try decoder.fwDecodeJson("id").intValue
        name = try decoder.fwDecodeJson("name").stringValue
        info = try decoder.fwDecode("info")
        infos = try decoder.fwDecode("infos")
    }
}

struct LandmarkTestInfo: Codable {
    var id: Int = 0
    var title: String = ""
    
    init() {}
    
    init(from decoder: Decoder) throws {
        id = try decoder.fwDecodeJson("id").intValue
        title = try decoder.fwDecodeJson("name").stringValue
    }
}
