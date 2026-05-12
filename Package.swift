// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "uptcbot",
    platforms: [.macOS("26.0")],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm.git", from: "3.31.0"),
        .package(url: "https://github.com/huggingface/swift-huggingface.git", from: "0.9.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "UPTCBotKit",
            dependencies: [
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXVLM", package: "mlx-swift-lm"),
                .product(name: "MLXEmbedders", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ],
            path: "Sources/UPTCBotKit",
            resources: [
                .copy("Resources/programas_uptc.json"),
                .copy("Resources/analysis_docs.json"),
            ]
        ),
        .executableTarget(
            name: "uptcbot",
            dependencies: [
                "UPTCBotKit",
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ],
            path: "Sources/uptcbot"
        ),
        .executableTarget(
            name: "UPTCBotApp",
            dependencies: [
                "UPTCBotKit",
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ],
            path: "Sources/UPTCBotApp",
            resources: [
                .copy("Resources/logouptc.png"),
            ]
        ),
    ]
)
