package com.example.project1_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val SCREEN_CAPTURE_CHANNEL = "com.example.project1_flutter/screen_capture"
        private const val SCREEN_CAPTURE_REQUEST_CODE = 1001
        private var screenCaptureCallback: MethodChannel.Result? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_CAPTURE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestScreenCapture" -> {
                    requestScreenCapture(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestScreenCapture(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            // Screen capture is not supported on older versions
            result.success(true)
            return
        }

        try {
            screenCaptureCallback = result
            
            // Start the foreground service BEFORE requesting screen capture permission
            // This is required on Android 12+ (API 31+)
            ScreenCaptureService.startScreenCapture(this)
            
            val mediaProjectionManager =
                getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val captureIntent = mediaProjectionManager.createScreenCaptureIntent()
            startActivityForResult(captureIntent, SCREEN_CAPTURE_REQUEST_CODE)
        } catch (e: Exception) {
            e.printStackTrace()
            result.success(false)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SCREEN_CAPTURE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // User granted permission - service will stay running
                screenCaptureCallback?.success(true)
            } else {
                // User denied permission - stop the foreground service
                ScreenCaptureService.stopScreenCapture(this)
                screenCaptureCallback?.success(false)
            }
            screenCaptureCallback = null
        }
    }
}

