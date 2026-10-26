package com.webappypie.doxivo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val toolkitHandler = PdfToolkitChannel(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PdfToolkitChannel.CHANNEL)
            .setMethodCallHandler(toolkitHandler)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PdfToolkitChannel.LEGACY_CRYPTO_CHANNEL)
            .setMethodCallHandler(toolkitHandler)
    }
}
