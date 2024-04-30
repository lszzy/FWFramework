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
            name: "FWComponentCalendar",
            targets: ["FWComponentCalendar"]
        ),
        .library(
            name: "FWComponentContacts",
            targets: ["FWComponentContacts"]
        ),
        .library(
            name: "FWComponentMicrophone",
            targets: ["FWComponentMicrophone"]
        ),
        .library(
            name: "FWComponentTracking",
            targets: ["FWComponentTracking"]
        ),
        .library(
            name: "FWComponentMacros",
            targets: ["FWComponentMacros"]
        ),
        .library(
            name: "FWComponentSDWebImage",
            targets: ["FWComponentSDWebImage"]
        ),
        .library(
            name: "FWComponentLottie",
            targets: ["FWComponentLottie"]
        ),
        .library(
            name: "FWComponentAlamofire",
            targets: ["FWComponentAlamofire"]
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
            name: "FWComponentCalendar",
            dependencies: ["FWFramework"],
            path: "Sources/FWComponent/Calendar",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWComponentContacts",
            dependencies: ["FWFramework"],
            path: "Sources/FWComponent/Contacts",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWComponentMicrophone",
            dependencies: ["FWFramework"],
            path: "Sources/FWComponent/Microphone",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWComponentTracking",
            dependencies: ["FWFramework"],
            path: "Sources/FWComponent/Tracking",
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
            path: "Sources/FWComponent/Macros/FWMacroMacros"
        ),
        .target(
            name: "FWComponentMacros",
            dependencies: [
                "FWFramework",
                "FWMacroMacros",
            ],
            path: "Sources/FWComponent/Macros/FWComponentMacros",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
                .define("FWComponentMacros"),
            ]
        ),
        .target(
            name: "FWComponentSDWebImage",
            dependencies: [
                "FWFramework",
                .product(name: "SDWebImage", package: "SDWebImage"),
            ],
            path: "Sources/FWComponent/SDWebImage",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWComponentLottie",
            dependencies: [
                "FWFramework",
                .product(name: "Lottie", package: "lottie-ios"),
            ],
            path: "Sources/FWComponent/Lottie",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
        .target(
            name: "FWComponentAlamofire",
            dependencies: [
                "FWFramework",
                .product(name: "Alamofire", package: "Alamofire"),
            ],
            path: "Sources/FWComponent/Alamofire",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM"),
            ]
        ),
    ]
)
