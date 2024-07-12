//
//  AES.swift
//  SpotifyAPIInvestigation
//
//  Created by 長内幸太郎 on 2024/07/12.
//

import Foundation
import CommonCrypto

struct AES {
    private static let keyLength = kCCKeySizeAES256
    private static let blockSize = kCCBlockSizeAES128

    static func encrypt(_ string: String, key: String) throws -> Data {
        guard let data = string.data(using: .utf8) else { throw CryptoError.invalidInput }
        return try crypt(input: data, operation: CCOperation(kCCEncrypt), key: key)
    }

    static func decrypt(_ data: Data, key: String) throws -> String {
        let decryptedData = try crypt(input: data, operation: CCOperation(kCCDecrypt), key: key)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else { throw CryptoError.invalidInput }
        return decryptedString
    }

    private static func crypt(input: Data, operation: CCOperation, key: String) throws -> Data {
        guard let keyData = key.data(using: .utf8) else { throw CryptoError.invalidKey }
        var outLength = Int(0)
        var outData = Data(count: input.count + blockSize)

        let keyBytes = keyData.withUnsafeBytes { keyBytes in
            return keyBytes.baseAddress
        }
        let inputBytes = input.withUnsafeBytes { inputBytes in
            return inputBytes.baseAddress
        }
        let outBytes = outData.withUnsafeMutableBytes { outBytes in
            return outBytes.baseAddress
        }

        let options = CCOptions(kCCOptionPKCS7Padding)

        let result = CCCrypt(
            operation,
            CCAlgorithm(kCCAlgorithmAES),
            options,
            keyBytes, keyLength,
            nil,
            inputBytes, input.count,
            outBytes, outData.count,
            &outLength
        )

        guard result == kCCSuccess else { throw CryptoError.cryptFailed }

        outData.removeSubrange(outLength..<outData.count)
        return outData
    }

    enum CryptoError: Error {
        case invalidInput
        case invalidKey
        case cryptFailed
    }
}

let secretKey = "your-secret-key"
let encryptionKey = "your-32-character-long-key-12345678"
let secretData = "/frYXyoIVNorJeKLG05aKDSMqcxZ6Fsbc0X5ZwW9PgU5yD3ltVROeJAgpkjugjlg"

func decryptedString() -> String {
    do {
        // 復号化
        let secret = try AES.decrypt(Data(base64Encoded: secretData)!, key: encryptionKey)
        print("Decrypted String: \(secret)")
        return secret
    } catch {
        print("Error: \(error)")
    }
    return ""
}

