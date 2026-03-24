import SwiftUI
import VisionKit
import Vision

// MARK: - Scan Result

struct ReceiptScanResult {
    var amount: String?
    var description: String?
    var date: Date?
    var category: ExpenseCategory?
}

// MARK: - Receipt Scanner View

struct ReceiptScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onScanComplete: (ReceiptScanResult) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onScanComplete: onScanComplete)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let dismiss: DismissAction
        let onScanComplete: (ReceiptScanResult) -> Void

        init(dismiss: DismissAction, onScanComplete: @escaping (ReceiptScanResult) -> Void) {
            self.dismiss = dismiss
            self.onScanComplete = onScanComplete
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            processScannedPages(scan: scan)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }

        // MARK: - OCR Processing

        private func processScannedPages(scan: VNDocumentCameraScan) {
            var allText: [String] = []

            let group = DispatchGroup()

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                guard let cgImage = image.cgImage else { continue }

                group.enter()

                let request = VNRecognizeTextRequest { request, error in
                    defer { group.leave() }
                    guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                    let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                    allText.append(contentsOf: lines)
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }

            group.notify(queue: .main) { [weak self] in
                let result = self?.parseReceipt(lines: allText) ?? ReceiptScanResult()
                self?.onScanComplete(result)
            }
        }

        // MARK: - Receipt Parsing

        private func parseReceipt(lines: [String]) -> ReceiptScanResult {
            var result = ReceiptScanResult()

            let fullText = lines.joined(separator: "\n").lowercased()

            // --- Amount ---
            result.amount = extractAmount(from: lines)

            // --- Date ---
            result.date = extractDate(from: lines)

            // --- Description (first meaningful non-numeric line) ---
            result.description = extractDescription(from: lines)

            // --- Category ---
            result.category = extractCategory(from: fullText)

            return result
        }

        private func extractAmount(from lines: [String]) -> String? {
            // Look for "total" lines first
            let totalPatterns = ["grand total", "total due", "total amount", "amount due", "total"]
            let amountRegex = try? NSRegularExpression(pattern: #"[\₱\$]?\s*(\d{1,3}(?:[,]\d{3})*\.\d{2})"#)

            // First pass: lines containing "total" keyword
            for line in lines {
                let lower = line.lowercased()
                for keyword in totalPatterns {
                    if lower.contains(keyword) {
                        if let amount = extractAmountFromLine(line, regex: amountRegex) {
                            return amount
                        }
                    }
                }
            }

            // Second pass: find the largest currency amount across all lines
            var largest: Double = 0
            var largestStr: String?

            for line in lines {
                let range = NSRange(line.startIndex..., in: line)
                if let regex = amountRegex {
                    let matches = regex.matches(in: line, range: range)
                    for match in matches {
                        if let numRange = Range(match.range(at: 1), in: line) {
                            let numStr = String(line[numRange]).replacingOccurrences(of: ",", with: "")
                            if let val = Double(numStr), val > largest {
                                largest = val
                                largestStr = numStr
                            }
                        }
                    }
                }
            }

            return largestStr
        }

        private func extractAmountFromLine(_ line: String, regex: NSRegularExpression?) -> String? {
            guard let regex = regex else { return nil }
            let range = NSRange(line.startIndex..., in: line)
            var largest: Double = 0
            var result: String?

            let matches = regex.matches(in: line, range: range)
            for match in matches {
                if let numRange = Range(match.range(at: 1), in: line) {
                    let numStr = String(line[numRange]).replacingOccurrences(of: ",", with: "")
                    if let val = Double(numStr), val > largest {
                        largest = val
                        result = numStr
                    }
                }
            }
            return result
        }

        private func extractDate(from lines: [String]) -> Date? {
            let datePatterns: [(String, String)] = [
                (#"(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})"#, ""),
                (#"(\w+ \d{1,2},?\s*\d{4})"#, ""),
                (#"(\d{4}[/\-]\d{1,2}[/\-]\d{1,2})"#, ""),
            ]

            let formatters: [DateFormatter] = {
                let formats = [
                    "MM/dd/yyyy", "MM-dd-yyyy", "dd/MM/yyyy", "dd-MM-yyyy",
                    "MM/dd/yy", "MM-dd-yy",
                    "yyyy/MM/dd", "yyyy-MM-dd",
                    "MMMM dd, yyyy", "MMMM dd yyyy",
                    "MMM dd, yyyy", "MMM dd yyyy",
                    "MMMM d, yyyy", "MMM d, yyyy",
                ]
                return formats.map { fmt in
                    let df = DateFormatter()
                    df.dateFormat = fmt
                    df.locale = Locale(identifier: "en_US_POSIX")
                    return df
                }
            }()

            for line in lines {
                for (pattern, _) in datePatterns {
                    guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                    let range = NSRange(line.startIndex..., in: line)
                    if let match = regex.firstMatch(in: line, range: range),
                       let matchRange = Range(match.range(at: 1), in: line) {
                        let dateStr = String(line[matchRange])
                        for formatter in formatters {
                            if let date = formatter.date(from: dateStr) {
                                return date
                            }
                        }
                    }
                }
            }
            return nil
        }

        private func extractDescription(from lines: [String]) -> String? {
            let skipPatterns = [
                #"^\d+[/\-.]"#,           // date-like
                #"^[\₱\$]?\d"#,           // starts with number/currency
                #"^(tel|phone|fax|vat|tin|sn|si|or)"#, // metadata
                #"^\s*$"#,                 // empty
                #"^-+$"#,                  // separator
                #"^=+$"#,                  // separator
                #"^(total|subtotal|change|cash|amount|tax|discount|qty|item)"#,
            ]

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 3 else { continue }

                let lower = trimmed.lowercased()
                var skip = false
                for pattern in skipPatterns {
                    if lower.range(of: pattern, options: .regularExpression) != nil {
                        skip = true
                        break
                    }
                }
                if !skip {
                    return trimmed
                }
            }
            return nil
        }

        private func extractCategory(from text: String) -> ExpenseCategory? {
            let categoryKeywords: [(ExpenseCategory, [String])] = [
                (.food, ["restaurant", "food", "cafe", "coffee", "bakery", "diner", "pizza",
                         "burger", "chicken", "grill", "eatery", "canteen", "jollibee",
                         "mcdonalds", "mcdonald", "starbucks", "grocery", "supermarket",
                         "market", "minimart", "7-eleven", "7eleven"]),
                (.transport, ["gas", "fuel", "petrol", "shell", "caltex", "petron", "grab",
                              "uber", "taxi", "parking", "toll", "lrt", "mrt", "jeep",
                              "transit", "gasoline", "diesel"]),
                (.health, ["pharmacy", "clinic", "hospital", "medical", "doctor", "dental",
                           "drugstore", "mercury drug", "watsons", "generics"]),
                (.utilities, ["electric", "water", "internet", "wifi", "meralco", "pldt",
                              "globe", "smart", "converge", "bill", "utility"]),
                (.shopping, ["mall", "shop", "store", "sm ", "robinsons", "uniqlo", "h&m",
                             "clothing", "shoes", "fashion", "lazada", "shopee"]),
                (.entertainment, ["cinema", "movie", "netflix", "spotify", "game", "arcade",
                                  "concert", "ticket", "amusement", "play"]),
            ]

            for (category, keywords) in categoryKeywords {
                for keyword in keywords {
                    if text.contains(keyword) {
                        return category
                    }
                }
            }
            return nil
        }
    }
}
