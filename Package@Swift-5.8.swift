// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "FWFramework",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
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
            name: "FWPluginModule",
            targets: ["FWPluginModule"]
        ),
        .library(
            name: "FWPluginCalendar",
            targets: ["FWPluginCalendar"]
        ),
        .library(
            name: "FWPluginContacts",
            targets: ["FWPluginContacts"]
        ),
        .library(
            name: "FWPluginMicrophone",
            targets: ["FWPluginMicrophone"]
        ),
        .library(
            name: "FWPluginTracking",
            targets: ["FWPluginTracking"]
        ),
        .library(
            name: "FWPluginBiometry",
            targets: ["FWPluginBiometry"]
        ),
        .library(
            name: "FWPluginSDWebImage",
            targets: ["FWPluginSDWebImage"]
        ),
        .library(
            name: "FWPluginLottie",
            targets: ["FWPluginLottie"]
        ),
        .library(
            name: "FWPluginAlamofire",
            targets: ["FWPluginAlamofire"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.9.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "FWFramework",
            path: "Sources/FWFramework",
            resources: [.copy("../PrivacyInfo.xcprivacy")],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWSwiftUI",
            dependencies: ["FWFramework"],
            path: "Sources/FWSwiftUI",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginModule",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Module",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginCalendar",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Calendar",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginContacts",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Contacts",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginMicrophone",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Microphone",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginTracking",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Tracking",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginBiometry",
            dependencies: ["FWFramework"],
            path: "Sources/FWPlugin/Biometry",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginSDWebImage",
            dependencies: [
                "FWFramework",
                .product(name: "SDWebImage", package: "SDWebImage")
            ],
            path: "Sources/FWPlugin/SDWebImage",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginLottie",
            dependencies: [
                "FWFramework",
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Sources/FWPlugin/Lottie",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        ),
        .target(
            name: "FWPluginAlamofire",
            dependencies: [
                "FWFramework",
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/FWPlugin/Alamofire",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWMacroSPM")
            ]
        )
    ]
)
