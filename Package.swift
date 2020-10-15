// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "FWFramework",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "FWFramework",
            targets: ["FWFramework"]
        ),
    ],
    targets: [
        .target(
            name: "FWFramework",
            dependencies: [],
            path: "FWFramework",
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("."),
            ]
        ),
    ]
)
