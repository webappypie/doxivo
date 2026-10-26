import Foundation
import Flutter
import PDFKit
import UIKit

public class PdfToolkitPlugin: NSObject, FlutterPlugin {
    public static let channelName = "com.webappypie.doxivo/pdf_toolkit"
    public static let legacyChannelName = "com.webappypie.doxivo/pdf_crypto"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let legacyChannel = FlutterMethodChannel(name: legacyChannelName, binaryMessenger: registrar.messenger())
        let instance = PdfToolkitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: legacyChannel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.processMethodCall(call, result: result)
        }
    }

    private func processMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments must be a dictionary", details: nil))
            return
        }

        switch call.method {
        case "getPageCount":
            guard let inputPath = args["inputPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "inputPath required", details: nil))
                return
            }
            guard let doc = PDFDocument(url: URL(fileURLWithPath: inputPath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Failed to open PDF", details: nil))
                return
            }
            result(doc.pageCount)

        case "mergePdfs":
            guard let inputPaths = args["inputPaths"] as? [String],
                  let outputPath = args["outputPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "inputPaths and outputPath required", details: nil))
                return
            }
            let mergedDoc = PDFDocument()
            for path in inputPaths {
                if let srcDoc = PDFDocument(url: URL(fileURLWithPath: path)) {
                    for i in 0..<srcDoc.pageCount {
                        if let page = srcDoc.page(at: i) {
                            mergedDoc.insert(page, at: mergedDoc.pageCount)
                        }
                    }
                }
            }
            if mergedDoc.write(to: URL(fileURLWithPath: outputPath)) {
                result(outputPath)
            } else {
                result(FlutterError(code: "WRITE_FAILED", message: "Failed to save merged PDF", details: nil))
            }

        case "splitPdf":
            guard let inputPath = args["inputPath"] as? String,
                  let outputDir = args["outputDir"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "inputPath and outputDir required", details: nil))
                return
            }
            let prefix = (args["prefix"] as? String) ?? "split_part"
            guard let srcDoc = PDFDocument(url: URL(fileURLWithPath: inputPath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Failed to load PDF", details: nil))
                return
            }
            var outputPaths: [String] = []
            let fileManager = FileManager.default
            try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

            for i in 0..<srcDoc.pageCount {
                if let page = srcDoc.page(at: i) {
                    let pageDoc = PDFDocument()
                    pageDoc.insert(page, at: 0)
                    let partPath = (outputDir as NSString).appendingPathComponent("\(prefix)_\(i + 1).pdf")
                    if pageDoc.write(to: URL(fileURLWithPath: partPath)) {
                        outputPaths.append(partPath)
                    }
                }
            }
            result(outputPaths)

        case "extractPages":
            guard let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let pageIndices = args["pageIndices"] as? [Int] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid parameters", details: nil))
                return
            }
            guard let srcDoc = PDFDocument(url: URL(fileURLWithPath: inputPath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Failed to load PDF", details: nil))
                return
            }
            let outDoc = PDFDocument()
            for idx in pageIndices {
                if idx >= 0 && idx < srcDoc.pageCount, let page = srcDoc.page(at: idx) {
                    outDoc.insert(page, at: outDoc.pageCount)
                }
            }
            if outDoc.write(to: URL(fileURLWithPath: outputPath)) {
                result(outputPath)
            } else {
                result(FlutterError(code: "WRITE_FAILED", message: "Failed to save extracted pages", details: nil))
            }

        case "reorderAndRotatePages":
            guard let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let pageIndices = args["pageIndices"] as? [Int] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid parameters", details: nil))
                return
            }
            let rotations = args["rotations"] as? [Int]
            guard let srcDoc = PDFDocument(url: URL(fileURLWithPath: inputPath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Failed to load PDF", details: nil))
                return
            }
            let outDoc = PDFDocument()
            for (i, idx) in pageIndices.enumerated() {
                if idx >= 0 && idx < srcDoc.pageCount, let page = srcDoc.page(at: idx) {
                    let rot = rotations != nil && i < rotations!.count ? rotations![i] : 0
                    if rot != 0 {
                        page.rotation = (page.rotation + rot) % 360
                    }
                    outDoc.insert(page, at: outDoc.pageCount)
                }
            }
            if outDoc.write(to: URL(fileURLWithPath: outputPath)) {
                result(outputPath)
            } else {
                result(FlutterError(code: "WRITE_FAILED", message: "Failed to save reordered PDF", details: nil))
            }

        case "renderPagesToImages":
            guard let inputPath = args["inputPath"] as? String,
                  let outputDir = args["outputDir"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "inputPath and outputDir required", details: nil))
                return
            }
            guard let srcDoc = PDFDocument(url: URL(fileURLWithPath: inputPath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Failed to load PDF", details: nil))
                return
            }
            let format = (args["format"] as? String)?.lowercased() ?? "jpg"
            let pageIndices = (args["pageIndices"] as? [Int]) ?? Array(0..<srcDoc.pageCount)
            let fileManager = FileManager.default
            try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

            var renderedPaths: [String] = []
            for pageIdx in pageIndices {
                if pageIdx >= 0 && pageIdx < srcDoc.pageCount, let page = srcDoc.page(at: pageIdx) {
                    let pageRect = page.bounds(for: .mediaBox)
                    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                    let img = renderer.image { ctx in
                        UIColor.white.set()
                        ctx.fill(pageRect)
                        ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                        page.draw(with: .mediaBox, to: ctx.cgContext)
                    }

                    let outFilePath = (outputDir as NSString).appendingPathComponent("page_\(pageIdx + 1).\(format)")
                    let imgData = format == "png" ? img.pngData() : img.jpegData(compressionQuality: 0.92)
                    if let data = imgData {
                        try? data.write(to: URL(fileURLWithPath: outFilePath))
                        renderedPaths.append(outFilePath)
                    }
                }
            }
            result(renderedPaths)

        case "encryptPdf":
            guard let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let userPassword = args["userPassword"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "inputPath, outputPath, and userPassword required", details: nil))
                return
            }
            let ownerPassword = (args["ownerPassword"] as? String) ?? userPassword
            guard let doc = PDFDocument(url: URL(fileURLWithPath: inputPath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Failed to load PDF", details: nil))
                return
            }
            let options: [PDFDocumentWriteOption: Any] = [
                .userPasswordOption: userPassword,
                .ownerPasswordOption: ownerPassword
            ]
            if doc.write(to: URL(fileURLWithPath: outputPath), withOptions: options) {
                result(outputPath)
            } else {
                result(FlutterError(code: "ENCRYPTION_FAILED", message: "Failed to encrypt PDF", details: nil))
            }

        case "addWatermark":
            guard let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let watermarkText = args["watermarkText"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid parameters", details: nil))
                return
            }
            guard let doc = PDFDocument(url: URL(fileURLWithPath: inputPath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Failed to load PDF", details: nil))
                return
            }
            let fontSize = CGFloat((args["fontSize"] as? Double) ?? 48.0)
            let opacity = CGFloat((args["opacity"] as? Double) ?? 0.3)

            let outDoc = PDFDocument()
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    let pageRect = page.bounds(for: .mediaBox)
                    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                    let newImage = renderer.image { ctx in
                        page.draw(with: .mediaBox, to: ctx.cgContext)

                        let attrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.boldSystemFont(ofSize: fontSize),
                            .foregroundColor: UIColor.gray.withAlphaComponent(opacity)
                        ]
                        let textSize = (watermarkText as NSString).size(withAttributes: attrs)
                        ctx.cgContext.saveGState()
                        ctx.cgContext.translateBy(x: pageRect.midX, y: pageRect.midY)
                        ctx.cgContext.rotate(by: -CGFloat.pi / 4.0)
                        (watermarkText as NSString).draw(at: CGPoint(x: -textSize.width / 2.0, y: -textSize.height / 2.0), withAttributes: attrs)
                        ctx.cgContext.restoreGState()
                    }
                    if let newPage = PDFPage(image: newImage) {
                        outDoc.insert(newPage, at: outDoc.pageCount)
                    }
                }
            }
            if outDoc.write(to: URL(fileURLWithPath: outputPath)) {
                result(outputPath)
            } else {
                result(FlutterError(code: "WRITE_FAILED", message: "Failed to save watermarked PDF", details: nil))
            }

        case "addSignature":
            guard let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let signaturePath = args["signaturePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid parameters", details: nil))
                return
            }
            guard let doc = PDFDocument(url: URL(fileURLWithPath: inputPath)),
                  let sigImage = UIImage(contentsOfFile: signaturePath) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Failed to load file", details: nil))
                return
            }
            let pageIndex = (args["pageIndex"] as? Int) ?? 0
            let x = CGFloat((args["x"] as? Double) ?? 50.0)
            let y = CGFloat((args["y"] as? Double) ?? 50.0)
            let width = CGFloat((args["width"] as? Double) ?? 150.0)
            let height = CGFloat((args["height"] as? Double) ?? 75.0)

            let outDoc = PDFDocument()
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    if i == pageIndex {
                        let pageRect = page.bounds(for: .mediaBox)
                        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                        let newImage = renderer.image { ctx in
                            page.draw(with: .mediaBox, to: ctx.cgContext)
                            sigImage.draw(in: CGRect(x: x, y: pageRect.height - y - height, width: width, height: height))
                        }
                        if let newPage = PDFPage(image: newImage) {
                            outDoc.insert(newPage, at: outDoc.pageCount)
                        }
                    } else {
                        outDoc.insert(page, at: outDoc.pageCount)
                    }
                }
            }
            if outDoc.write(to: URL(fileURLWithPath: outputPath)) {
                result(outputPath)
            } else {
                result(FlutterError(code: "WRITE_FAILED", message: "Failed to save signed PDF", details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
