//
//  ContentView.swift
//  FWSwiftUI
//
//  Created by wuyong on 2024/4/26.
//

import SwiftUI
import FWFramework
import FWSwiftUI
import FWExtensionCalendar
import FWExtensionContacts
import FWExtensionMicrophone
import FWExtensionTracking
import FWExtensionMacros
import FWExtensionSDWebImage
import FWExtensionLottie
import FWExtensionAlamofire

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
            
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
