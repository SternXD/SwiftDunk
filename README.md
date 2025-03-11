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

## Usage

### Basic Authentication

```swift
import SwiftDunk

// Initialize SwiftDunk
let config = SwiftDunk.Configuration(apiKey: "your-api-key")
let client = SwiftDunk(configuration: config)

// Authenticate
Task {
    do {
        // Get Anisette data first
        let anisetteData = try await client.anisette.getAnisetteData()
        
        // Authenticate with Apple ID
        let authResult = try await client.auth.authenticate(
            username: "your-apple-id@example.com",
            password: "your-password",
            anisetteData: anisetteData
        )
        
        print("Authentication successful!")
        print("Access Token: \(authResult.accessToken)")
    } catch {
        print("Authentication failed: \(error)")
    }
}
```

### Working with Developer Accounts

```swift
// List all developer accounts
Task {
    do {
        let accounts = try await client.accounts.listAccounts()
        for account in accounts {
            print("Account: \(account.name) (\(account.email))")
        }
    } catch {
        print("Failed to list accounts: \(error)")
    }
}
```

### Managing Apps

```swift
// Create a new app
Task {
    do {
        let newApp = AppCreationInfo(
            name: "My Awesome App",
            bundleId: "com.example.myawesomeapp",
            platform: .iOS,
            teamId: "TEAM123456"
        )
        
        let app = try await client.apps.createApp(newApp)
        print("App created with ID: \(app.id)")
    } catch {
        print("Failed to create app: \(error)")
    }
}
```

## Requirements

- Swift 5.7 or later
- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+

## License

This project is available under the MIT license. See the LICENSE file for more info.
