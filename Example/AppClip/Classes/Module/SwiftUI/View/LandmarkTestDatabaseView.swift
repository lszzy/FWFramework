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
                Text("\(item.id)")
            }
            .onDelete(perform: { index in
                let item = itemList[index.first!]
                FWDatabase.delete(LandmarkTestTable.self, where: "id = \(item.id)")
                loadData()
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
                let lastItem = FWDatabase.query(LandmarkTestTable.self, order: "by pkid desc", limit: "1").first as? LandmarkTestTable
                let item = LandmarkTestTable()
                item.id = lastItem != nil ? lastItem!.id + 1 : 1;
                item.name = "name"
                let info = LandmarkTestTableInfo()
                info.id = item.id
                info.title = nil
                item.info = info
                item.infos = [info]
                FWDatabase.insert(item)
                
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
        itemList = FWDatabase.query(LandmarkTestTable.self) as! [LandmarkTestTable]
    }
}

struct LandmarkTestDatabaseView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkTestDatabaseView()
    }
}
