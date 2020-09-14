//
//  WebImage.swift
//  AppClip
//
//  Created by wuyong on 2020/9/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct WebImage: View {
    @State private var uiImage: UIImage? = nil
    var placeholderImage: UIImage = UIImage()
    var imageUrl: String?
    
    var body: some View {
        Image(uiImage: self.uiImage ?? placeholderImage)
            .resizable()
            .onAppear(perform: downloadWebImage)
            .frame(width: 80, height: 80, alignment: .center)
            .onTapGesture {
                print("Tap")
            }
            .navigationBarTitle(Text("WebImage"))
    }
    
    func downloadWebImage() {
        guard let urlString = imageUrl else { return }
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, let image = UIImage(data: data) {
                self.uiImage = image
            } else {
                print("error: \(String(describing: error))")
            }
        }
        .resume()
    }
}

@available(iOS 13.0, *)
struct WebImage_Previews: PreviewProvider {
    static var previews: some View {
        WebImage(placeholderImage: UIImage(named: "theme_image")!, imageUrl: "https://picsum.photos/50/50?i=30")
    }
}
