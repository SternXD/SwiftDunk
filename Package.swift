// swift-tools-version: 6.0.0
import PackageDescription

let package = Package(
    name: "SwiftDunk",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SwiftDunk",
            targets: ["SwiftDunk"]
        ),
    ],
    dependencies: [
        // Use a specific version range compatible with SRP
        .package(url: "https://github.com/apple/swift-crypto.git", "1.1.0"..<"2.0.0"),
        
        // Use SRP with the compatible swift-crypto version
        .package(url: "https://github.com/Bouke/SRP", from: "3.2.0"),
        
        // Alamofire for networking
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.7.1"),
    ],
    targets: [
        .target(
            name: "SwiftDunk",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "SRP", package: "SRP"),
                "Alamofire",
            ]
        ),
        .testTarget(
            name: "SwiftDunkTests",
            dependencies: ["SwiftDunk"]
        ),
    ]
)
