// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoreBluetoothMock",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "CoreBluetoothMock",
            targets: ["CoreBluetoothMockWrapper"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.24.2"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.4.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.33.1"),
    ],
    targets: [
        .binaryTarget(
            name: "CoreBluetoothMockBinary",
            url: "https://github.com/tochy0115/CoreBluetoothMock/releases/download/1.0.2/CoreBluetoothMock.xcframework.zip",
            checksum: "3f1af9f1cfec63b0dc0d185d5d313c131d4fe1738bc197b93e7bea2c9de9b395"
        ),
        .target(
            name: "CoreBluetoothMockWrapper",
            dependencies: [
                "CoreBluetoothMockBinary",
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            path: "Sources/CoreBluetoothMockWrapper"
        ),
    ]
)
