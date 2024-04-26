// swift-tools-version:5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "FWFramework",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "FWFramework",
            targets: ["FWFramework"]
        ),
        .library(
            name: "FWSwiftUI",
            targets: ["FWSwiftUI"]
        ),
        .library(
            name: "FWVendor",
            targets: [
                "FWVendorSDWebImage",
                "FWVendorLottie",
                "FWVendorAlamofire",
            ]
        ),
        .library(
            name: "FWMacro",
            targets: ["FWMacro"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.9.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .target(
            name: "FWFramework",
            path: "Sources/FWFramework",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWSwiftUI",
            dependencies: ["FWFramework"],
            path: "Sources/FWSwiftUI",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWVendorSDWebImage",
            dependencies: [
                "FWFramework",
                "SDWebImage",
            ],
            path: "Sources/FWVendor/SDWebImage",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWVendorLottie",
            dependencies: [
                "FWFramework",
                .product(name: "Lottie", package: "lottie-ios"),
            ],
            path: "Sources/FWVendor/Lottie",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWVendorAlamofire",
            dependencies: [
                "FWFramework",
                .product(name: "Alamofire", package: "Alamofire"),
            ],
            path: "Sources/FWVendor/Alamofire",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .macro(
            name: "FWMacroMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Macros/FWMacroMacros"
        ),
        .target(
            name: "FWMacro",
            dependencies: ["FWMacroMacros"],
            path: "Macros/FWMacro"
        ),
    ]
)
