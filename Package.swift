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
        .library(
            name: "FWFrameworkAppleMusic",
            targets: ["FWFrameworkAppleMusic"]),
        .library(
            name: "FWFrameworkCalendar",
            targets: ["FWFrameworkCalendar"]),
        .library(
            name: "FWFrameworkContacts",
            targets: ["FWFrameworkContacts"]),
        .library(
            name: "FWFrameworkMicrophone",
            targets: ["FWFrameworkMicrophone"]),
        .library(
            name: "FWFrameworkTracking",
            targets: ["FWFrameworkTracking"]),
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
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkCompatible",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Module/Compatible",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkAppleMusic",
            dependencies: ["FWFrameworkCompatible"],
            path: "FWFramework/Classes/Module/AppleMusic",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkCalendar",
            dependencies: ["FWFrameworkCompatible"],
            path: "FWFramework/Classes/Module/Calendar",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkContacts",
            dependencies: ["FWFrameworkCompatible"],
            path: "FWFramework/Classes/Module/Contacts",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkMicrophone",
            dependencies: ["FWFrameworkCompatible"],
            path: "FWFramework/Classes/Module/Microphone",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
        .target(
            name: "FWFrameworkTracking",
            dependencies: ["FWFrameworkCompatible"],
            path: "FWFramework/Classes/Module/Tracking",
            cSettings: [
                .define("FWFrameworkSPM", to: "1")
            ],
            swiftSettings: [
                .define("FWFrameworkSPM")
            ]),
    ]
)
