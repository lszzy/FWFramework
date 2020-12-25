//
//  LandmarkLazyView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/25.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct LandmarkLazyView: View {
    
    @State var list = (0...40).map{_ in Item(number:Int.random(in: 1000...5000))}
    
    @State var loading = false
    
    var body: some View {
        VStack{
            Text("count:\(list.count)")
            //数据数量，在LazyVStack下数据在每次刷新后才会增加，在VStack下，数据会一直增加。
            ScrollView{
                LazyVStack{ //换成VStack作比较
                    ForEach(list, id:\.id){ item in
                        Text("ID: \(item.number)")
                            .onAppear {
                                moreItem(id: item.id)
                            }
                    }
                }
                if loading {
                    ProgressView()
                }
            }
        }
    }

    func moreItem(id:UUID){
       //如果是最后一个数据则获取新数据
        if id == list.last!.id && loading != true {
            loading = true
            //增加延时，模拟异步数据获取效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                //数据模拟，也可获取网络数据
                list.append(contentsOf: (0...30)
                            .map{_ in Item(number:Int.random(in: 1000...5000))})
                loading = false
            }
        }
    }
}

 struct Item:Identifiable{
    let id = UUID()
    let number:Int
}

struct LandmarkLazyView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkLazyView()
    }
}
