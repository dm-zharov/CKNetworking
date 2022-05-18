// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CKNetworking",
    defaultLocalization: "ru",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CKNetworking",
            targets: ["CKNetworking"]
        )
    ],
    targets: [
        .target(
            name: "CKNetworking"
        )
    ]
)
