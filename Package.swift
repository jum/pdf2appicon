// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "pdf2appicon",
    dependencies: [
	.package(url: "https://github.com/kylef/Commander.git", from: "0.0.0"),
    ],
    targets: [
    	.target(
		name: "pdf2appicon",
		dependencies: ["Commander"],
		path: "."
	)
    ]
)

