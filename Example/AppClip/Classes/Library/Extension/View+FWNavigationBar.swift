//
//  View+FWNavigationBar.swift
//  AppClip
//
//  Created by wuyong on 2020/12/12.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct FWNavigationBarModifier: ViewModifier {
    
    var backgroundColor: UIColor?
    var titleColor: UIColor?

    init(backgroundColor: UIColor?, titleColor: UIColor?) {
        self.backgroundColor = backgroundColor
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = backgroundColor ?? .clear
        
        if let titleColor = titleColor {
            coloredAppearance.titleTextAttributes = [.foregroundColor: titleColor]
            coloredAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
            UINavigationBar.appearance().tintColor = titleColor
        }
        
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }

    func body(content: Content) -> some View {
        ZStack{
            content
            VStack {
                GeometryReader { geometry in
                    Color(self.backgroundColor ?? .clear)
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
        }
    }
}

extension View {

    func fwNavigationBarColor(backgroundColor: UIColor?, titleColor: UIColor?) -> some View {
        self.modifier(FWNavigationBarModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }
}

