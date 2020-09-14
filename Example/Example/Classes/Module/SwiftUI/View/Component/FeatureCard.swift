/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows a featured landmark.
*/

import SwiftUI

@available(iOS 13.0, *)
struct FeatureCard: View {
    var landmark: Landmark
    
    var body: some View {
        landmark.featureImage?
            .resizable()
            .overlay(TextOverlay(landmark: landmark))
            //.aspectRatio(3 / 2, contentMode: .fit)
    }
}

@available(iOS 13.0, *)
struct TextOverlay: View {
    var landmark: Landmark
    
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(
                colors: [Color.black.opacity(0.6), Color.black.opacity(0)]),
            startPoint: .bottom,
            endPoint: .center)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle().fill(gradient)
            VStack(alignment: .leading) {
                Text(landmark.name)
                    .font(.title)
                    .bold()
                Text(landmark.park)
            }
            .padding()
        }
        .foregroundColor(.white)
    }
}

@available(iOS 13.0, *)
struct FeatureCard_Previews: PreviewProvider {
    static var previews: some View {
        FeatureCard(landmark: features[0])
    }
}
