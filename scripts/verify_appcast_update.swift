#!/usr/bin/env swift

import CryptoKit
import Foundation

struct AppcastUpdate {
    let url: URL
    let length: Int
    let signature: String
}

enum VerifyError: Error, CustomStringConvertible {
    case missingFile(String)
    case missingPublicKey
    case missingEnclosure
    case invalidURL(String)
    case invalidLength(String)
    case invalidSignatureEncoding
    case signatureMismatch

    var description: String {
        switch self {
        case .missingFile(let path):
            return "Missing file: \(path)"
        case .missingPublicKey:
            return "Missing SUPublicEDKey in Config/BatteryPanicApp-Info.plist"
        case .missingEnclosure:
            return "Could not find an update enclosure in appcast.xml"
        case .invalidURL(let value):
            return "Invalid enclosure URL: \(value)"
        case .invalidLength(let value):
            return "Invalid enclosure length: \(value)"
        case .invalidSignatureEncoding:
            return "The Sparkle signature or public key is not valid base64"
        case .signatureMismatch:
            return "Sparkle signature verification failed"
        }
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let appcastURL = root.appendingPathComponent("appcast.xml")
let infoPlistURL = root.appendingPathComponent("Config/BatteryPanicApp-Info.plist")

func readPublicKey() throws -> String {
    guard FileManager.default.fileExists(atPath: infoPlistURL.path) else {
        throw VerifyError.missingFile(infoPlistURL.path)
    }

    let data = try Data(contentsOf: infoPlistURL)
    let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
    guard
        let dictionary = plist as? [String: Any],
        let key = dictionary["SUPublicEDKey"] as? String,
        !key.isEmpty
    else {
        throw VerifyError.missingPublicKey
    }

    return key
}

func readAppcastUpdate() throws -> AppcastUpdate {
    guard FileManager.default.fileExists(atPath: appcastURL.path) else {
        throw VerifyError.missingFile(appcastURL.path)
    }

    let xml = try String(contentsOf: appcastURL, encoding: .utf8)
    let pattern = #"<enclosure\s+url="([^"]+)"\s+length="([^"]+)"\s+type="[^"]+"\s+sparkle:edSignature="([^"]+)""#
    let regex = try NSRegularExpression(pattern: pattern)
    let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)
    guard let match = regex.firstMatch(in: xml, range: range) else {
        throw VerifyError.missingEnclosure
    }

    func group(_ index: Int) -> String {
        String(xml[Range(match.range(at: index), in: xml)!])
    }

    let urlString = group(1)
    let lengthString = group(2)
    let signature = group(3)

    guard let url = URL(string: urlString) else {
        throw VerifyError.invalidURL(urlString)
    }
    guard let length = Int(lengthString) else {
        throw VerifyError.invalidLength(lengthString)
    }

    return AppcastUpdate(url: url, length: length, signature: signature)
}

func updateData(for update: AppcastUpdate) throws -> Data {
    if CommandLine.arguments.count > 1 {
        let path = CommandLine.arguments[1]
        guard FileManager.default.fileExists(atPath: path) else {
            throw VerifyError.missingFile(path)
        }
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }

    return try Data(contentsOf: update.url)
}

do {
    let update = try readAppcastUpdate()
    let data = try updateData(for: update)

    guard data.count == update.length else {
        throw VerifyError.invalidLength("appcast says \(update.length), file is \(data.count)")
    }

    guard
        let signatureData = Data(base64Encoded: update.signature),
        let publicKeyData = Data(base64Encoded: try readPublicKey())
    else {
        throw VerifyError.invalidSignatureEncoding
    }

    let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
    guard publicKey.isValidSignature(signatureData, for: data) else {
        throw VerifyError.signatureMismatch
    }

    print("Sparkle appcast update verified")
    print("URL: \(update.url.absoluteString)")
    print("Length: \(update.length)")
} catch {
    fputs("Appcast update verification failed: \(error)\n", stderr)
    exit(1)
}
