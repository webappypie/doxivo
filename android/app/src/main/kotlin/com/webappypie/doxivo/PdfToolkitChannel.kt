package com.webappypie.doxivo

import android.content.Context
import android.graphics.Bitmap
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.io.MemoryUsageSetting
import com.tom_roush.pdfbox.multipdf.PDFMergerUtility
import com.tom_roush.pdfbox.multipdf.Splitter
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.encryption.AccessPermission
import com.tom_roush.pdfbox.pdmodel.encryption.StandardProtectionPolicy
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject
import com.tom_roush.pdfbox.pdmodel.graphics.state.PDExtendedGraphicsState
import com.tom_roush.pdfbox.rendering.ImageType
import com.tom_roush.pdfbox.rendering.PDFRenderer
import com.tom_roush.pdfbox.util.Matrix
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class PdfToolkitChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.webappypie.doxivo/pdf_toolkit"
        const val LEGACY_CRYPTO_CHANNEL = "com.webappypie.doxivo/pdf_crypto"
    }

    private val executor = Executors.newCachedThreadPool()

    init {
        PDFBoxResourceLoader.init(context)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        executor.execute {
            try {
                handleMethodCall(call, result)
            } catch (e: Exception) {
                result.error("UNEXPECTED_ERROR", e.message, e.stackTraceToString())
            }
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPageCount" -> {
                val inputPath = call.argument<String>("inputPath")
                if (inputPath == null) {
                    result.error("INVALID_ARGUMENTS", "inputPath is required", null)
                    return
                }
                val file = File(inputPath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "File does not exist: $inputPath", null)
                    return
                }
                PDDocument.load(file).use { doc ->
                    result.success(doc.numberOfPages)
                }
            }

            "mergePdfs" -> {
                val inputPaths = call.argument<List<String>>("inputPaths")
                val outputPath = call.argument<String>("outputPath")
                if (inputPaths.isNullOrEmpty() || outputPath == null) {
                    result.error("INVALID_ARGUMENTS", "inputPaths and outputPath are required", null)
                    return
                }

                val merger = PDFMergerUtility()
                merger.destinationFileName = outputPath
                for (path in inputPaths) {
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "Input file not found: $path", null)
                        return
                    }
                    merger.addSource(file)
                }
                merger.mergeDocuments(MemoryUsageSetting.setupMainMemoryOnly())
                result.success(outputPath)
            }

            "splitPdf" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputDir = call.argument<String>("outputDir")
                val prefix = call.argument<String>("prefix") ?: "split_part"
                if (inputPath == null || outputDir == null) {
                    result.error("INVALID_ARGUMENTS", "inputPath and outputDir are required", null)
                    return
                }

                val file = File(inputPath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Input file not found: $inputPath", null)
                    return
                }

                val outDirectory = File(outputDir)
                if (!outDirectory.exists()) outDirectory.mkdirs()

                val outputPaths = mutableListOf<String>()
                PDDocument.load(file).use { doc ->
                    val splitter = Splitter()
                    val pages = splitter.split(doc)
                    for ((index, pageDoc) in pages.withIndex()) {
                        val partFile = File(outDirectory, "${prefix}_${index + 1}.pdf")
                        pageDoc.save(partFile)
                        pageDoc.close()
                        outputPaths.add(partFile.absolutePath)
                    }
                }
                result.success(outputPaths)
            }

            "extractPages" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val pageIndices = call.argument<List<Int>>("pageIndices")
                if (inputPath == null || outputPath == null || pageIndices == null) {
                    result.error("INVALID_ARGUMENTS", "inputPath, outputPath, and pageIndices are required", null)
                    return
                }

                val file = File(inputPath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Input file not found: $inputPath", null)
                    return
                }

                PDDocument.load(file).use { srcDoc ->
                    PDDocument().use { outDoc ->
                        val maxPages = srcDoc.numberOfPages
                        for (idx in pageIndices) {
                            if (idx in 0 until maxPages) {
                                outDoc.addPage(srcDoc.getPage(idx))
                            }
                        }
                        outDoc.save(File(outputPath))
                    }
                }
                result.success(outputPath)
            }

            "reorderAndRotatePages" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val pageIndices = call.argument<List<Int>>("pageIndices")
                val rotations = call.argument<List<Int>>("rotations")
                if (inputPath == null || outputPath == null || pageIndices == null) {
                    result.error("INVALID_ARGUMENTS", "inputPath, outputPath, and pageIndices are required", null)
                    return
                }

                val file = File(inputPath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Input file not found: $inputPath", null)
                    return
                }

                PDDocument.load(file).use { srcDoc ->
                    PDDocument().use { outDoc ->
                        val maxPages = srcDoc.numberOfPages
                        for ((i, idx) in pageIndices.withIndex()) {
                            if (idx in 0 until maxPages) {
                                val page = srcDoc.getPage(idx)
                                val rot = rotations?.getOrNull(i) ?: 0
                                if (rot != 0) {
                                    val currentRot = page.rotation
                                    page.rotation = (currentRot + rot) % 360
                                }
                                outDoc.addPage(page)
                            }
                        }
                        outDoc.save(File(outputPath))
                    }
                }
                result.success(outputPath)
            }

            "renderPagesToImages" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputDir = call.argument<String>("outputDir")
                val pageIndices = call.argument<List<Int>>("pageIndices")
                val dpi = call.argument<Int>("dpi") ?: 150
                val format = call.argument<String>("format") ?: "jpg"

                if (inputPath == null || outputDir == null) {
                    result.error("INVALID_ARGUMENTS", "inputPath and outputDir are required", null)
                    return
                }

                val file = File(inputPath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Input file not found: $inputPath", null)
                    return
                }

                val outDirectory = File(outputDir)
                if (!outDirectory.exists()) outDirectory.mkdirs()

                val renderedPaths = mutableListOf<String>()
                PDDocument.load(file).use { doc ->
                    val renderer = PDFRenderer(doc)
                    val totalPages = doc.numberOfPages
                    val pagesToProcess = pageIndices ?: (0 until totalPages).toList()

                    for (pageIdx in pagesToProcess) {
                        if (pageIdx in 0 until totalPages) {
                            val bitmap = renderer.renderImageWithDPI(pageIdx, dpi.toFloat(), ImageType.RGB)
                            val outFile = File(outDirectory, "page_${pageIdx + 1}.${format.lowercase()}")
                            FileOutputStream(outFile).use { fos ->
                                val compressFormat = if (format.equals("png", ignoreCase = true)) {
                                    Bitmap.CompressFormat.PNG
                                } else {
                                    Bitmap.CompressFormat.JPEG
                                }
                                bitmap.compress(compressFormat, 92, fos)
                            }
                            bitmap.recycle()
                            renderedPaths.add(outFile.absolutePath)
                        }
                    }
                }
                result.success(renderedPaths)
            }

            "encryptPdf" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val userPassword = call.argument<String>("userPassword") ?: ""
                val ownerPassword = call.argument<String>("ownerPassword") ?: userPassword
                val keyLength = call.argument<Int>("keyLength") ?: 256

                if (inputPath == null || outputPath == null) {
                    result.error("INVALID_ARGUMENTS", "inputPath and outputPath are required", null)
                    return
                }

                val file = File(inputPath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Input file not found: $inputPath", null)
                    return
                }

                PDDocument.load(file).use { doc ->
                    val ap = AccessPermission()
                    val spp = StandardProtectionPolicy(ownerPassword, userPassword, ap)
                    spp.encryptionKeyLength = keyLength
                    doc.protect(spp)
                    doc.save(File(outputPath))
                }
                result.success(outputPath)
            }

            "addWatermark" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val watermarkText = call.argument<String>("watermarkText") ?: "CONFIDENTIAL"
                val fontSize = (call.argument<Double>("fontSize") ?: 48.0).toFloat()
                val opacity = (call.argument<Double>("opacity") ?: 0.3).toFloat()
                val rotationAngle = (call.argument<Double>("rotation") ?: 45.0).toFloat()

                if (inputPath == null || outputPath == null) {
                    result.error("INVALID_ARGUMENTS", "inputPath and outputPath are required", null)
                    return
                }

                val file = File(inputPath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Input file not found: $inputPath", null)
                    return
                }

                PDDocument.load(file).use { doc ->
                    val font = PDType1Font.HELVETICA_BOLD
                    for (page in doc.pages) {
                        val mediaBox = page.mediaBox
                        PDPageContentStream(doc, page, PDPageContentStream.AppendMode.APPEND, true, true).use { cs ->
                            val gState = PDExtendedGraphicsState().apply {
                                nonStrokingAlphaConstant = opacity
                            }
                            cs.setGraphicsStateParameters(gState)
                            cs.setNonStrokingColor(0.5f, 0.5f, 0.5f)
                            cs.beginText()
                            cs.setFont(font, fontSize)

                            val rad = Math.toRadians(rotationAngle.toDouble())
                            val cx = mediaBox.width / 2f
                            val cy = mediaBox.height / 2f
                            val matrix = Matrix.getRotateInstance(rad, cx, cy)
                            cs.setTextMatrix(matrix)

                            val strWidth = (font.getStringWidth(watermarkText) / 1000f) * fontSize
                            cs.newLineAtOffset(-strWidth / 2f, 0f)
                            cs.showText(watermarkText)
                            cs.endText()
                        }
                    }
                    doc.save(File(outputPath))
                }
                result.success(outputPath)
            }

            "addSignature" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val signaturePath = call.argument<String>("signaturePath")
                val pageIndex = call.argument<Int>("pageIndex") ?: 0
                val x = (call.argument<Double>("x") ?: 50.0).toFloat()
                val y = (call.argument<Double>("y") ?: 50.0).toFloat()
                val width = (call.argument<Double>("width") ?: 150.0).toFloat()
                val height = (call.argument<Double>("height") ?: 75.0).toFloat()

                if (inputPath == null || outputPath == null || signaturePath == null) {
                    result.error("INVALID_ARGUMENTS", "inputPath, outputPath, and signaturePath are required", null)
                    return
                }

                val file = File(inputPath)
                val sigFile = File(signaturePath)
                if (!file.exists() || !sigFile.exists()) {
                    result.error("FILE_NOT_FOUND", "File not found", null)
                    return
                }

                PDDocument.load(file).use { doc ->
                    if (pageIndex in 0 until doc.numberOfPages) {
                        val page = doc.getPage(pageIndex)
                        val sigImage = PDImageXObject.createFromFile(signaturePath, doc)
                        PDPageContentStream(doc, page, PDPageContentStream.AppendMode.APPEND, true, true).use { cs ->
                            cs.drawImage(sigImage, x, y, width, height)
                        }
                    }
                    doc.save(File(outputPath))
                }
                result.success(outputPath)
            }

            else -> result.notImplemented()
        }
    }
}
