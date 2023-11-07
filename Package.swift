// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FWFramework",
    platforms: [
        .iOS(.v13)
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
        .library(
            name: "FWVendor",
            targets: ["FWVendorSDWebImage", "FWVendorLottie"])
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.9.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "FWObjC",
            path: "Sources",
            sources: ["FWObjC"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/FWObjC"),
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
        .target(
            name: "FWVendorSDWebImage",
            dependencies: [
                "FWFramework",
                "SDWebImage"
            ],
            path: "Sources/FWVendor/SDWebImage",
            cSettings: [
                .define("FWMacroSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]),
        .target(
            name: "FWVendorLottie",
            dependencies: [
                "FWFramework",
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Sources/FWVendor/Lottie",
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
