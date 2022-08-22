// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FWFramework",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "FWObjC",
            targets: ["FWObjC"]),
        .library(
            name: "FWFramework",
            targets: ["FWFramework"]),
        .library(
            name: "FWSwiftUI",
            targets: ["FWSwiftUI"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FWObjC",
            path: "Sources",
            sources: ["FWObjC"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("FWObjC/Kernel"),
                .headerSearchPath("include"),
                .define("FWMacroSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]),
        .target(
            name: "FWFramework",
            dependencies: ["FWObjC"],
            path: "Sources/FWFramework",
            cSettings: [
                .define("FWMacroSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]),
        .target(
            name: "FWSwiftUI",
            dependencies: ["FWFramework"],
            path: "Sources/FWSwiftUI",
            cSettings: [
                .define("FWMacroSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]),
        .testTarget(
            name: "FWFrameworkTests",
            dependencies: ["FWFramework"],
            path: "Example/Tests",
            exclude: [
                "Info.plist"
            ],
            cSettings: [
                .define("FWMacroSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]),
    ]
)
