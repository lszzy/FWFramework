//
//  LandmarkTestDataView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/18.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct LandmarkTestDataView: View {
    @State var text: String = ""
    
    var body: some View {
        VStack {
            Text(text)
            
            Button("Codable") {
                let codableString = """
{
    "id": true,
    "name": "name1",
    "info": { "id": 2, "title": "title2" },
    "infos": [{ "id": "3", "title": "title3" }, { "id": 4.4, "title": "title4" }]
}
"""
                guard let codableObject = try? codableString.fwUTF8Data?.fwDecoded() as LandmarkTestData? else {
                    text = "decode error"
                    return
                }
                guard let jsonString = try? codableObject.fwEncoded().fwUTF8String else {
                    text = "encode error"
                    return
                }
                text = jsonString
            }
        }
    }
}

struct LandmarkTestDataView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkTestDataView()
    }
}
