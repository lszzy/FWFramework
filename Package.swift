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
            name: "FWFrameworkCompatible",
            targets: ["FWFrameworkCompatible"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FWFramework",
            path: "FWFramework/Classes",
            sources: [
                "FWFramework/Kernel",
                "FWFramework/Service",
                "FWFramework/Toolkit"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("FWFramework/Kernel"),
                .headerSearchPath("FWFramework/Service"),
                .headerSearchPath("FWFramework/Toolkit"),
                .headerSearchPath("include"),
                .define("FWMacroSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]),
        .target(
            name: "FWFrameworkCompatible",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Compatible",
            cSettings: [
                .define("FWMacroSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]),
    ]
)
