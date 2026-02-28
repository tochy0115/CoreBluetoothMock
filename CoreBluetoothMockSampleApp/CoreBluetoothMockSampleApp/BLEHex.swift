import Foundation

enum BLEHex {
    static func decode(_ text: String) -> Data {
        let cleaned = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            return Data()
        }

        guard cleaned.count.isMultiple(of: 2) else {
            return Data()
        }

        var bytes = [UInt8]()
        bytes.reserveCapacity(cleaned.count / 2)

        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let next = cleaned.index(index, offsetBy: 2)
            let chunk = cleaned[index..<next]
            guard let value = UInt8(chunk, radix: 16) else {
                return Data()
            }
            bytes.append(value)
            index = next
        }

        return Data(bytes)
    }

    static func encode(_ data: Data?) -> String {
        guard let data, !data.isEmpty else {
            return ""
        }
        return data.map { String(format: "%02X", $0) }.joined()
    }
}
