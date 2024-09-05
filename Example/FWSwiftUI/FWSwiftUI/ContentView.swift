//
//  ContentView.swift
//  FWSwiftUI
//
//  Created by wuyong on 2024/4/26.
//

import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct ContentView: View {
    @State var activities = Activity<ExampleWidgetAttributes>.activities
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Create an activity to start a live activity")
                    
                    Button {
                        let attributes = ExampleWidgetAttributes(numberOfGroceyItems: 12)
                        let contentState = ExampleWidgetAttributes.ContentState(courierName: "Mike", deliveryTime: .now + 120)
                        
                        ActivityManager.createActivity(attributes: attributes, contentState: contentState) { token, error in
                            if let error {
                                print("error: \(error.localizedDescription)")
                            } else {
                                print("token: \(token ?? "")")
                            }
                        }
                        activities = ActivityManager.getAllActivities(of: ExampleWidgetAttributes.self)
                    } label: {
                        Text("Create Activity")
                            .font(.headline)
                    }
                    .tint(.green)
                    
                    Button {
                        activities = ActivityManager.getAllActivities(of: ExampleWidgetAttributes.self)
                    } label: {
                        Text("List All Activities")
                            .font(.headline)
                    }
                    .tint(.green)
                    
                    Button {
                        ActivityManager.endAllActivities(of: ExampleWidgetAttributes.self)
                        activities = ActivityManager.getAllActivities(of: ExampleWidgetAttributes.self)
                    } label: {
                        Text("End All Activites")
                            .font(.headline)
                    }
                    .tint(.green)
                }
                
                if !activities.isEmpty {
                    Section {
                        Text("Live Activities")
                        
                        ScrollView {
                            ForEach(activities, id: \.id) { activity in
                                HStack(alignment: .center) {
                                    Text(activity.contentState.courierName)
                                    
                                    Text(activity.contentState.deliveryTime, style: .timer)
                                    
                                    Text("update")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                        .onTapGesture {
                                            let contentState = ExampleWidgetAttributes.ContentState(courierName: "Adam", deliveryTime: .now + 150)
                                            
                                            ActivityManager.updateActivity(activity, using: contentState)
                                            activities = ActivityManager.getAllActivities(of: ExampleWidgetAttributes.self)
                                        }
                                    
                                    Text("end")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                        .onTapGesture {
                                            ActivityManager.endActivity(activity)
                                            activities = ActivityManager.getAllActivities(of: ExampleWidgetAttributes.self)
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("FWSwiftUI")
            .fontWeight(.ultraLight)
        }
    }
}

#Preview {
    if #available(iOS 16.1, *) {
        ContentView()
    }
}
