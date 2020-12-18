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
    "id": 1,
    "name": "name1",
    "info": { "id": 2, "title": "title2" },
    "infos": [{ "id": 3, "title": "title3" }, { "id": 4, "title": "title4" }]
}
"""
                guard let codableData = codableString.data(using: .utf8) else { return }
                guard let codableObject = try? JSONDecoder().decode(LandmarkTestData.self, from: codableData) else { return }
                guard let jsonData = try? JSONEncoder().encode(codableObject) else { return }
                guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
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
