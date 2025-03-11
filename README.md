# SwiftDunk

A Swift package for communicating with Apple's Grand Slam Authentication and related APIs.

This package is a Swift port of [PyDunk](https://github.com/nythepegasus/PyDunk), converting the Python implementation to Swift with full compatibility with Apple platforms.

## Features

- Apple Grand Slam Authentication API client
- Anisette data handling for authentication
- Developer account management
- App, device, and team management interfaces
- Xcode-related functionality

## Installation

### Swift Package Manager

Add SwiftDunk as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/SternXD/SwiftDunk.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Go to File > Add Packages...
2. Enter the repository URL: `https://github.com/YourUsername/SwiftDunk.git`
3. Choose the version constraints
4. Click "Add Package"

## Requirements

- Swift 6.0 or later
- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+

## License

This project is available under the MIT license. See the LICENSE file for more info.
