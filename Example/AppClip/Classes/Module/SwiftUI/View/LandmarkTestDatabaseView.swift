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
    
    var body: some View {
        List {
            ForEach(itemList, id: \.id) { item in
                Text("\(item.id)\npkid: \(item.pkid) id: \(item.id) name: \(item.name)\ninfo.id: \(item.info?.id ?? 0) infos.id: \(item.infos.count > 0 ? (item.infos.first?.id ?? 0) : 0)")
            }
            .onDelete(perform: { index in
                let item = itemList[index.first!]
                itemList.remove(at: index.first!)
                FWDatabase.delete(LandmarkTestTable.self, where: "id = \(item.id)")
            })
            .onMove(perform: { from, to in
                if from.first! != to {
                    itemList.move(fromOffsets: from, toOffset: to)
                }
            })
        }
        .onAppear(perform: {
            if itemList.count < 1 {
                itemList = FWDatabase.query(LandmarkTestTable.self) as! [LandmarkTestTable]
            }
        })
        .navigationBarItems(trailing: HStack {
            Button(action: {
                let lastItem = FWDatabase.query(LandmarkTestTable.self, order: "by pkid desc", limit: "1").first as? LandmarkTestTable
                
                let item = LandmarkTestTable()
                item.id = lastItem != nil ? lastItem!.id + 1 : 1;
                item.name = "name"
                let info = LandmarkTestTableInfo()
                info.id = item.id
                info.title = nil
                item.info = info
                item.infos = [info]
                item.pkid = FWDatabase.insert(item)
                
                itemList.append(item)
            }, label: {
                Image(systemName: "plus")
                    .imageScale(.large)
                    .padding()
            })
            
            EditButton()
        })
    }
}

struct LandmarkTestDatabaseView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkTestDatabaseView()
    }
}
