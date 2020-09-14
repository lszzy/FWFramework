//
//  MapView.swift
//  AppClip
//
//  Created by wuyong on 2020/8/26.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import MapKit

@available(iOS 13.0, *)
struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView
    
    var coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        return MKMapView(frame: .zero)
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        uiView.setRegion(region, animated: true)
    }
}

@available(iOS 13.0, *)
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(coordinate: landmarkData[0].locationCoordinate)
    }
}
