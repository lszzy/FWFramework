/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays a rotated version of a badge symbol.
*/

import SwiftUI

@available(iOS 13.0, *)
struct RotatedBadgeSymbol: View {
    let angle: Angle
    
    var body: some View {
        BadgeSymbol()
        .padding(-60)
        .rotationEffect(angle, anchor: .bottom)
    }
}

@available(iOS 13.0, *)
struct RotatedBadgeSymbol_Previews: PreviewProvider {
    static var previews: some View {
        RotatedBadgeSymbol(angle: .init(degrees: 5))
    }
}
