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
            targets: ["FWFramework", "FWFrameworkCompatible"]),
        .library(
            name: "FWFrameworkAppleMusic",
            targets: ["FWFramework", "FWFrameworkAppleMusic"]),
        .library(
            name: "FWFrameworkCalendar",
            targets: ["FWFramework", "FWFrameworkCalendar"]),
        .library(
            name: "FWFrameworkContacts",
            targets: ["FWFramework", "FWFrameworkContacts"]),
        .library(
            name: "FWFrameworkMicrophone",
            targets: ["FWFramework", "FWFrameworkMicrophone"]),
        .library(
            name: "FWFrameworkTracking",
            targets: ["FWFramework", "FWFrameworkTracking"]),
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
                .headerSearchPath("include")
            ]),
        .target(
            name: "FWFrameworkCompatible",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Compatible",
            swiftSettings: [
                .define("DEBUG", .when(platforms: [.iOS], configuration: .debug)),
                .define("FWFrameworkCompatible")
            ]),
        .target(
            name: "FWFrameworkAppleMusic",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Component/AppleMusic",
            cSettings: [
                .define("FWFrameworkAppleMusic", to: "1")
            ]),
        .target(
            name: "FWFrameworkCalendar",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Component/Calendar",
            cSettings: [
                .define("FWFrameworkCalendar", to: "1")
            ]),
        .target(
            name: "FWFrameworkContacts",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Component/Contacts",
            cSettings: [
                .define("FWFrameworkContacts", to: "1")
            ]),
        .target(
            name: "FWFrameworkMicrophone",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Component/Microphone",
            cSettings: [
                .define("FWFrameworkMicrophone", to: "1")
            ]),
        .target(
            name: "FWFrameworkTracking",
            dependencies: ["FWFramework"],
            path: "FWFramework/Classes/Component/Tracking",
            cSettings: [
                .define("FWFrameworkTracking", to: "1")
            ]),
    ]
)
