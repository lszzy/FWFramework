//
//  LandmarkTestTable.swift
//  AppClip
//
//  Created by wuyong on 2020/12/19.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import Foundation

@objcMembers
class LandmarkTestTable: NSObject {
    var pkid: Int = 0
    var id: Int = 0
    var name: String = ""
    var info: LandmarkTestTableInfo?
    var infos: [LandmarkTestTableInfo] = []
}

@objcMembers
class LandmarkTestTableInfo: NSObject, NSCoding {
    var id: Int = 0
    var title: String?
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        id = coder.decodeInteger(forKey: "id")
        title = coder.decodeObject(forKey: "title") as? String
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(title, forKey: "title")
    }
}
