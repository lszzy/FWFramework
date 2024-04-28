//
//  ContentView.swift
//  FWSwiftUI
//
//  Created by wuyong on 2024/4/26.
//

import SwiftUI
import FWFramework
import FWSwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
            
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            print("View onAppear")
        }
        .onDisappear {
            print("View onDisappear")
        }
    }
}

#Preview {
    ContentView()
}
