import Foundation

/// Minimal RFC 4180 CSV: commas, quoted fields, doubled quotes, and line
/// breaks inside quotes.
enum CSV {
    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func line(_ fields: [String]) -> String {
        fields.map(escape).joined(separator: ",")
    }

    /// Rows of fields. Blank lines are skipped.
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var iterator = Array(text.unicodeScalars).makeIterator()
        var pending: Unicode.Scalar? = nil

        func endRow() {
            row.append(field)
            if !(row.count == 1 && row[0].isEmpty) { rows.append(row) }
            row = []
            field = ""
        }

        while let scalar = pending ?? iterator.next() {
            pending = nil
            if inQuotes {
                if scalar == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" { field.unicodeScalars.append("\"") } else { inQuotes = false; pending = next }
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.unicodeScalars.append(scalar)
                }
                continue
            }
            switch scalar {
            case "\"": inQuotes = true
            case ",": row.append(field); field = ""
            case "\r":
                if let next = iterator.next(), next != "\n" { pending = next }
                endRow()
            case "\n": endRow()
            default: field.unicodeScalars.append(scalar)
            }
        }
        if !field.isEmpty || !row.isEmpty { endRow() }
        return rows
    }
}
