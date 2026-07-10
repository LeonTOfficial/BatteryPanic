#!/usr/bin/env swift

import CryptoKit
import Foundation

struct AppcastUpdate {
    let url: URL
    let releaseNotesURL: URL
    let length: Int
    let signature: String
}

enum VerifyError: Error, CustomStringConvertible {
    case missingFile(String)
    case missingPublicKey
    case missingEnclosure
    case missingReleaseNotesLink
    case invalidURL(String)
    case invalidReleaseNotes(String)
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
        case .missingReleaseNotesLink:
            return "Could not find a release notes link in appcast.xml"
        case .invalidURL(let value):
            return "Invalid enclosure URL: \(value)"
        case .invalidReleaseNotes(let value):
            return "Invalid release notes: \(value)"
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
let arguments = Array(CommandLine.arguments.dropFirst())
let verifyPublicReleaseNotes = arguments.contains("--public-release-notes")
let updateArchivePath = arguments.first { !$0.hasPrefix("--") }

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
    let notesPattern = #"<sparkle:releaseNotesLink>([^<]+)</sparkle:releaseNotesLink>"#
    let notesRegex = try NSRegularExpression(pattern: notesPattern)
    let pattern = #"<enclosure\s+url="([^"]+)"\s+length="([^"]+)"\s+type="[^"]+"\s+sparkle:edSignature="([^"]+)""#
    let regex = try NSRegularExpression(pattern: pattern)
    let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)
    guard let notesMatch = notesRegex.firstMatch(in: xml, range: range) else {
        throw VerifyError.missingReleaseNotesLink
    }
    guard let match = regex.firstMatch(in: xml, range: range) else {
        throw VerifyError.missingEnclosure
    }

    let releaseNotesString = String(xml[Range(notesMatch.range(at: 1), in: xml)!])
    func group(_ index: Int) -> String {
        String(xml[Range(match.range(at: index), in: xml)!])
    }

    let urlString = group(1)
    let lengthString = group(2)
    let signature = group(3)

    guard let url = URL(string: urlString) else {
        throw VerifyError.invalidURL(urlString)
    }
    guard let releaseNotesURL = URL(string: releaseNotesString) else {
        throw VerifyError.invalidURL(releaseNotesString)
    }
    guard let length = Int(lengthString) else {
        throw VerifyError.invalidLength(lengthString)
    }

    return AppcastUpdate(url: url, releaseNotesURL: releaseNotesURL, length: length, signature: signature)
}

func updateData(for update: AppcastUpdate) throws -> Data {
    if let path = updateArchivePath {
        guard FileManager.default.fileExists(atPath: path) else {
            throw VerifyError.missingFile(path)
        }
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }

    return try Data(contentsOf: update.url)
}

func releaseNotesData(for update: AppcastUpdate) throws -> Data {
    if !verifyPublicReleaseNotes,
       update.releaseNotesURL.host == "leontofficial.github.io",
       update.releaseNotesURL.path.hasPrefix("/BatteryPanic/") {
        let relativePath = String(update.releaseNotesURL.path.dropFirst("/BatteryPanic/".count))
        let localPath = root.appendingPathComponent("docs").appendingPathComponent(relativePath)
        let indexPath = localPath.appendingPathComponent("index.html")
        if FileManager.default.fileExists(atPath: indexPath.path) {
            return try Data(contentsOf: indexPath)
        }
        if FileManager.default.fileExists(atPath: localPath.path) {
            return try Data(contentsOf: localPath)
        }
    }

    return try Data(contentsOf: update.releaseNotesURL)
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

    let releaseNotesData = try releaseNotesData(for: update)
    guard releaseNotesData.count > 800 else {
        throw VerifyError.invalidReleaseNotes("release notes are too small or empty")
    }
    let releaseNotesHTML = String(decoding: releaseNotesData.prefix(4096), as: UTF8.self)
    guard releaseNotesHTML.localizedCaseInsensitiveContains("Battery Panic") else {
        throw VerifyError.invalidReleaseNotes("release notes do not look like Battery Panic notes")
    }

    print("Sparkle appcast update verified")
    print("URL: \(update.url.absoluteString)")
    print("Release notes: \(update.releaseNotesURL.absoluteString)")
    print("Length: \(update.length)")
} catch {
    fputs("Appcast update verification failed: \(error)\n", stderr)
    exit(1)
}
