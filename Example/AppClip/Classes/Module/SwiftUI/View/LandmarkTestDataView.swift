//
//  LandmarkTestDataView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/18.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct LandmarkTestDataView: View {
    @State var itemList: [LandmarkTestData] = []
    @State private var index: Int = 0
    
    var body: some View {
        List {
            ForEach(itemList) { item in
                let text = try? item.fwEncoded().fwUTF8String
                Text("\(item.id)\n\(text ?? "")")
            }
            .onDelete(perform: { index in
                itemList.remove(at: index.first!)
            })
            .onMove(perform: { from, to in
                if from.first! != to {
                    itemList.move(fromOffsets: from, toOffset: to)
                }
            })
        }
        .onAppear(perform: {
            if itemList.count < 1 {
                loadData()
            }
        })
        .navigationBarItems(trailing: HStack {
            Button(action: {
                loadData()
            }, label: {
                Image(systemName: "plus")
                    .imageScale(.large)
                    .padding()
            })
            
            EditButton()
        })
    }
    
    func loadData() {
        index = index + 1
        let codableString = """
{
"id": \(index),
"name": "name1",
"info": { "id": true, "title": "title2" },
"infos": [{ "id": "3", "name": "title3" }, { "id": 4.4, "name": 4 }]
}
"""
        guard let codableObject = try? codableString.fwUTF8Data?.fwDecoded() as LandmarkTestData? else { return }
        itemList.append(codableObject)
    }
}

struct LandmarkTestDataView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkTestDataView()
    }
}
