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
    var info: LandmarkTestInfo?
    var infos: [LandmarkTestInfo] = []
    
    init(from decoder: Decoder) throws {
        id = try decoder.fwJson("id").intValue
        name = try decoder.fwJson("name").stringValue
        info = try decoder.fwDecodeIf("info")
        infos = try decoder.fwDecode("infos")
    }
}

struct LandmarkTestInfo: Codable {
    var id: Int = 0
    var title: String?
    
    init(from decoder: Decoder) throws {
        id = try decoder.fwJson("id").intValue
        title = try decoder.fwJsonIf("title")?.string ?? decoder.fwJsonIf("name")?.string
    }
}
