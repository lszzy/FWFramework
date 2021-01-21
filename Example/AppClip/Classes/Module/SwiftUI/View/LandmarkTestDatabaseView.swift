//
//  LandmarkTestDatabaseView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/19.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import FWFramework

struct LandmarkTestDatabaseView: View {
    @State var itemList: [LandmarkTestTable] = []
    
    init() {
        FWDatabase.setVersion(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
    }
    
    var body: some View {
        List {
            ForEach(itemList, id: \.id) { item in
                Text("\(item.id)\npkid: \(item.pkid) id: \(item.id) name: \(item.name)\ninfo.id: \(item.info?.id ?? 0) infos.id: \(item.infos.count > 0 ? (item.infos.first?.id ?? 0) : 0)")
            }
            .onDelete(perform: { index in
                let item = itemList[index.first!]
                FWDatabase.delete(item)
                reloadData()
            })
            .onMove(perform: { from, to in
                if from.first! != to {
                    itemList.move(fromOffsets: from, toOffset: to)
                }
            })
        }
        .onAppear(perform: {
            reloadData()
        })
        .fwNavigationBarColor(backgroundColor: .tertiarySystemBackground)
        .navigationTitle("Database Test")
        .navigationBarItems(trailing: HStack {
            Button(action: {
                let item = LandmarkTestTable()
                let maxId = FWDatabase.query(LandmarkTestTable.self, func: "max(id)") as? Int ?? 0
                item.id = maxId + 1
                item.name = "name"
                let info = LandmarkTestTableInfo()
                info.id = item.id
                info.title = nil
                item.info = info
                item.infos = [info]
                FWDatabase.save(item)
                reloadData()
            }, label: {
                Image(systemName: "plus")
                    .imageScale(.large)
                    .padding()
            })
            
            EditButton()
        })
    }
    
    func reloadData() {
        itemList = FWDatabase.query(LandmarkTestTable.self) as! [LandmarkTestTable]
    }
}

struct LandmarkTestDatabaseView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkTestDatabaseView()
    }
}
