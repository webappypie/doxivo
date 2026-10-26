package com.webappypie.doxivo

import android.content.Context
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.encryption.AccessPermission
import com.tom_roush.pdfbox.pdmodel.encryption.StandardProtectionPolicy
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class PdfEncryptChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.webappypie.doxivo/pdf_crypto"
    }

    init {
        PDFBoxResourceLoader.init(context)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
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

                try {
                    val inputFile = File(inputPath)
                    if (!inputFile.exists()) {
                        result.error("FILE_NOT_FOUND", "Input file does not exist", null)
                        return
                    }

                    val document = PDDocument.load(inputFile)
                    val ap = AccessPermission()
                    val spp = StandardProtectionPolicy(ownerPassword, userPassword, ap)
                    spp.encryptionKeyLength = keyLength
                    document.protect(spp)
                    document.save(File(outputPath))
                    document.close()

                    result.success(outputPath)
                } catch (e: Exception) {
                    result.error("ENCRYPTION_FAILED", e.message, e.stackTraceToString())
                }
            }
            else -> result.notImplemented()
        }
    }
}
