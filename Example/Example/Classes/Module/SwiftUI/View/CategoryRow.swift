//
//  CategoryRow.swift
//  AppClip
//
//  Created by wuyong on 2020/8/27.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct CategoryRow: View {
    var categoryName: String
    var items: [Landmark]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(self.categoryName)
                .font(.headline)
                .padding(.leading, 15)
                .padding(.top, 5)
            
            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack(alignment: .top, spacing: 0, content: {
                    ForEach(self.items) { landmark in
                        NavigationLink(
                            destination: LandmarkDetail(landmark: landmark),
                            label: {
                                CategoryItem(landmark: landmark)
                            })
                    }
                })
                .padding(.trailing, 15)
            })
            .frame(height: 185)
        }
    }
}

@available(iOS 13.0, *)
struct CategoryItem: View {
    var landmark: Landmark
    var body: some View {
        VStack(alignment: .leading) {
            landmark.image
                .renderingMode(.original)
                .resizable()
                .frame(width: 155, height: 155)
                .cornerRadius(5)
            Text(landmark.name)
                .foregroundColor(.primary)
                .font(.caption)
        }
        .padding(.leading, 15)
    }
}

@available(iOS 13.0, *)
struct CategoryRow_Previews: PreviewProvider {
    static var previews: some View {
        CategoryRow(
            categoryName: landmarkData[0].category.rawValue,
            items: Array(landmarkData.prefix(4))
        )
        .environmentObject(UserData())
    }
}
