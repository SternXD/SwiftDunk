//
//  CryptoUtils.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation
import Crypto
import CommonCrypto

public struct CryptoUtils {
    /// Generate PBKDF2 key from password
    /// - Parameters:
    ///   - password: Password to derive key from
    ///   - salt: Salt for key derivation
    ///   - iterations: Number of iterations
    ///   - keyLength: Desired key length in bytes
    /// - Returns: Derived key
    public static func pbkdf2(
        password: String,
        salt: Data,
        iterations: Int,
        keyLength: Int
    ) -> Data {
        let passwordData = password.data(using: .utf8)!
        var derivedKeyData = Data(repeating: 0, count: keyLength)
        
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    password, passwordData.count,
                    saltBytes.baseAddress, salt.count,
                    CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(iterations),
                    derivedKeyBytes.baseAddress, keyLength
                )
            }
        }
        
        guard result == kCCSuccess else {
            fatalError("PBKDF2 computation failed")
        }
        
        return derivedKeyData
    }
    
    /// Generate random bytes
    /// - Parameter count: Number of random bytes to generate
    /// - Returns: Data containing random bytes
    public static func randomBytes(_ count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
    
    /// Hash data using SHA256
    /// - Parameter data: Data to hash
    /// - Returns: Hashed data
    public static func sha256(_ data: Data) -> Data {
        return Data(SHA256.hash(data: data))
    }
}