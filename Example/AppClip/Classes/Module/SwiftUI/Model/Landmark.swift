//
//  Landmark.swift
//  AppClip
//
//  Created by wuyong on 2020/8/26.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import CoreLocation

struct Landmark: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    fileprivate var imageName: String
    fileprivate var coordinates: Coordinates
    var state: String
    var park: String
    var category: Category
    var isFeatured: Bool
    var isFavorite: Bool
    
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
    
    var featureImage: Image? {
        guard isFeatured else { return nil }
        
        return Image(
            ImageStore.loadImage(name: "progressive.jpg"),
            scale: 2,
            label: Text(name))
    }
    
    enum Category: String, CaseIterable, Codable, Hashable {
        case featured = "Featured"
        case lakes = "Lakes"
        case rivers = "Rivers"
        case mountains = "Mountains"
    }
}

extension Landmark {
    var image: Image {
        ImageStore.shared.image(name: id % 2 == 0 ? "progressive.jpg" : "AccentImage")
    }
}

struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}
