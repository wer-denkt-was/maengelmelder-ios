// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Maengelmelder",
    defaultLocalization: "de",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Maengelmelder",
            targets: ["Maengelmelder"]),
    ],
    dependencies: [
            .package(url: "https://github.com/JonasGessner/JGProgressHUD", from: "2.2.0"),
            .package(url: "https://github.com/Alamofire/AlamofireImage", from: "4.3.0"),
            .package(url: "https://github.com/aromajoin/material-showcase-ios", from: "0.8.0"),
            .package(url: "https://github.com/Marxon13/M13Checkbox.git", from: "3.4.1"),
            .package(url: "https://github.com/jonkykong/SideMenu.git", from: "6.5.0"),
            .package(url: "https://github.com/Timetoast-22/FSPagerView", from: "0.9.0"),
            .package(url: "https://github.com/Timetoast-22/Reachability.swift", from: "5.2.3"),
            .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.3")
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Maengelmelder",
            dependencies: [
                .product(name: "JGProgressHUD", package: "JGProgressHUD"),
                .product(name: "AlamofireImage", package: "AlamofireImage"),
                .product(name: "MaterialShowcase", package: "material-showcase-ios"),
                .product(name: "M13Checkbox", package: "M13Checkbox"),
                .product(name: "SideMenu", package: "SideMenu"),
                .product(name: "FSPagerView", package: "FSPagerView"),
                .product(name: "Reachability", package: "Reachability.swift"),
                .product(name: "SQLite", package: "SQLite.swift")
                ]),
        .testTarget(
            name: "MaengelmelderTests",
            dependencies: ["Maengelmelder"]),
    ]
)
