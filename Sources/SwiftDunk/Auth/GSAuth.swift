//
//  GSAuth.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation
import CryptoKit
import SRP

/// GSAuth - Grand Slam Authentication handler for Apple services
public class GSAuth {
    private let baseUrl = "https://gsa.apple.com/grandslam/"
    private let infoBaseUrl = "https://gsas.apple.com/grandslam/"
    private let baseAuthUrl: String
    
    private let anisette: Anisette
    private let urlSession: URLSession
    
    /// Initialize with optional anisette data provider and URL session
    /// - Parameters:
    ///   - anisette: Optional anisette data provider
    ///   - urlSession: Optional URL session to use for requests
    public init(anisette: Anisette? = nil, urlSession: URLSession? = nil) {
        self.baseAuthUrl = baseUrl + "GsService2"
        self.anisette = anisette ?? Anisette(urlSession: urlSession)
        self.urlSession = urlSession ?? URLSession.shared
    }
    
    /// Base authentication headers
    private var baseAuthHeaders: [String: String] {
        var headers = anisette.headers(includeUser: true)
        headers["Content-Type"] = "text/x-xml-plist"
        headers["Accept"] = "*/*"
        headers["User-Agent"] = "akd/1.0 CFNetwork/978.0.7 Darwin/18.7.0"
        headers["Accept-Language"] = "en-us"
        return headers
    }
    
    /// Authentication headers with identity token
    /// - Parameter identityToken: Identity token for authentication
    /// - Returns: Headers with identity token
    private func authHeaders(identityToken: String) -> [String: String] {
        var headers = baseAuthHeaders
        headers["X-Apple-Identity-Token"] = identityToken
        return headers
    }
    
    /// Base authentication body
    private var baseAuthBody: [String: Any] {
        return [
            "Header": [
                "Version": "1.0.1"
            ],
            "Request": [
                "cpd": anisette.cpd
            ]
        ]
    }
    
    /// Base authentication body with additional parameters
    /// - Parameter params: Additional parameters to include
    /// - Returns: Authentication body with parameters
    private func baseAuthBodyParams(_ params: [String: Any]) -> [String: Any] {
        var body = baseAuthBody
        if var request = body["Request"] as? [String: Any] {
            for (key, value) in params {
                request[key] = value
            }
            body["Request"] = request
        }
        return body
    }
    
    /// Check for errors in response
    /// - Parameter response: Response dictionary
    /// - Returns: Whether there was an error
    private func checkError(_ response: [String: Any]) -> Bool {
        let status: [String: Any]
        if let statusDict = response["Status"] as? [String: Any] {
            status = statusDict
        } else {
            status = response
        }
        
        if let ec = status["ec"] as? Int, ec != 0 {
            let errorMessage = status["em"] as? String ?? "Unknown error"
            print("Error \(ec): \(errorMessage)")
            return true
        }
        return false
    }
    
    /// Encrypt password using PBKDF2
    /// - Parameters:
    ///   - password: Clear text password
    ///   - salt: Salt for key derivation
    ///   - iterations: Number of iterations
    /// - Returns: Derived key
    private func encryptPassword(password: String, salt: Data, iterations: Int) -> Data {
        let passwordHash = SHA256.hash(data: password.data(using: .utf8)!)
        return pbkdf2(password: Data(passwordHash), salt: salt, iterations: iterations, keyLength: 32)
    }
    
    /// Create session key using HMAC
    /// - Parameters:
    ///   - srpClient: SRP client with session key
    ///   - name: Name to use for key derivation
    /// - Returns: Derived session key
    private func createSessionKey(srpClient: SRPClient, name: String) -> Data {
        guard let sessionKey = srpClient.sessionKey else {
            fatalError("Expected a session key from SRP client")
        }
        
        let hmac = HMAC<SHA256>.authenticationCode(
            for: name.data(using: .utf8)!,
            using: SymmetricKey(data: sessionKey)
        )
        return Data(hmac)
    }
    
    /// Decrypt data using AES-CBC
    /// - Parameters:
    ///   - srpClient: SRP client with session key
    ///   - data: Data to decrypt
    /// - Returns: Decrypted data
    private func decryptCBC(srpClient: SRPClient, data: Data) -> Data {
        let keyData = createSessionKey(srpClient: srpClient, name: "extra data key:")
        let ivData = createSessionKey(srpClient: srpClient, name: "extra data iv:")
        let iv = ivData.prefix(16)
        
        let key = SymmetricKey(data: keyData)
        let sealedBox = try! AES.CBC.SealedBox(nonce: AES.CBC.Nonce(data: iv), 
                                              ciphertext: data)
        
        // Use CryptoKit for AES-CBC decryption
        let decrypted = try! AES.CBC.open(sealedBox, using: key)
        
        // Remove PKCS#7 padding
        let paddingSize = Int(decrypted.last ?? 0)
        if paddingSize > 0 && paddingSize <= 16 {
            return decrypted.dropLast(paddingSize)
        }
        return decrypted
    }
    
    /// Decrypt data using AES-GCM
    /// - Parameters:
    ///   - data: Data to decrypt
    ///   - sessionKey: Session key for decryption
    /// - Returns: Decrypted data, or nil if decryption fails
    private func decryptGCM(data: Data, sessionKey: Data?) -> Data? {
        guard let sessionKey = sessionKey, data.count >= 35 else { return nil }
        
        let versionSize = 3
        let ivSize = 16
        let tagSize = 16
        let decryptedSize = data.count - (versionSize + ivSize + tagSize)
        
        guard decryptedSize > 0 else { return nil }
        
        let version = data.prefix(versionSize)
        let iv = data.subdata(in: versionSize..<(versionSize + ivSize))
        let ciphertext = data.subdata(in: (versionSize + ivSize)..<(data.count - tagSize))
        let tag = data.suffix(tagSize)
        
        do {
            let key = SymmetricKey(data: sessionKey)
            let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: iv),
                                                ciphertext: ciphertext,
                                                tag: tag)
            return try AES.GCM.open(sealedBox, using: key, authenticating: version)
        } catch {
            return nil
        }
    }
    
    /// Perform user info request
    /// - Returns: User info response
    private func userInfoRequest() throws -> [String: Any] {
        let url = URL(string: baseAuthUrl + "/fetchUserInfo")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = baseAuthHeaders
        
        let (data, response) = try URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GSAuthError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        guard let plist = try PropertyListSerialization.propertyList(from: data, 
                                                                   options: [], 
                                                                   format: nil) as? [String: Any] else {
            throw GSAuthError.invalidResponse
        }
        
        return plist
    }
    
    /// Perform authenticated request
    /// - Parameter params: Parameters for the request
    /// - Returns: Response dictionary
    private func authenticatedRequest(_ params: [String: Any]) throws -> [String: Any] {
        let url = URL(string: baseAuthUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = baseAuthHeaders
        
        let bodyParams = baseAuthBodyParams(params)
        request.httpBody = try PropertyListSerialization.data(
            fromPropertyList: bodyParams,
            format: .xml,
            options: 0
        )
        
        let (data, response) = try URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GSAuthError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        guard let plist = try PropertyListSerialization.propertyList(from: data, 
                                                                   options: [],
                                                                   format: nil) as? [String: Any],
              let responseDict = plist["Response"] as? [String: Any] else {
            throw GSAuthError.invalidResponse
        }
        
        return responseDict
    }
    
    /// Handle trusted device 2FA
    /// - Parameters:
    ///   - dsid: Device ID
    ///   - idmsToken: IDMS token
    /// - Returns: 2FA response or nil if failed
    private func trusted2FA(dsid: String, idmsToken: String) throws -> [String: Any]? {
        let identityToken = "\(dsid):\(idmsToken)".data(using: .utf8)!.base64EncodedString()
        var headers = authHeaders(identityToken: identityToken)
        headers.merge(anisette.headers(includeUser: true)) { $1 }
        
        var request = URLRequest(url: URL(string: "https://gsa.apple.com/auth/verify/trusteddevice")!)
        request.allHTTPHeaderFields = headers
        
        let _ = try URLSession.shared.data(for: request)
        
        print("Enter 2FA code: ")
        guard let codeStr = readLine(), let code = Int(codeStr) else {
            throw GSAuthError.invalidInput
        }
        
        headers["security-code"] = "\(code)"
        
        request = URLRequest(url: URL(string: "https://gsa.apple.com/grandslam/GsService2/validate")!)
        request.allHTTPHeaderFields = headers
        
        let (data, response) = try URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GSAuthError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        guard let plist = try PropertyListSerialization.propertyList(from: data,
                                                                   options: [],
                                                                   format: nil) as? [String: Any] else {
            throw GSAuthError.invalidResponse
        }
        
        if checkError(plist) {
            return nil
        }
        
        print("2FA successful")
        return plist
    }
    
    /// Handle SMS 2FA
    /// - Parameters:
    ///   - dsid: Device ID
    ///   - idmsToken: IDMS token
    /// - Returns: 2FA response or nil if failed
    private func sms2FA(dsid: String, idmsToken: String) throws -> [String: Any]? {
        let identityToken = "\(dsid):\(idmsToken)".data(using: .utf8)!.base64EncodedString()
        var headers = authHeaders(identityToken: identityToken)
        headers.merge(anisette.headers(includeUser: true)) { $1 }
        headers["Accept"] = "application/json, text/javascript, */*; q=0.01"
        headers["Content-Type"] = "application/json"
        
        var request = URLRequest(url: URL(string: "https://gsa.apple.com/auth")!)
        request.allHTTPHeaderFields = headers
        
        let _ = try URLSession.shared.data(for: request)
        
        print("Enter 2FA code: ")
        guard let codeStr = readLine(), let code = Int(codeStr) else {
            throw GSAuthError.invalidInput
        }
        
        let body: [String: Any] = [
            "phoneNumber": ["id": 1],
            "securityCode": ["code": "\(code)"],
            "mode": "sms"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        
        request = URLRequest(url: URL(string: "https://gsa.apple.com/auth/verify/phone/securitycode")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        
        let (data, response) = try URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GSAuthError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        print("2FA successful")
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    /// Authenticate with Apple ID
    /// - Parameters:
    ///   - username: Apple ID username (email)
    ///   - password: Apple ID password
    /// - Returns: Secure payload data or tuple with payload and 2FA response
    public func authenticate(username: String, password: String) throws -> Any {
        // Configure SRP
        let srpConfig = SRP.Configuration(
            algorithm: .sha256,
            ng: .N2048,
            digest: SHA256.self
        )
        
        // Start SRP authentication
        let srpClient = SRPClient(
            username: username.data(using: .utf8)!,
            password: Data(), // We'll set this after getting salt
            configuration: srpConfig
        )
        
        let clientEphemeral = srpClient.startAuthentication()
        
        // Initial auth request
        let initParams: [String: Any] = [
            "A2k": clientEphemeral.publicKey.base64EncodedString(),
            "ps": ["s2k", "s2k_fo"],
            "u": username,
            "o": "init"
        ]
        
        let initResponse = try authenticatedRequest(initParams)
        
        if checkError(initResponse) {
            throw GSAuthError.authenticationFailed("Init response failed")
        }
        
        // Verify we're using s2k
        guard let sp = initResponse["sp"] as? String, sp == "s2k" else {
            throw GSAuthError.unsupportedProtocol("This implementation only supports s2k")
        }
        
        // Get salt and B value
        guard let saltBase64 = initResponse["s"] as? String,
              let salt = Data(base64Encoded: saltBase64),
              let iterations = initResponse["i"] as? Int,
              let bBase64 = initResponse["B"] as? String,
              let b = Data(base64Encoded: bBase64),
              let c = initResponse["c"] as? String else {
            throw GSAuthError.invalidResponse
        }
        
        // Derive password and process challenge
        srpClient.password = encryptPassword(password: password, salt: salt, iterations: iterations)
        
        guard let clientSession = try? srpClient.processChallenge(b) else {
            throw GSAuthError.authenticationFailed("Failed to process challenge")
        }
        
        // Complete authentication
        let completeParams: [String: Any] = [
            "c": c,
            "M1": clientSession.clientProof.base64EncodedString(),
            "u": username,
            "o": "complete"
        ]
        
        let completeResponse = try authenticatedRequest(completeParams)
        
        if checkError(completeResponse) {
            throw GSAuthError.authenticationFailed("Complete response failed")
        }
        
        // Verify server response
        guard let m2Base64 = completeResponse["M2"] as? String,
              let m2 = Data(base64Encoded: m2Base64),
              let spdBase64 = completeResponse["spd"] as? String,
              let spd = Data(base64Encoded: spdBase64) else {
            throw GSAuthError.invalidResponse
        }
        
        try srpClient.verifyServerProof(m2)
        
        guard srpClient.isAuthenticated else {
            throw GSAuthError.authenticationFailed("Failed to verify session")
        }
        
        // Decrypt secure payload data
        let spdData = decryptCBC(srpClient: srpClient, data: spd)
        
        guard let securePayload = try PropertyListSerialization.propertyList(
            from: spdData,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw GSAuthError.invalidResponse
        }
        
        // Check if 2FA is required
        var authType = ""
        if let status = completeResponse["Status"] as? [String: Any],
           let au = status["au"] as? String {
            authType = au
        }
        
        if authType == "trustedDeviceSecondaryAuth" {
            print("Type SMS to use SMS: ")
            if let which = readLine(), which == "SMS" {
                if let dsid = securePayload["adsid"] as? String,
                   let idmsToken = securePayload["GsIdmsToken"] as? String {
                    let twoFAResponse = try sms2FA(dsid: dsid, idmsToken: idmsToken)
                    return (securePayload, twoFAResponse)
                }
            } else {
                if let dsid = securePayload["adsid"] as? String,
                   let idmsToken = securePayload["GsIdmsToken"] as? String {
                    let twoFAResponse = try trusted2FA(dsid: dsid, idmsToken: idmsToken)
                    return (securePayload, twoFAResponse)
                }
            }
        } else if authType == "secondaryAuth" {
            print("SMS authentication required")
            if let dsid = securePayload["adsid"] as? String,
               let idmsToken = securePayload["GsIdmsToken"] as? String {
                let twoFAResponse = try sms2FA(dsid: dsid, idmsToken: idmsToken)
                return (securePayload, twoFAResponse)
            }
        } else if !authType.isEmpty {
            throw GSAuthError.unsupportedAuthType("Unknown auth value \(authType)")
        } else {
            print("Assuming 2FA is not required")
            return securePayload
        }
        
        return securePayload
    }
    
    /// Create app checksum
    /// - Parameters:
    ///   - appName: Application name
    ///   - sessionKey: Session key
    ///   - dsid: Device ID
    /// - Returns: App checksum or nil if parameters are missing
    private func makeAppChecksum(appName: String, sessionKey: Data?, dsid: String?) -> Data? {
        guard let sessionKey = sessionKey, let dsid = dsid else { return nil }
        
        let key = SymmetricKey(data: sessionKey)
        var hmac = HMAC<SHA256>(key: key)
        
        ["apptokens", dsid, appName].forEach { string in
            hmac.update(data: string.data(using: .utf8)!)
        }
        
        return Data(hmac.finalize())
    }
    
    /// Fetch Xcode authentication token
    /// - Parameters:
    ///   - username: Apple ID username
    ///   - password: Apple ID password
    /// - Returns: Secure payload and Xcode session or raw response
    public func fetchXcodeToken(username: String, password: String) throws -> (Any, Any) {
        let app = "com.apple.gs.xcode.auth"
        let authResult = try authenticate(username: password)
        
        let spd: [String: Any]
        if let dict = authResult as? [String: Any] {
            spd = dict
        } else if let tuple = authResult as? ([String: Any], Any) {
            spd = tuple.0
        } else {
            throw GSAuthError.invalidResponse
        }
        
        // Get required values
        guard let sessionKeyBase64 = spd["sk"] as? String,
              let sessionKey = Data(base64Encoded: sessionKeyBase64),
              let dsid = spd["adsid"] as? String,
              let c = spd["c"] as? String,
              let idmsToken = spd["GsIdmsToken"] as? String else {
            throw GSAuthError.invalidResponse
        }
        
        // Generate checksum
        let checksum = makeAppChecksum(appName: app, sessionKey: sessionKey, dsid: dsid)
        
        // Request Xcode token
        let params: [String: Any] = [
            "app": [app],
            "c": c,
            "checksum": checksum?.base64EncodedString() ?? "",
            "cpd": anisette.cpd,
            "o": "apptokens",
            "t": idmsToken,
            "u": dsid
        ]
        
        let tokenResponse = try authenticatedRequest(params)
        
        if checkError(tokenResponse) {
            throw GSAuthError.authenticationFailed("Error authenticating for Xcode token")
        }
        
        // Decrypt token
        if let etBase64 = tokenResponse["et"] as? String,
           let et = Data(base64Encoded: etBase64),
           let decryptedToken = decryptGCM(data: et, sessionKey: sessionKey),
           let tokenPlist = try? PropertyListSerialization.propertyList(from: decryptedToken, options: [], format: nil) as? [String: Any],
           let tokenData = tokenPlist["t"] as? [[String: Any]],
           !tokenData.isEmpty {
            let xcodeSession = XcodeSession(dsid: dsid, token: tokenData[0], anisette: anisette)
            return (spd, xcodeSession)
        }
        
        return (spd, tokenResponse)
    }
}

/// GSAuth errors
public enum GSAuthError: Error {
    case requestFailed(statusCode: Int)
    case invalidResponse
    case invalidInput
    case authenticationFailed(String)
    case unsupportedProtocol(String)
    case unsupportedAuthType(String)
}

/// PBKDF2 implementation using CommonCrypto
func pbkdf2(password: Data, salt: Data, iterations: Int, keyLength: Int) -> Data {
    var derivedKeyData = Data(repeating: 0, count: keyLength)
    
    derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
        password.withUnsafeBytes { passwordBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.baseAddress, password.count,
                    saltBytes.baseAddress, salt.count,
                    CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(iterations),
                    derivedKeyBytes.baseAddress, keyLength
                )
            }
        }
    }
    
    return derivedKeyData
}

/// Bridging header for CommonCrypto
import CommonCrypto