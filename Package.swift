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
            name: "FWExtensionCalendar",
            targets: ["FWExtensionCalendar"]
        ),
        .library(
            name: "FWExtensionContacts",
            targets: ["FWExtensionContacts"]
        ),
        .library(
            name: "FWExtensionMicrophone",
            targets: ["FWExtensionMicrophone"]
        ),
        .library(
            name: "FWExtensionTracking",
            targets: ["FWExtensionTracking"]
        ),
        .library(
            name: "FWExtensionMacros",
            targets: ["FWExtensionMacros"]
        ),
        .library(
            name: "FWExtensionSDWebImage",
            targets: ["FWExtensionSDWebImage"]
        ),
        .library(
            name: "FWExtensionLottie",
            targets: ["FWExtensionLottie"]
        ),
        .library(
            name: "FWExtensionAlamofire",
            targets: ["FWExtensionAlamofire"]
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
            resources: [.process("../PrivacyInfo.xcprivacy")],
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
            name: "FWExtensionCalendar",
            dependencies: ["FWFramework"],
            path: "Sources/FWExtension/Calendar",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWExtensionContacts",
            dependencies: ["FWFramework"],
            path: "Sources/FWExtension/Contacts",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWExtensionMicrophone",
            dependencies: ["FWFramework"],
            path: "Sources/FWExtension/Microphone",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWExtensionTracking",
            dependencies: ["FWFramework"],
            path: "Sources/FWExtension/Tracking",
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
            path: "Sources/FWExtension/Macros/FWMacroMacros"
        ),
        .target(
            name: "FWExtensionMacros",
            dependencies: [
                "FWFramework",
                "FWMacroMacros",
            ],
            path: "Sources/FWExtension/Macros/FWExtensionMacros",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
                .define("FWExtensionMacros"),
            ]
        ),
        .target(
            name: "FWExtensionSDWebImage",
            dependencies: [
                "FWFramework",
                "SDWebImage",
            ],
            path: "Sources/FWExtension/SDWebImage",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWExtensionLottie",
            dependencies: [
                "FWFramework",
                .product(name: "Lottie", package: "lottie-ios"),
            ],
            path: "Sources/FWExtension/Lottie",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWExtensionAlamofire",
            dependencies: [
                "FWFramework",
                .product(name: "Alamofire", package: "Alamofire"),
            ],
            path: "Sources/FWExtension/Alamofire",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
    ]
)
