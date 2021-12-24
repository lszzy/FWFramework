// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FWFramework",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "FWFramework",
            targets: ["FWFramework"]),
        .library(
            name: "FWFrameworkSwift",
            targets: ["FWFramework", "FWFrameworkSwift"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FWFramework",
            path: "FWFramework/Classes/Objc",
            sources: [
                "Kernel",
                "Service",
                "Toolkit"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Kernel"),
                .headerSearchPath("Service"),
                .headerSearchPath("Toolkit"),
                .headerSearchPath("include")
            ]),
        .target(
            name: "FWFrameworkSwift",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Swift",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWFrameworkSwift")
            ]),
    ]
)
